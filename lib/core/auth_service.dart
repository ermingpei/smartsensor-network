import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'referral_service.dart';

/// Authentication service for SmartSensor app.
/// Supports: Email/Password, Phone/OTP, Google, Apple, WeChat, and Anonymous mode.
class AuthService extends ChangeNotifier {
  final SupabaseClient _client;

  User? _currentUser;
  bool _isAnonymous = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _pendingEmailVerification = false;

  // Persistence keys
  static const String _anonModeKey = 'auth_anonymous_mode';

  AuthService(this._client) {
    _initAuth();
  }

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null && isEmailVerified;
  bool get isAnonymous => _isAnonymous;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get pendingEmailVerification => _pendingEmailVerification;

  /// Check if user email is verified
  bool get isEmailVerified {
    if (_currentUser == null) return false;
    // Phone users don't need email verification
    if (_currentUser!.phone != null && _currentUser!.phone!.isNotEmpty) {
      return true;
    }
    // OAuth users are auto-verified
    if (_currentUser!.appMetadata['provider'] != null &&
        _currentUser!.appMetadata['provider'] != 'email') {
      return true;
    }
    // Email users need verification
    return _currentUser!.emailConfirmedAt != null;
  }

  /// Initialize authentication state
  Future<void> _initAuth() async {
    _currentUser = _client.auth.currentUser;

    // Check if anonymous mode was previously chosen
    final prefs = await SharedPreferences.getInstance();
    _isAnonymous = prefs.getBool(_anonModeKey) ?? false;

    // Listen to auth state changes
    _client.auth.onAuthStateChange.listen((data) {
      _currentUser = data.session?.user;

      if (_currentUser != null) {
        // Only clear anonymous if actually logged in with verified account
        if (isEmailVerified) {
          _isAnonymous = false;
          _saveAnonMode(false);
          _pendingEmailVerification = false;
        }
      }
      notifyListeners();
    });

    notifyListeners();
  }

  /// Save anonymous mode preference
  Future<void> _saveAnonMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_anonModeKey, value);
  }

  /// Sign up with email and password.
  /// Returns true if signup successful (no email verification required).
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? inviterCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _currentUser = response.user;
        // No email verification required - register and login immediately
        _isAnonymous = false;
        await _saveAnonMode(false);

        // Process referral if invite code provided
        if (inviterCode != null && inviterCode.isNotEmpty) {
          final referralService = ReferralService();
          await referralService.processReferral(
            response.user!.id,
            inviterCode,
          );
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on AuthException catch (e) {
      _errorMessage = _parseAuthError(e.message);
    } catch (e) {
      _errorMessage = '网络错误，请稍后重试';
      debugPrint('Signup error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Sign in with email and password.
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _currentUser = response.user;
        // No email verification required - login directly
        _isAnonymous = false;
        await _saveAnonMode(false);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on AuthException catch (e) {
      _errorMessage = _parseAuthError(e.message);
    } catch (e) {
      _errorMessage = '网络错误，请稍后重试';
      debugPrint('Login error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Sign in or sign up with email (auto-detect)
  Future<bool> signInOrSignUpWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Try sign in first
      final signInResponse = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (signInResponse.user != null) {
        _currentUser = signInResponse.user;
        if (!isEmailVerified) {
          _pendingEmailVerification = true;
          _errorMessage = '请先验证邮箱后再登录';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        _isAnonymous = false;
        await _saveAnonMode(false);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on AuthException catch (e) {
      // Only try signup if user does not exist (not for wrong password)
      // Supabase returns 'Invalid login credentials' for both wrong password AND non-existent user
      // We need to check if user exists first, but since we can't easily do that,
      // we'll show a clearer error and let user click a 'Register' link if needed
      if (e.message.contains('Invalid login credentials')) {
        // Could be wrong password OR user doesn't exist
        // Ask user to confirm if they want to register
        _errorMessage = '邮箱或密码错误。如果是新用户，请再次点击按钮注册。';
        _isLoading = false;
        notifyListeners();
        // Return a special state - set a flag to attempt signup on next click
        return false;
      } else {
        _errorMessage = _parseAuthError(e.message);
      }
    } catch (e) {
      _errorMessage = '网络错误，请稍后重试';
      debugPrint('Auth error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Send OTP to phone number
  Future<bool> sendPhoneOtp(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _client.auth.signInWithOtp(
        phone: phone,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _parseAuthError(e.message);
    } catch (e) {
      _errorMessage = '发送验证码失败，请稍后重试';
      debugPrint('Phone OTP error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Verify phone OTP and sign in
  Future<bool> verifyPhoneOtp({
    required String phone,
    required String otp,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _client.auth.verifyOTP(
        phone: phone,
        token: otp,
        type: OtpType.sms,
      );

      if (response.user != null) {
        _currentUser = response.user;
        _isAnonymous = false;
        await _saveAnonMode(false);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on AuthException catch (e) {
      _errorMessage = _parseAuthError(e.message);
    } catch (e) {
      _errorMessage = '验证码错误或已过期';
      debugPrint('Phone verify error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Sign in with Google OAuth
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.smartsensor://login-callback/',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _errorMessage = 'Google登录失败，请确认已启用';
      debugPrint('Google OAuth error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Sign in with Apple
  Future<bool> signInWithApple() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.smartsensor://login-callback/',
      );

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _errorMessage = 'Apple登录失败，请确认已启用';
      debugPrint('Apple OAuth error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Continue as anonymous (guest mode)
  /// Can always be chosen, even after previous logout
  Future<void> continueAsAnonymous() async {
    _currentUser = null; // Ensure no user session
    _isAnonymous = true;
    _pendingEmailVerification = false;
    await _saveAnonMode(true);
    notifyListeners();
  }

  /// Reset password via email
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://smartsensor.yourcompany.com/auth/reset',
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _parseAuthError(e.message);
    } catch (e) {
      _errorMessage = '发送重置邮件失败';
      debugPrint('Password reset error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Resend email verification
  Future<bool> resendVerificationEmail() async {
    if (_currentUser?.email == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: _currentUser!.email!,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '重发验证邮件失败';
      debugPrint('Resend error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Sign out - does NOT prevent future anonymous usage
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      _currentUser = null;
      _isAnonymous = false;
      _pendingEmailVerification = false;
      await _saveAnonMode(false);
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  /// Parse auth error messages to user-friendly Chinese/English
  String _parseAuthError(String message) {
    if (message.contains('Email not confirmed')) {
      return '请先验证邮箱';
    } else if (message.contains('Invalid login credentials')) {
      // More helpful message for new users trying to login
      return '账号不存在或密码错误，新用户请点击下方链接注册';
    } else if (message.contains('User already registered')) {
      return '该邮箱已注册，请直接登录';
    } else if (message.contains('Password should be')) {
      return '密码至少需要6位';
    } else if (message.contains('rate limit')) {
      return '操作太频繁，请稍后再试';
    } else if (message.contains('network')) {
      return '网络错误，请检查连接';
    } else if (message.contains('Phone')) {
      return '手机号格式错误或不支持';
    } else if (message.contains('OTP') || message.contains('token')) {
      return '验证码错误或已过期';
    } else if (message.contains('provider')) {
      return '该登录方式未启用，请联系管理员';
    }
    return message;
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear pending verification state
  void clearPendingVerification() {
    _pendingEmailVerification = false;
    notifyListeners();
  }
}
