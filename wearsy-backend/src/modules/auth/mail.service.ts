import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);
  private transporter: nodemailer.Transporter | null = null;

  constructor(private readonly configService: ConfigService) {
    this.initTransporter();
  }

  private initTransporter() {
    const host =
      process.env.MAIL_HOST ||
      this.configService.get<string>('MAIL_HOST') ||
      process.env.SMTP_HOST ||
      this.configService.get<string>('SMTP_HOST') ||
      'smtp-relay.brevo.com';

    const port =
      Number(process.env.MAIL_PORT || this.configService.get<number>('MAIL_PORT')) ||
      Number(process.env.SMTP_PORT || this.configService.get<number>('SMTP_PORT')) ||
      587;

    const secure = false; // Bắt buộc false vì sử dụng port 587 STARTTLS

    const user = (
      process.env.MAIL_USER ||
      this.configService.get<string>('MAIL_USER') ||
      process.env.SMTP_USER ||
      this.configService.get<string>('SMTP_USER') ||
      ''
    ).trim();

    const rawPass =
      process.env.MAIL_PASS ||
      this.configService.get<string>('MAIL_PASS') ||
      process.env.SMTP_PASS ||
      this.configService.get<string>('SMTP_PASS') ||
      '';
    const pass = rawPass.replace(/\s+/g, '');

    if (user && pass) {
      this.transporter = nodemailer.createTransport({
        host,
        port,
        secure,
        auth: {
          user,
          pass,
        },
      });
      this.logger.log(`SMTP Mailer initialized successfully for host: ${host}, user: ${user}`);
    } else {
      this.logger.warn(
        'MAIL_USER (hoặc SMTP_USER) / MAIL_PASS (hoặc SMTP_PASS) chưa được cấu hình trong .env. Email sẽ không thể gửi đi.',
      );
    }
  }

  async sendOtpEmail(toEmail: string, otp: string, userName?: string): Promise<{ success: boolean; message?: string }> {
    if (!this.transporter) {
      this.initTransporter();
      if (!this.transporter) {
        return {
          success: false,
          message: 'Server chưa được cấu hình thông tin SMTP (MAIL_USER / MAIL_PASS trong file .env).',
        };
      }
    }

    const from =
      process.env.MAIL_FROM ||
      this.configService.get<string>('MAIL_FROM') ||
      process.env.SMTP_FROM ||
      this.configService.get<string>('SMTP_FROM') ||
      'WEARSY Support <vo.thedan@outlook.com>';
    const displayName = userName || 'Bạn';

    const html = `
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
          <tr>
            <td align="center" style="padding: 36px 30px 20px; background: linear-gradient(135deg, rgba(124, 77, 255, 0.15) 0%, rgba(255, 110, 145, 0.15) 100%); border-bottom: 1px solid rgba(255, 255, 255, 0.05);">
              <h1 style="margin: 0; font-size: 32px; font-weight: 800; letter-spacing: 3px; background: linear-gradient(135deg, #7C4DFF 0%, #B388FF 50%, #FF6E91 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent;">WEARSY</h1>
              <p style="margin: 8px 0 0; font-size: 13px; color: #9E9EAF; letter-spacing: 1px;">YOUR WARDROBE, SMARTER</p>
            </td>
          </tr>
          <tr>
            <td style="padding: 35px 35px 25px;">
              <p style="margin: 0 0 15px; font-size: 16px; color: #ffffff; font-weight: 600;">Xin chào ${displayName},</p>
              <p style="margin: 0 0 25px; font-size: 14px; line-height: 1.6; color: #B0B0C3;">
                Cảm ơn bạn đã đăng ký tài khoản tại <strong>WEARSY</strong>. Vui lòng sử dụng mã xác thực dưới đây để kích hoạt tài khoản:
              </p>
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin: 25px 0;">
                <tr>
                  <td align="center" style="padding: 22px; background: linear-gradient(135deg, rgba(124, 77, 255, 0.18) 0%, rgba(255, 110, 145, 0.1) 100%); border-radius: 18px; border: 1.5px dashed #7C4DFF;">
                    <div style="font-size: 12px; font-weight: 600; color: #B388FF; letter-spacing: 2px; margin-bottom: 8px; text-transform: uppercase;">MÃ XÁC THỰC OTP</div>
                    <div style="font-size: 38px; font-weight: 900; letter-spacing: 12px; color: #ffffff; text-indent: 12px;">${otp}</div>
                    <div style="font-size: 12px; color: #9E9EAF; margin-top: 8px;">Hiệu lực trong vòng <strong>5 phút</strong></div>
                  </td>
                </tr>
              </table>
              <p style="margin: 20px 0 0; font-size: 13px; line-height: 1.5; color: #7B7B8F;">
                ⚠️ <em>Không chia sẻ mã này cho bất kỳ ai để đảm bảo an toàn cho tài khoản của bạn.</em>
              </p>
            </td>
          </tr>
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
`;

    try {
      await this.transporter.sendMail({
        from,
        to: toEmail,
        subject: 'WEARSY Verification Code',
        html,
      });
      this.logger.log(`OTP email sent successfully to: ${toEmail}`);
      return { success: true };
    } catch (error) {
      this.logger.error(`Failed to send email to ${toEmail}: ${error.message}`);
      return {
        success: false,
        message: `Lỗi máy chủ gửi mail: ${error.message}`,
      };
    }
  }
}
