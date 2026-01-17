import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_strings.dart';
import 'main_scaffold.dart';

class OnboardingPage extends StatefulWidget {
  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<Map<String, String>> get _pages => [
        {
          "title": AppStrings.t('onboard_1_title'),
          "body": AppStrings.t('onboard_1_body'),
          "icon": "🌐"
        },
        {
          "title": AppStrings.t('onboard_2_title'),
          "body": AppStrings.t('onboard_2_body'),
          "icon": "📡"
        },
        {
          "title": AppStrings.t('onboard_3_title'),
          "body": AppStrings.t('onboard_3_body'),
          "icon": "💎"
        },
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212), // Deep dark background
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 20),
                // --- APP LOGO (Stylized) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset('assets/icon/icon.png',
                          width: 48, height: 48),
                    ),
                    SizedBox(width: 12),
                    Image.asset(
                      'assets/icon/smartsensor_title.png',
                      height: 50,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          "SmartSensor",
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                    blurRadius: 10,
                                    color: Colors.cyanAccent,
                                    offset: Offset(0, 0))
                              ]),
                        );
                      },
                    ),
                  ],
                ),
                Text(
                  AppStrings.t('slogan'),
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      letterSpacing: 1.2,
                      fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 4),
                Text(
                  AppStrings.t('powered_by') + " Qubit Rhythm",
                  style: TextStyle(
                      color: Colors.cyanAccent.withValues(alpha: 0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0),
                ),

                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40.0, vertical: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _pages[index]['icon']!,
                              style: TextStyle(fontSize: 80),
                            ),
                            SizedBox(height: 30),
                            Text(
                              _pages[index]['title']!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              _pages[index]['body']!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.4,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Page Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(horizontal: 5),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.cyanAccent
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Action Button
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(boxShadow: [
                      BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: Offset(0, 5))
                    ]),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        } else {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('seenOnboarding', true);

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MainScaffold()),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30))),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? AppStrings.t('enter_network')
                            : AppStrings.t('next'),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
