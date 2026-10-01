import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String _selectedGender = 'Nam';
  DateTime? _selectedBirthDate = DateTime(2002, 5, 20);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();

    final result = await authProvider.sendOtpEmail(email, fullName: name);
    if (!mounted) return;

    if (result.success) {
      _showOtpModal(email);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(result.errorMessage ?? 'Không thể gửi mã OTP tới email.'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    }
  }

  void _showOtpModal(String email) {
    final otpControllers = List.generate(6, (_) => TextEditingController());
    final focusNodes = List.generate(6, (_) => FocusNode());
    bool isVerifying = false;
    String? otpError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void verifyAndRegister() async {
              final otpCode = otpControllers.map((c) => c.text).join();
              if (otpCode.length < 6) {
                setModalState(() {
                  otpError = 'Vui lòng nhập đủ 6 chữ số OTP';
                });
                return;
              }

              setModalState(() {
                isVerifying = true;
                otpError = null;
              });

              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final isOtpValid = await authProvider.verifyOtp(email, otpCode);

              if (!isOtpValid) {
                setModalState(() {
                  isVerifying = false;
                  otpError =
                      'Mã OTP không chính xác hoặc đã hết hạn. Vui lòng kiểm tra lại email.';
                });
                return;
              }

              final success = await authProvider.register(
                _nameController.text.trim(),
                email,
                _passwordController.text,
                gender: _selectedGender,
                birthDate: _selectedBirthDate,
              );

              if (!bottomSheetContext.mounted) return;
              Navigator.pop(bottomSheetContext);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Xác thực OTP & Đăng ký tài khoản thành công!'),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                );
                Navigator.pop(context);
              } else if (authProvider.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(authProvider.errorMessage!),
                    backgroundColor: AppTheme.accentColor,
                  ),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.mark_email_read_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Xác thực mã OTP Email',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Mã 6 chữ số đã được gửi đến:',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppTheme.darkTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                AppTheme.primaryLight.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        email,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryLight,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                AppTheme.primaryLight.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mark_email_unread_rounded,
                              color: AppTheme.primaryLight, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Mã OTP 6 số đã được gửi qua Gmail thật tới hộp thư của bạn. Vui lòng kiểm tra Hộp thư đến (hoặc thư mục Spam).',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 44,
                          height: 52,
                          child: TextField(
                            controller: otpControllers[index],
                            focusNode: focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              contentPadding: EdgeInsets.zero,
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppTheme.primaryLight, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Colors.white24),
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty && index < 5) {
                                focusNodes[index + 1].requestFocus();
                              } else if (value.isEmpty && index > 0) {
                                focusNodes[index - 1].requestFocus();
                              }
                              if (otpControllers
                                  .every((c) => c.text.isNotEmpty)) {
                                verifyAndRegister();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    if (otpError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        otpError!,
                        style: GoogleFonts.inter(
                            color: Colors.redAccent, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: isVerifying ? null : verifyAndRegister,
                          child: isVerifying
                              ? const SpinKitThreeBounce(
                                  color: Colors.white, size: 20)
                              : Text(
                                  'XÁC NHẬN OTP & ĐĂNG KÝ',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton.icon(
                        onPressed: () async {
                          final ap =
                              Provider.of<AuthProvider>(context, listen: false);
                          final res = await ap.sendOtpEmail(email,
                              fullName: _nameController.text.trim());
                          if (res.success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Đã gửi lại mã OTP mới tới email của bạn!'),
                                backgroundColor: AppTheme.primaryColor,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    res.errorMessage ?? 'Gửi lại thất bại.'),
                                backgroundColor: AppTheme.accentColor,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.refresh_rounded,
                            size: 16, color: AppTheme.primaryLight),
                        label: Text(
                          'Chưa nhận được? Gửi lại mã OTP',
                          style: GoogleFonts.inter(
                            color: AppTheme.primaryLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleGoogleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.loginWithGoogle();
    if (!mounted) return;
    if (success) {
      Navigator.pop(context); // return to main screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký / Đăng nhập thành công bằng Google!'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tạo Tài Khoản WEARSY',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: AppTheme.darkBackground,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bắt đầu hành trình thời trang',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tạo tài khoản để cá nhân hóa tủ đồ và gợi ý outfit AI',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.darkTextSecondary,
                  ),
                ),
                const SizedBox(height: 28),

                // Register Form Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full Name Field
                        Text(
                          'Họ và tên',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Nguyễn Văn A',
                            prefixIcon: Icon(Icons.person_outline_rounded,
                                color: AppTheme.primaryLight),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập họ và tên';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

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
                            hintText: 'user@example.com',
                            prefixIcon: Icon(Icons.email_outlined,
                                color: AppTheme.primaryLight),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập Email';
                            }
                            if (!value.contains('@')) {
                              return 'Email không đúng định dạng';
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
                            hintText: 'Tối thiểu 6 ký tự',
                            prefixIcon: const Icon(Icons.lock_outline_rounded,
                                color: AppTheme.primaryLight),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
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
                            if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)')
                                .hasMatch(value)) {
                              return 'Mật khẩu phải chứa cả chữ cái và chữ số';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Confirm Password Field
                        Text(
                          'Xác nhận mật khẩu',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Nhập lại mật khẩu',
                            prefixIcon: const Icon(Icons.lock_reset_rounded,
                                color: AppTheme.primaryLight),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppTheme.darkTextSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng xác nhận mật khẩu';
                            }
                            if (value != _passwordController.text) {
                              return 'Mật khẩu xác nhận không trùng khớp';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Giới tính
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.darkSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Giới tính',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.darkTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: ['Nam', 'Nữ', 'Khác'].map((g) {
                                  final isSelected = _selectedGender == g;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      label: Text(g),
                                      selected: isSelected,
                                      showCheckmark: isSelected,
                                      checkmarkColor: Colors.white,
                                      selectedColor: AppTheme.primaryColor,
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.05),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: isSelected
                                              ? Colors.transparent
                                              : Colors.white
                                                  .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : AppTheme.darkTextSecondary,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      onSelected: (val) {
                                        if (val)
                                          setState(() => _selectedGender = g);
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Ngày sinh
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate:
                                  _selectedBirthDate ?? DateTime(2002, 5, 20),
                              firstDate: DateTime(1960),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() => _selectedBirthDate = date);
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.darkSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.cake_rounded,
                                    color: AppTheme.primaryLight, size: 22),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ngày sinh',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppTheme.darkTextSecondary,
                                        ),
                                      ),
                                      Text(
                                        _selectedBirthDate != null
                                            ? DateFormat('dd/MM/yyyy')
                                                .format(_selectedBirthDate!)
                                            : 'Chưa thiết lập',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.calendar_today_rounded,
                                    color: Colors.white54, size: 18),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Register Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
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
                              onPressed: authProvider.isLoading
                                  ? null
                                  : _handleRegister,
                              child: authProvider.isLoading
                                  ? const SpinKitThreeBounce(
                                      color: Colors.white,
                                      size: 24,
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'ĐĂNG KÝ TÀI KHOẢN',
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                            Icons.check_circle_outline_rounded,
                                            size: 20),
                                      ],
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Divider
                        Row(
                          children: [
                            const Expanded(
                                child:
                                    Divider(color: Colors.white24, height: 1)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'Hoặc nhanh hơn với',
                                style: GoogleFonts.inter(
                                  color: AppTheme.darkTextSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Expanded(
                                child:
                                    Divider(color: Colors.white24, height: 1)),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Social SSO Buttons (Google SSO)
                        SizedBox(
                          width: double.infinity,
                          child: InkWell(
                            onTap: authProvider.isLoading
                                ? null
                                : _handleGoogleLogin,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.15)),
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
                                    'Đăng ký nhanh bằng Google',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
