import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../core/sensor_manager.dart';
import 'rewards_page.dart';
import '../core/app_strings.dart';

class HexMapPage extends StatefulWidget {
  @override
  _HexMapPageState createState() => _HexMapPageState();
}

class _HexMapPageState extends State<HexMapPage> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  List<Polygon> _hexagons = [];
  bool _isLoading = true;

  bool _isMissionExpanded = true;
  Timer? _collapseTimer;

  // Heatmap mode: 0=coverage, 1=noise, 2=wifi
  int _heatmapMode = 0;

  @override
  void initState() {
    super.initState();
    _locateUser();
    // Auto-collapse the guide after 8 seconds
    _collapseTimer = Timer(Duration(seconds: 8), () {
      if (mounted) setState(() => _isMissionExpanded = false);
    });
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  Future<void> _locateUser() async {
    setState(() => _isLoading = true);

    try {
      // 1. Check Permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _isLoading = false);
          return; // Still denied
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 2. Get Location
      final settings = LocationSettings(
        accuracy: LocationAccuracy.high,
      );
      Position pos =
          await Geolocator.getCurrentPosition(locationSettings: settings);

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(pos.latitude, pos.longitude);
          _generateHexGrid(pos.latitude, pos.longitude);
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Location error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _generateHexGrid(double centerLat, double centerLng) {
    List<Polygon> hexes = [];
    final rng = Random();

    // Get visited hexes from sensor manager
    final manager = Provider.of<SensorManager>(context, listen: false);
    final myHexes = manager.visitedHexes;

    // Generate a 5x5 grid
    for (int x = -2; x <= 2; x++) {
      for (int y = -2; y <= 2; y++) {
        double offsetLat = x * 0.005;
        double offsetLng = y * 0.005;
        if (y % 2 != 0) offsetLat += 0.0025;

        final hexLat = centerLat + offsetLat;
        final hexLng = centerLng + offsetLng;
        final center = LatLng(hexLat, hexLng);

        // Generate spatialKey matching sensor_manager format
        String spatialKey =
            "${hexLat.toStringAsFixed(3)}_${hexLng.toStringAsFixed(3)}";
        bool isMyHex = myHexes.contains(spatialKey);

        Color color;

        if (_heatmapMode == 0) {
          // Coverage mode - show real visited hexes
          if (isMyHex) {
            color = Colors.green.withValues(alpha: 0.5);
          } else if (rng.nextBool()) {
            color =
                Colors.blue.withValues(alpha: 0.3); // Other users (simulated)
          } else {
            color = Colors.transparent;
          }
        } else if (_heatmapMode == 1) {
          // Noise heatmap - simulate different noise levels
          final noiseLevel = rng.nextInt(100);
          color = _getNoiseColor(noiseLevel.toDouble());
        } else {
          // WiFi heatmap - simulate signal strength
          final signalStrength = -30 - rng.nextInt(70); // -30 to -100 dBm
          color = _getWifiColor(signalStrength.toDouble());
        }

        if (color != Colors.transparent) {
          hexes.add(
            Polygon(
              points: _createHexPoints(center, 0.0028),
              color: color,
              borderColor: Colors.white.withValues(alpha: 0.3),
              borderStrokeWidth: 1,
            ),
          );
        }
      }
    }
    _hexagons = hexes;
  }

  Color _getNoiseColor(double decibel) {
    // 0-30: green, 30-50: yellow, 50-70: orange, 70+: red
    if (decibel < 30) return Colors.green.withValues(alpha: 0.5);
    if (decibel < 50) return Colors.yellow.withValues(alpha: 0.5);
    if (decibel < 70) return Colors.orange.withValues(alpha: 0.5);
    return Colors.red.withValues(alpha: 0.5);
  }

  Color _getWifiColor(double signal) {
    // -30 to -50: excellent (green), -50 to -70: good (yellow), -70+: weak (red)
    if (signal >= -50) return Colors.green.withValues(alpha: 0.5);
    if (signal >= -70) return Colors.yellow.withValues(alpha: 0.5);
    return Colors.red.withValues(alpha: 0.5);
  }

  List<LatLng> _createHexPoints(LatLng center, double radius) {
    final points = <LatLng>[];
    for (int i = 0; i < 6; i++) {
      double angle_deg = 60.0 * i - 30;
      double angle_rad = pi / 180 * angle_deg;
      points.add(LatLng(
        center.latitude + radius * cos(angle_rad),
        center.longitude + radius * sin(angle_rad) * 1.5,
      ));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(title: Text(AppStrings.t('coverage_map'))),
      body: Consumer<SensorManager>(
        builder: (context, manager, child) {
          final displayLocation =
              (manager.isSampling && manager.liveLocation != null)
                  ? manager.liveLocation
                  : _currentLocation;

          return Stack(
            children: [
              _buildMapContent(manager, displayLocation),

              // --- Top Legend (Restored & Interactive) ---
              if (displayLocation != null && !_isLoading)
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E3F).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: Colors.cyanAccent.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 4)
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Flexible(
                          child: _buildInteractiveLegend(
                              Colors.green,
                              AppStrings.t('legend_my_mining'),
                              AppStrings.t('legend_my_mining_desc')),
                        ),
                        SizedBox(width: 4),
                        Flexible(
                          child: _buildInteractiveLegend(
                              Colors.blue.withValues(alpha: 0.5),
                              AppStrings.t('legend_covered'),
                              AppStrings.t('legend_covered_desc')),
                        ),
                        SizedBox(width: 4),
                        Flexible(
                          child: _buildInteractiveLegend(
                              Colors.transparent,
                              AppStrings.t('legend_empty'),
                              AppStrings.t('legend_empty_desc'),
                              borderColor: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),

              // --- Bottom Mission Guide (Collapsible) ---
              if (displayLocation != null && !_isLoading)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => setState(
                        () => _isMissionExpanded = !_isMissionExpanded),
                    onVerticalDragEnd: (details) {
                      if (details.primaryVelocity! > 0) {
                        setState(
                            () => _isMissionExpanded = false); // Swipe down
                      } else if (details.primaryVelocity! < 0) {
                        setState(() => _isMissionExpanded = true); // Swipe up
                      }
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      height: _isMissionExpanded ? 260 : 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E3F),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                        border: Border.all(
                            color: Colors.cyanAccent.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black38,
                              blurRadius: 10,
                              offset: Offset(0, -2))
                        ],
                      ),
                      child: SingleChildScrollView(
                        physics: NeverScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            // Handle bar / Header
                            Container(
                              height: 60,
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  Icon(
                                      _isMissionExpanded
                                          ? Icons.keyboard_arrow_down
                                          : Icons.keyboard_arrow_up,
                                      color: Colors.cyanAccent),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(AppStrings.t('mission_title'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                  ),
                                  if (!_isMissionExpanded)
                                    Flexible(
                                      child: Text(AppStrings.t('tap_to_view'),
                                          maxLines: 1,
                                          overflow: TextOverflow.fade,
                                          softWrap: false,
                                          style: TextStyle(
                                              color: Colors.cyanAccent,
                                              fontSize: 12)),
                                    ),
                                ],
                              ),
                            ),
                            // Expanded Content
                            if (_isMissionExpanded)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 0),
                                child: Column(
                                  children: [
                                    Divider(),
                                    _buildMissionRow(
                                        Colors.transparent,
                                        AppStrings.t('mission_empty_hex'),
                                        AppStrings.t('mission_high_yield'),
                                        Colors.grey),
                                    _buildMissionRow(
                                        Colors.blue.withValues(alpha: 0.3),
                                        AppStrings.t('mission_covered_hex'),
                                        AppStrings.t('mission_low_yield'),
                                        null),
                                    SizedBox(height: 12),
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.orange
                                                .withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.timer,
                                              size: 20,
                                              color: Colors.orangeAccent),
                                          SizedBox(width: 10),
                                          Expanded(
                                              child: Text(
                                                  AppStrings.t(
                                                      'mission_action_desc'),
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color:
                                                          Colors.orangeAccent,
                                                      height: 1.3))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Controls
              if (displayLocation != null && !_isLoading)
                Positioned(
                  bottom: _isMissionExpanded ? 280 : 80,
                  right: 20,
                  child: Column(
                    children: [
                      // Layer toggle button
                      FloatingActionButton(
                        heroTag: "layer_toggle",
                        mini: true,
                        backgroundColor: _heatmapMode == 0
                            ? Colors.cyanAccent
                            : _heatmapMode == 1
                                ? Colors.purpleAccent
                                : Colors.greenAccent,
                        foregroundColor: Colors.black,
                        child: Icon(
                          _heatmapMode == 0
                              ? Icons.layers
                              : _heatmapMode == 1
                                  ? Icons.graphic_eq
                                  : Icons.wifi,
                          color: Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            _heatmapMode = (_heatmapMode + 1) % 3;
                            if (_currentLocation != null) {
                              _generateHexGrid(
                                _currentLocation!.latitude,
                                _currentLocation!.longitude,
                              );
                            }
                          });
                          final isZh = AppStrings.languageCode == 'zh';
                          final modes = isZh
                              ? ['覆盖模式', '噪音热力图', 'WiFi热力图']
                              : ['Coverage', 'Noise Heatmap', 'WiFi Heatmap'];
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(modes[_heatmapMode]),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      FloatingActionButton(
                        heroTag: "rewards_fab",
                        backgroundColor: Colors.amber,
                        child: const Icon(Icons.stars, color: Colors.black),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const RewardsPage()));
                        },
                      ),
                      const SizedBox(height: 10),
                      FloatingActionButton(
                        heroTag: "zoom_in",
                        mini: true,
                        backgroundColor: const Color(0xFF1E1E3F),
                        foregroundColor: Colors.white,
                        child: Icon(Icons.add, color: Colors.white),
                        onPressed: () {
                          final currZoom = _mapController.camera.zoom;
                          _mapController.move(
                              _mapController.camera.center, currZoom + 1);
                        },
                      ),
                      SizedBox(height: 10),
                      FloatingActionButton(
                        heroTag: "zoom_out",
                        mini: true,
                        backgroundColor: const Color(0xFF1E1E3F),
                        foregroundColor: Colors.white,
                        child: Icon(Icons.remove, color: Colors.white),
                        onPressed: () {
                          final currZoom = _mapController.camera.zoom;
                          _mapController.move(
                              _mapController.camera.center, currZoom - 1);
                        },
                      ),
                      SizedBox(height: 10),
                      FloatingActionButton(
                        heroTag: "my_loc",
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        child: Icon(Icons.my_location, color: Colors.black),
                        onPressed: () {
                          _mapController.move(displayLocation, 15.0);
                        },
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMissionRow(
      Color color, String label, String reward, Color? borderColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                  color: borderColor ?? Colors.transparent, width: 2),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.white)),
          ),
          Flexible(
            flex: 3,
            child: Text(reward,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                    color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMapContent(SensorManager manager, LatLng? displayLocation) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (displayLocation == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(AppStrings.t('loc_access_needed'),
                style: TextStyle(color: Colors.white, fontSize: 18)),
            SizedBox(height: 8),
            Text(AppStrings.t('loc_access_desc'),
                style: TextStyle(color: Colors.grey)),
            SizedBox(height: 24),
            TextButton(
              onPressed: () => Geolocator.openAppSettings(),
              child: Text(AppStrings.t('open_settings'),
                  style: TextStyle(color: Colors.blueAccent)),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: _locateUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
              ),
              child: Text(AppStrings.t('retry_permission'),
                  style: TextStyle(color: Colors.black)),
            )
          ],
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: displayLocation,
        initialZoom: 14.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.sensor_sentinel',
        ),
        PolygonLayer(polygons: _hexagons),
        MarkerLayer(
          markers: [
            Marker(
              point: displayLocation,
              width: 50,
              height: 50,
              child: Icon(
                Icons.person_pin_circle,
                color:
                    manager.isSampling ? Colors.greenAccent : Colors.redAccent,
                size: 40,
                shadows: [Shadow(blurRadius: 10, color: Colors.black)],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInteractiveLegend(Color color, String label, String info,
      {Color? borderColor}) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("$label: $info"), duration: Duration(seconds: 2)));
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color,
                border: Border.all(color: borderColor ?? Colors.transparent),
                shape: BoxShape.circle),
          ),
          SizedBox(width: 6),
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black,
                        offset: Offset(1, 1),
                      ),
                    ])),
          ),
        ],
      ),
    );
  }
}
