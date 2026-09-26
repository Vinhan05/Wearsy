import 'dart:developer' as developer;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmailService {
  static const String _prefKeySmtpEmail = 'smtp_sender_email';
  static const String _prefKeySmtpPassword = 'smtp_sender_password';

  // Default credentials (Brevo Relay)
  static String senderEmail = 'baee6e001@smtp-brevo.com';
  static String senderAppPassword = 'YOUR_BREVO_SMTP_KEY';
  static String senderFrom = 'vo.thedan@outlook.com';
  static String senderFromName = 'WEARSY Support';

  /// Khởi tạo và nạp cấu hình SMTP từ bộ nhớ máy (nếu có)
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString(_prefKeySmtpEmail);
      final savedPassword = prefs.getString(_prefKeySmtpPassword);

      // Tự động xóa cache tài khoản Gmail cũ (nếu có) để chuyển sang Brevo
      if (savedEmail != null && savedEmail.contains('gmail.com')) {
        await prefs.remove(_prefKeySmtpEmail);
        await prefs.remove(_prefKeySmtpPassword);
      } else {
        if (savedEmail != null && savedEmail.isNotEmpty) {
          senderEmail = savedEmail;
        }
        if (savedPassword != null && savedPassword.isNotEmpty) {
          senderAppPassword = savedPassword;
        }
      }
    } catch (e) {
      developer.log('EmailService init error: $e', name: 'EmailService');
    }
  }

  /// Cập nhật tài khoản SMTP và Mật khẩu
  static Future<void> updateConfig({
    required String email,
    required String appPassword,
  }) async {
    senderEmail = email.trim();
    senderAppPassword = appPassword.trim().replaceAll(' ', '');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeySmtpEmail, senderEmail);
    await prefs.setString(_prefKeySmtpPassword, senderAppPassword);
  }

  /// Kiểm tra xem đã có cấu hình SMTP hay chưa
  static bool get isConfigured => senderEmail.isNotEmpty && senderAppPassword.isNotEmpty;

  /// Gửi email chứa mã OTP 6 số thật tới hộp thư người nhận
  static Future<EmailSendResult> sendOtpEmail({
    required String toEmail,
    required String otp,
    String? userName,
  }) async {
    if (!isConfigured) {
      return EmailSendResult(
        success: false,
        errorMessage: 'Chưa cấu hình tài khoản SMTP gửi thư hoặc API Key.',
        isConfigMissing: true,
      );
    }

    try {
      // 1. Tạo SMTP server (Brevo Relay hoặc Gmail tùy host)
      final cleanPassword = senderAppPassword.replaceAll(' ', '');
      final smtpServer = senderEmail.contains('brevo.com')
          ? SmtpServer(
              'smtp-relay.brevo.com',
              port: 587,
              username: senderEmail,
              password: cleanPassword,
              ssl: false,
              allowInsecure: true,
            )
          : gmail(senderEmail, cleanPassword);

      // 2. Tạo nội dung email HTML cao cấp chuẩn WEARSY
      final displayName = (userName != null && userName.isNotEmpty) ? userName : 'Bạn';

      final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>WEARSY Verification Code</title>
</head>
<body style="margin: 0; padding: 0; background-color: #0b0c15; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; color: #ffffff;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #0b0c15; padding: 40px 10px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" style="max-width: 520px; background: linear-gradient(145deg, #181926 0%, #12131e 100%); border-radius: 24px; border: 1px solid rgba(255, 255, 255, 0.08); overflow: hidden; box-shadow: 0 20px 50px rgba(0,0,0,0.5);">
          <!-- Header Banner -->
          <tr>
            <td align="center" style="padding: 36px 30px 20px; background: linear-gradient(135deg, rgba(124, 77, 255, 0.15) 0%, rgba(255, 110, 145, 0.15) 100%); border-bottom: 1px solid rgba(255, 255, 255, 0.05);">
              <h1 style="margin: 0; font-size: 32px; font-weight: 800; letter-spacing: 3px; background: linear-gradient(135deg, #7C4DFF 0%, #B388FF 50%, #FF6E91 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent;">WEARSY</h1>
              <p style="margin: 8px 0 0; font-size: 13px; color: #9E9EAF; letter-spacing: 1px;">YOUR WARDROBE, SMARTER</p>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding: 35px 35px 25px;">
              <p style="margin: 0 0 15px; font-size: 16px; color: #ffffff; font-weight: 600;">Xin chào $displayName,</p>
              <p style="margin: 0 0 25px; font-size: 14px; line-height: 1.6; color: #B0B0C3;">
                Cảm ơn bạn đã đăng ký tài khoản tại <strong>WEARSY</strong>. Để hoàn tất việc kích hoạt tài khoản và bảo vệ an toàn cho tủ đồ số thông minh của bạn, vui lòng sử dụng mã xác thực bên dưới:
              </p>

              <!-- OTP Box -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin: 25px 0;">
                <tr>
                  <td align="center" style="padding: 22px; background: linear-gradient(135deg, rgba(124, 77, 255, 0.18) 0%, rgba(255, 110, 145, 0.1) 100%); border-radius: 18px; border: 1.5px dashed #7C4DFF;">
                    <div style="font-size: 12px; font-weight: 600; color: #B388FF; letter-spacing: 2px; margin-bottom: 8px; text-transform: uppercase;">MÃ XÁC THỰC OTP</div>
                    <div style="font-size: 38px; font-weight: 900; letter-spacing: 12px; color: #ffffff; text-indent: 12px;">$otp</div>
                    <div style="font-size: 12px; color: #9E9EAF; margin-top: 8px;">Hiệu lực trong vòng <strong>5 phút</strong></div>
                  </td>
                </tr>
              </table>

              <p style="margin: 20px 0 0; font-size: 13px; line-height: 1.5; color: #7B7B8F;">
                ⚠️ <em>Lưu ý: Không chia sẻ mã này với bất kỳ ai để đảm bảo an toàn cho tài khoản của bạn. Nếu bạn không yêu cầu mã này, vui lòng bỏ qua email.</em>
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td align="center" style="padding: 20px 30px 30px; border-top: 1px solid rgba(255, 255, 255, 0.05); background: rgba(0, 0, 0, 0.2);">
              <p style="margin: 0; font-size: 12px; color: #66667A;">
                © 2026 Dự án EXE101 WEARSY. Bảo lưu mọi quyền.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''';

      // 3. Khởi tạo đối tượng Message
      final message = Message()
        ..from = Address(senderFrom, senderFromName)
        ..recipients.add(toEmail.trim())
        ..subject = 'WEARSY Verification Code'
        ..html = htmlContent;

      developer.log('Sending OTP email to: $toEmail via $senderEmail', name: 'EmailService');
      final sendReport = await send(message, smtpServer);
      developer.log('Email sent successfully: ${sendReport.toString()}', name: 'EmailService');

      return EmailSendResult(success: true);
    } on MailerException catch (e) {
      developer.log('MailerException sending email: ${e.toString()}', name: 'EmailService');
      String friendlyMsg = 'Không thể gửi email OTP.';
      for (var p in e.problems) {
        developer.log('Problem: ${p.code}: ${p.msg}', name: 'EmailService');
        if (p.msg.contains('Username and Password not accepted') || p.msg.contains('BadCredentials')) {
          friendlyMsg = 'Gmail hoặc Mật khẩu ứng dụng (App Password) không hợp lệ.';
        }
      }
      return EmailSendResult(
        success: false,
        errorMessage: friendlyMsg,
      );
    } catch (e) {
      developer.log('Error sending email: $e', name: 'EmailService');
      return EmailSendResult(
        success: false,
        errorMessage: 'Lỗi gửi email: ${e.toString()}',
      );
    }
  }
}

class EmailSendResult {
  final bool success;
  final String? errorMessage;
  final bool isConfigMissing;

  EmailSendResult({
    required this.success,
    this.errorMessage,
    this.isConfigMissing = false,
  });
}
