import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'nguyenvana@example.com');
  final _passwordController = TextEditingController(text: '12345678');
  bool _obscurePassword = true;

  int _failedAttempts = 0;
  int _lockoutSecondsRemaining = 0;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    _checkSavedLockout();
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
        const SnackBar(
          content: Text('Đăng nhập thành công! Chào mừng bạn đến với WEARSY.'),
          backgroundColor: AppTheme.primaryColor,
        ),
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
          const SnackBar(
            content: Text('Bạn đã nhập sai 5 lần liên tiếp. Nút đăng nhập tạm khóa trong 1 phút.'),
            backgroundColor: AppTheme.accentColor,
            duration: Duration(seconds: 4),
          ),
        );
      } else if (_failedAttempts >= 10) {
        _startLockout(300); // Khóa 5 phút khi sai thêm 5 lần (tổng 10 lần)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn đã nhập sai 10 lần liên tiếp. Nút đăng nhập tạm khóa trong 5 phút.'),
            backgroundColor: AppTheme.accentColor,
            duration: Duration(seconds: 5),
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
        const SnackBar(
          content: Text('Đăng nhập thành công bằng Google!'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppTheme.darkBackground,
          image: DecorationImage(
            image: NetworkImage('https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=1000&auto=format&fit=crop'),
            fit: BoxFit.cover,
            opacity: 0.15,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Badge & App Title
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Image.asset(
                      'assets/images/logo_icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'WEARSY',
                    style: GoogleFonts.outfit(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3.5,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Your wardrobe, smarter',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      letterSpacing: 1.0,
                      color: AppTheme.darkTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Login Form Card (Glassmorphism)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đăng nhập',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Nhập email và mật khẩu của bạn để tiếp tục',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.darkTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Email Field
                          Text(
                            'Email',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'nguyenvana@example.com',
                              prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryLight),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập Email';
                              }
                              if (!value.contains('@')) {
                                return 'Email không hợp lệ';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

                          // Password Field
                          Text(
                            'Mật khẩu',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryLight),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: AppTheme.darkTextSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập mật khẩu';
                              }
                              if (value.length < 6) {
                                return 'Mật khẩu phải có ít nhất 6 ký tự';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),

                          // Login Submit Button
                          Builder(
                            builder: (context) {
                              final isLocked = _lockoutSecondsRemaining > 0;
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 300),
                                    opacity: isLocked ? 0.45 : 1.0,
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: isLocked ? null : AppTheme.primaryGradient,
                                          color: isLocked ? Colors.white.withOpacity(0.12) : null,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: isLocked
                                              ? null
                                              : [
                                                  BoxShadow(
                                                    color: AppTheme.primaryColor.withOpacity(0.4),
                                                    blurRadius: 15,
                                                    offset: const Offset(0, 5),
                                                  ),
                                                ],
                                        ),
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          onPressed: (authProvider.isLoading || isLocked) ? null : _handleLogin,
                                          child: authProvider.isLoading
                                              ? const SpinKitThreeBounce(
                                                  color: Colors.white,
                                                  size: 24,
                                                )
                                              : isLocked
                                                  ? Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        const Icon(Icons.timer_outlined, color: Colors.white70, size: 20),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          'THỬ LẠI SAU ${_formatDuration(_lockoutSecondsRemaining)}',
                                                          style: GoogleFonts.outfit(
                                                            fontSize: 15,
                                                            fontWeight: FontWeight.bold,
                                                            letterSpacing: 1.0,
                                                            color: Colors.white70,
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Text(
                                                          'ĐĂNG NHẬP',
                                                          style: GoogleFonts.outfit(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold,
                                                            letterSpacing: 1.2,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        const Icon(Icons.arrow_forward_rounded, size: 20),
                                                      ],
                                                    ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isLocked) ...[
                                    const SizedBox(height: 10),
                                    Center(
                                      child: Text(
                                        _failedAttempts >= 10
                                            ? 'Đã nhập sai 10 lần liên tục. Tạm khóa trong 5 phút.'
                                            : 'Đã nhập sai 5 lần liên tục. Tạm khóa trong 1 phút.',
                                        style: GoogleFonts.inter(
                                          color: AppTheme.accentColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // Divider
                          Row(
                            children: [
                              const Expanded(child: Divider(color: Colors.white24, height: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'Hoặc đăng nhập bằng',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.darkTextSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider(color: Colors.white24, height: 1)),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Social SSO Buttons (Google SSO)
                          SizedBox(
                            width: double.infinity,
                            child: InkWell(
                              onTap: authProvider.isLoading ? null : _handleGoogleLogin,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        'G',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFEA4335),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Đăng nhập nhanh bằng Google',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
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

                  const SizedBox(height: 24),

                  // Switch to Register Screen
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Chưa có tài khoản WEARSY? ',
                        style: GoogleFonts.inter(
                          color: AppTheme.darkTextSecondary,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Đăng ký ngay',
                          style: GoogleFonts.inter(
                            color: AppTheme.primaryLight,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
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
