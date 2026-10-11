import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Tiện ích bảo mật — Hash mật khẩu trước khi lưu vào SharedPreferences.
///
/// Sử dụng SHA-256 + salt cố định theo email để ngăn rainbow table attack.
/// Lưu ý: Đây là giải pháp client-side cho offline mode. Khi backend có sẵn,
/// mật khẩu phải được hash bcrypt phía server.
class SecurityUtils {
  SecurityUtils._();

  /// Salt nội bộ cố định — thêm entropy
  static const String _appSalt = 'WEARSY_SEC_2024_v1';

  /// Hash mật khẩu với SHA-256 + email-salt để lưu vào SharedPreferences
  static String hashPassword(String plaintext, String email) {
    final saltedInput = '${_appSalt}_${email.trim().toLowerCase()}_$plaintext';
    final bytes = utf8.encode(saltedInput);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// So sánh mật khẩu người dùng nhập với hash đã lưu
  static bool verifyPassword(
      String plaintext, String email, String storedHash) {
    return hashPassword(plaintext, email) == storedHash;
  }

  /// Validate email đúng định dạng (RFC 5322 cơ bản)
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w\.\-\+]+@[\w\-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email.trim());
  }

  /// Validate độ mạnh mật khẩu: tối thiểu 8 ký tự, có chữ cái và số
  static PasswordStrength checkPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.empty;
    if (password.length < 8) return PasswordStrength.tooShort;

    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#\$&*~\-_.,]').hasMatch(password);

    if (!hasLetter || !hasDigit) return PasswordStrength.weak;
    if (hasSpecial && password.length >= 12) return PasswordStrength.strong;
    return PasswordStrength.medium;
  }

  /// Thông báo lỗi validate mật khẩu cho form
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (value.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự';
    if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
      return 'Mật khẩu phải chứa ít nhất 1 chữ cái';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Mật khẩu phải chứa ít nhất 1 chữ số';
    }
    return null;
  }

  /// Thông báo lỗi validate email cho form
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập Email';
    if (!isValidEmail(value.trim())) {
      return 'Email không đúng định dạng (VD: user@example.com)';
    }
    return null;
  }
}

enum PasswordStrength { empty, tooShort, weak, medium, strong }
