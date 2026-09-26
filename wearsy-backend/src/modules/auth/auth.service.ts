import { Injectable, BadRequestException } from '@nestjs/common';
import { MailService } from './mail.service';

interface PendingOtp {
  code: string;
  expiresAt: Date;
  fullName?: string;
}

@Injectable()
export class AuthService {
  private readonly pendingOtps = new Map<string, PendingOtp>();

  constructor(private readonly mailService: MailService) {}

  async sendOtp(email: string, fullName?: string): Promise<{ success: boolean; message: string }> {
    if (!email || !email.includes('@')) {
      throw new BadRequestException('Email không hợp lệ.');
    }

    const cleanEmail = email.trim().toLowerCase();
    // Sinh mã ngẫu nhiên 6 chữ số thật
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 phút

    this.pendingOtps.set(cleanEmail, { code: otp, expiresAt, fullName });

    const result = await this.mailService.sendOtpEmail(cleanEmail, otp, fullName);
    if (!result.success) {
      throw new BadRequestException(result.message || 'Không thể gửi mã OTP tới email.');
    }

    return {
      success: true,
      message: `Đã gửi mã xác thực tới ${cleanEmail}. Vui lòng kiểm tra hộp thư.`,
    };
  }

  async verifyOtp(email: string, otp: string): Promise<{ success: boolean; message: string }> {
    const cleanEmail = email.trim().toLowerCase();
    const pending = this.pendingOtps.get(cleanEmail);

    if (!pending) {
      throw new BadRequestException('Không tìm thấy yêu cầu xác thực OTP cho email này.');
    }

    if (new Date() > pending.expiresAt) {
      this.pendingOtps.delete(cleanEmail);
      throw new BadRequestException('Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới.');
    }

    if (pending.code !== otp.trim()) {
      throw new BadRequestException('Mã OTP không chính xác.');
    }

    this.pendingOtps.delete(cleanEmail);
    return {
      success: true,
      message: 'Xác thực OTP thành công!',
    };
  }
}
