import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_windowmanager_plus/flutter_windowmanager_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/security_utils.dart';
import '../../home/screens/main_navigation_screen.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  int _failedAttempts = 0;
  int _lockoutSecondsRemaining = 0;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    _checkSavedLockout();
    _enableSecureScreen();
  }

  /// Chặn chụp màn hình trên Android (FLAG_SECURE)
  Future<void> _enableSecureScreen() async {
    try {
      await FlutterWindowManagerPlus.addFlags(
          FlutterWindowManagerPlus.FLAG_SECURE);
    } catch (_) {}
  }

  /// Gỡ FLAG_SECURE khi rời màn hình đăng nhập
  Future<void> _disableSecureScreen() async {
    try {
      await FlutterWindowManagerPlus.clearFlags(
          FlutterWindowManagerPlus.FLAG_SECURE);
    } catch (_) {}
  }

  Future<void> _checkSavedLockout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _failedAttempts = prefs.getInt('login_failed_attempts') ?? 0;
      final lockoutUntil = prefs.getInt('login_lockout_until') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (lockoutUntil > now) {
        final remaining = (lockoutUntil - now) ~/ 1000;
        if (remaining > 0) {
          _startLockout(remaining, persist: false);
        }
      }
    } catch (_) {}
  }

  void _startLockout(int seconds, {bool persist = true}) {
    _lockoutTimer?.cancel();
    setState(() {
      _lockoutSecondsRemaining = seconds;
    });

    if (persist) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt('login_failed_attempts', _failedAttempts);
        prefs.setInt(
          'login_lockout_until',
          DateTime.now().millisecondsSinceEpoch + (seconds * 1000),
        );
      });
    }

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_lockoutSecondsRemaining > 1) {
          _lockoutSecondsRemaining--;
        } else {
          _lockoutSecondsRemaining = 0;
          timer.cancel();
          SharedPreferences.getInstance().then((prefs) {
            prefs.remove('login_lockout_until');
          });
        }
      });
    });
  }

  Future<void> _resetLockout() async {
    _lockoutTimer?.cancel();
    setState(() {
      _failedAttempts = 0;
      _lockoutSecondsRemaining = 0;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('login_failed_attempts');
      await prefs.remove('login_lockout_until');
    } catch (_) {}
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _disableSecureScreen();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_lockoutSecondsRemaining > 0) return;
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      await _resetLockout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Đăng nhập thành công! Chào mừng bạn đến với WEARSY.'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } else {
      _failedAttempts++;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('login_failed_attempts', _failedAttempts);
      } catch (_) {}

      if (!mounted) return;

      if (_failedAttempts == 5) {
        _startLockout(60); // Khóa 1 phút khi sai 5 lần liên tiếp
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Bạn đã nhập sai 5 lần liên tiếp. Nút đăng nhập tạm khóa trong 1 phút.'),
            backgroundColor: AppTheme.accentColor,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (_failedAttempts >= 10) {
        _startLockout(300); // Khóa 5 phút khi sai thêm 5 lần (tổng 10 lần)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Bạn đã nhập sai 10 lần liên tiếp. Nút đăng nhập tạm khóa trong 5 phút.'),
            backgroundColor: AppTheme.accentColor,
            duration: const Duration(seconds: 5),
          ),
        );
      } else if (authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    }
  }

  void _handleGoogleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.loginWithGoogle();
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đăng nhập thành công bằng Google!'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context); // Listen to Theme changes
    final authProvider = Provider.of<AuthProvider>(context);
    final isTheme2 = AppTheme.current.id == 'theme_2';

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.lightBackground,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Badge
                  Container(
                    width: 105,
                    height: 105,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: isTheme2
                          ? Border.all(
                              color: AppTheme.primaryLight.withOpacity(0.4),
                              width: 2)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Image.asset(
                      'assets/images/logo_icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title Wearsy
                  Text(
                    'Wearsy',
                    style: GoogleFonts.outfit(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.darkTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Trợ lý Thời trang & Tủ đồ Thông minh AI',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.darkTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Login Form Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: isTheme2
                          ? Border.all(color: AppTheme.cardColor, width: 1.5)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email Field Label
                          Text(
                            'Email',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: AppTheme.darkTextPrimary),
                            decoration: InputDecoration(
                              hintText: 'Nhập email của bạn',
                              hintStyle: TextStyle(
                                  color: AppTheme.darkTextSecondary
                                      .withOpacity(0.5)),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isTheme2
                                        ? AppTheme.primaryLight
                                        : AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.person,
                                      color: Colors.white, size: 18),
                                ),
                              ),
                              fillColor: AppTheme.lavenderSurface,
                              filled: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  color: isTheme2
                                      ? AppTheme.primaryLight.withOpacity(0.5)
                                      : AppTheme.primaryColor.withOpacity(0.15),
                                  width: isTheme2 ? 1.4 : 1.0,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  color: isTheme2
                                      ? AppTheme.primaryLight.withOpacity(0.5)
                                      : AppTheme.primaryColor.withOpacity(0.15),
                                  width: isTheme2 ? 1.4 : 1.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  color: isTheme2
                                      ? AppTheme.primaryLight
                                      : AppTheme.primaryColor,
                                  width: 2.0,
                                ),
                              ),
                            ),
                            validator: (value) =>
                                SecurityUtils.validateEmail(value),
                          ),
                          const SizedBox(height: 24),

                          // Password Field Label
                          Text(
                            'Mật khẩu',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(color: AppTheme.darkTextPrimary),
                            decoration: InputDecoration(
                              hintText: 'Nhập mật khẩu',
                              hintStyle: TextStyle(
                                  color: AppTheme.darkTextSecondary
                                      .withOpacity(0.5)),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isTheme2
                                        ? AppTheme.primaryLight
                                        : AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.lock,
                                      color: Colors.white, size: 18),
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppTheme.darkTextSecondary
                                      .withOpacity(0.6),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              fillColor: AppTheme.lavenderSurface,
                              filled: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  color: isTheme2
                                      ? AppTheme.primaryLight.withOpacity(0.5)
                                      : AppTheme.primaryColor.withOpacity(0.15),
                                  width: isTheme2 ? 1.4 : 1.0,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  color: isTheme2
                                      ? AppTheme.primaryLight.withOpacity(0.5)
                                      : AppTheme.primaryColor.withOpacity(0.15),
                                  width: isTheme2 ? 1.4 : 1.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  color: isTheme2
                                      ? AppTheme.primaryLight
                                      : AppTheme.primaryColor,
                                  width: 2.0,
                                ),
                              ),
                            ),
                            validator: (value) =>
                                SecurityUtils.validatePassword(value),
                          ),
                          const SizedBox(height: 32),

                          // Login Submit Button
                          Builder(
                            builder: (context) {
                              final isLocked = _lockoutSecondsRemaining > 0;
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(28),
                                        ),
                                        elevation: 0,
                                      ),
                                      onPressed:
                                          (authProvider.isLoading || isLocked)
                                              ? null
                                              : _handleLogin,
                                      child: authProvider.isLoading
                                          ? const SpinKitThreeBounce(
                                              color: Colors.white,
                                              size: 24,
                                            )
                                          : isLocked
                                              ? Text(
                                                  'THỬ LẠI SAU ${_formatDuration(_lockoutSecondsRemaining)}',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : Text(
                                                  'Đăng Nhập',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // Divider
                          Center(
                            child: Text(
                              'Hoặc',
                              style: GoogleFonts.inter(
                                color:
                                    AppTheme.darkTextSecondary.withOpacity(0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Google Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.lavenderSurface,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                  side: BorderSide(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.12),
                                  ),
                                ),
                              ),
                              onPressed: authProvider.isLoading
                                  ? null
                                  : _handleGoogleLogin,
                              child: const GoogleLogoWidget(size: 30),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Register prompt link
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RegisterScreen(),
                                  ),
                                );
                              },
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppTheme.darkTextSecondary
                                        .withOpacity(0.8),
                                  ),
                                  children: [
                                    const TextSpan(
                                        text: 'Chưa có tài khoản Wearsy? - '),
                                    TextSpan(
                                      text: 'Đăng ký ngay',
                                      style: GoogleFonts.inter(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GoogleLogoWidget extends StatelessWidget {
  final double size;
  const GoogleLogoWidget({super.key, this.size = 28.0});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/google_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
