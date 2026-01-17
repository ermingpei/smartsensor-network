import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/sensor_manager.dart';
import 'core/auth_service.dart';
import 'features/onboarding_page.dart';
import 'features/main_scaffold.dart';
import 'features/auth_page.dart';
import 'features/consent_dialog.dart';

// Environment variables (injected via --dart-define)
// See .env.example for required configuration
const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: '', // Required: Your Supabase project URL
);
const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: '', // Required: Your Supabase anon/public key
);
const sentryDsn = String.fromEnvironment('SENTRY_DSN',
    defaultValue: ''); // Optional: Sentry DSN for error tracking

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WakelockPlus.enable();

  // Initialize Supabase
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  final prefs = await SharedPreferences.getInstance();
  final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  // Initialize Sentry (if DSN configured)
  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 1.0;
        options.environment =
            const String.fromEnvironment('ENV', defaultValue: 'development');
      },
      appRunner: () => _runApp(seenOnboarding),
    );
  } else {
    // Run without Sentry in development
    _runApp(seenOnboarding);
  }
}

void _runApp(bool seenOnboarding) {
  final supabaseClient = Supabase.instance.client;

  runApp(
    MultiProvider(
      providers: [
        // Auth Service
        ChangeNotifierProvider(
          create: (_) => AuthService(supabaseClient),
        ),
        // Sensor Manager
        ChangeNotifierProvider(
          create: (context) {
            final manager = SensorManager();
            manager.initSync(supabaseClient);
            // Load persisted earnings from local storage
            manager.loadEarnings();
            return manager;
          },
        ),
      ],
      child: SensorSentinelApp(seenOnboarding: seenOnboarding),
    ),
  );
}

class SensorSentinelApp extends StatelessWidget {
  final bool seenOnboarding;

  const SensorSentinelApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartSensor',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primarySwatch: Colors.cyan,
        useMaterial3: true,
      ),
      home: _AuthGate(seenOnboarding: seenOnboarding),
    );
  }
}

/// Auth gate widget to handle authentication flow
/// Now includes privacy consent check before auth
class _AuthGate extends StatefulWidget {
  final bool seenOnboarding;

  const _AuthGate({required this.seenOnboarding});

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _checkingConsent = true;
  bool _hasConsent = false;

  @override
  void initState() {
    super.initState();
    _checkConsent();
  }

  Future<void> _checkConsent() async {
    final consent = await ConsentDialog.hasConsent();
    if (mounted) {
      setState(() {
        _hasConsent = consent;
        _checkingConsent = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking consent
    if (_checkingConsent) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent),
        ),
      );
    }

    // Show consent dialog if not yet consented
    if (!_hasConsent) {
      return ConsentDialog(
        onAccept: () {
          setState(() => _hasConsent = true);
        },
      );
    }

    // Normal auth flow
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        // User is logged in or chose anonymous mode
        if (authService.isLoggedIn || authService.isAnonymous) {
          // Load referral boost for logged-in users
          if (authService.isLoggedIn && authService.currentUser != null) {
            final sensorManager =
                Provider.of<SensorManager>(context, listen: false);
            sensorManager.loadReferralBoost(authService.currentUser!.id);
          }

          // Show onboarding if first time
          if (!widget.seenOnboarding) {
            return OnboardingPage();
          }
          return const MainScaffold();
        }

        // Show auth page
        return AuthPage(
          onAuthSuccess: () {
            // Navigate to appropriate page based on onboarding status
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => widget.seenOnboarding
                    ? const MainScaffold()
                    : OnboardingPage(),
              ),
            );
          },
        );
      },
    );
  }
}
