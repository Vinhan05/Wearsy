import {
  Injectable,
  BadRequestException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { UserEntity } from '../users/entities/user.entity';
import { MailService } from './mail.service';

interface PendingOtp {
  code: string;
  expiresAt: Date;
  fullName?: string;
  /** Số lần nhập sai tối đa trước khi OTP bị hủy */
  failedAttempts: number;
}

@Injectable()
export class AuthService {
  private readonly pendingOtps = new Map<string, PendingOtp>();
  /** Token blacklist — lưu các JWT đã bị thu hồi (logout / đổi mật khẩu) */
  private readonly revokedTokens = new Set<string>();

  private readonly OTP_MAX_ATTEMPTS = 5;
  private readonly BCRYPT_ROUNDS = 12;

  constructor(
    @InjectRepository(UserEntity)
    private readonly userRepository: Repository<UserEntity>,
    private readonly mailService: MailService,
    private readonly jwtService: JwtService,
  ) {}

  // ─── Password Hashing ────────────────────────────────────────────────────────

  async hashPassword(plaintext: string): Promise<string> {
    return bcrypt.hash(plaintext, this.BCRYPT_ROUNDS);
  }

  async comparePassword(plaintext: string, hash: string): Promise<boolean> {
    return bcrypt.compare(plaintext, hash);
  }

  // ─── Register ────────────────────────────────────────────────────────────────

  async register(body: {
    email: string;
    password: string;
    full_name: string;
  }): Promise<{ token: string; user: Partial<UserEntity> }> {
    const cleanEmail = body.email.trim().toLowerCase();

    const existing = await this.userRepository.findOne({
      where: { email: cleanEmail },
    });
    if (existing) {
      // Thông báo chung để tránh User Enumeration
      throw new BadRequestException(
        'Email hoặc thông tin đăng ký không hợp lệ.',
      );
    }

    const passwordHash = await this.hashPassword(body.password);

    const user = this.userRepository.create({
      email: cleanEmail,
      password_hash: passwordHash,
      full_name: body.full_name,
      role: 'USER',
      is_vip: false,
      is_active: true,
    });
    await this.userRepository.save(user);

    const token = this.generateToken(user);
    return {
      token,
      user: {
        id: user.id,
        email: user.email,
        full_name: user.full_name,
        role: user.role,
        is_vip: user.is_vip,
      },
    };
  }

  // ─── Login ───────────────────────────────────────────────────────────────────

  async login(body: {
    email: string;
    password: string;
  }): Promise<{ token: string; expires_in: number; user: Partial<UserEntity> }> {
    const cleanEmail = body.email.trim().toLowerCase();

    const user = await this.userRepository.findOne({
      where: { email: cleanEmail },
    });

    // Luôn trả về thông báo chung để tránh User Enumeration Attack
    if (!user || !user.is_active) {
      throw new UnauthorizedException(
        'Email hoặc mật khẩu không chính xác. Vui lòng kiểm tra lại.',
      );
    }

    const isPasswordValid = await this.comparePassword(
      body.password,
      user.password_hash,
    );
    if (!isPasswordValid) {
      throw new UnauthorizedException(
        'Email hoặc mật khẩu không chính xác. Vui lòng kiểm tra lại.',
      );
    }

    const token = this.generateToken(user);
    return {
      token,
      expires_in: 86400, // 24 giờ
      user: {
        id: user.id,
        email: user.email,
        full_name: user.full_name,
        role: user.role,
        is_vip: user.is_vip,
        vip_expires_at: user.vip_expires_at,
      },
    };
  }

  // ─── SSO Login (Google / Facebook) ──────────────────────────────────────────

  async ssoLogin(body: {
    email: string;
    full_name?: string;
    avatar_url?: string;
  }): Promise<{ token: string; expires_in: number; user: Partial<UserEntity> }> {
    const cleanEmail = (body.email || 'user.sso@wearsy.app').trim().toLowerCase();
    let user = await this.userRepository.findOne({
      where: { email: cleanEmail },
    });

    if (!user) {
      user = this.userRepository.create({
        email: cleanEmail,
        password_hash: 'SSO_AUTH_ACCOUNT',
        full_name: (body.full_name && body.full_name.trim().length > 0)
            ? body.full_name.trim()
            : cleanEmail.split('@')[0],
        avatar_url: body.avatar_url || null,
        role: 'USER',
        is_vip: false,
        is_active: true,
      });
      await this.userRepository.save(user);
    } else {
      let changed = false;
      if (body.full_name && body.full_name.trim().length > 0 && user.full_name !== body.full_name.trim()) {
        user.full_name = body.full_name.trim();
        changed = true;
      }
      if (body.avatar_url && user.avatar_url !== body.avatar_url) {
        user.avatar_url = body.avatar_url;
        changed = true;
      }
      if (changed) {
        await this.userRepository.save(user);
      }
    }

    const token = this.generateToken(user);
    return {
      token,
      expires_in: 86400,
      user: {
        id: user.id,
        email: user.email,
        full_name: user.full_name,
        avatar_url: user.avatar_url,
        role: user.role,
        is_vip: user.is_vip,
        vip_expires_at: user.vip_expires_at,
      },
    };
  }

  // ─── JWT ─────────────────────────────────────────────────────────────────────

  private generateToken(user: UserEntity): string {
    return this.jwtService.sign(
      { sub: user.id, email: user.email, role: user.role },
      { expiresIn: '24h' },
    );
  }

  /** Kiểm tra token có bị thu hồi không (blacklist check) */
  isTokenRevoked(token: string): boolean {
    return this.revokedTokens.has(token);
  }

  /** Thu hồi token khi logout hoặc đổi mật khẩu */
  revokeToken(token: string): void {
    this.revokedTokens.add(token);
    // Tự dọn sau 25 giờ (> JWT expiry 24h)
    setTimeout(() => this.revokedTokens.delete(token), 25 * 60 * 60 * 1000);
  }

  // ─── OTP ─────────────────────────────────────────────────────────────────────

  async sendOtp(
    email: string,
    fullName?: string,
  ): Promise<{ success: boolean; message: string }> {
    if (!email || !email.includes('@')) {
      throw new BadRequestException('Email không hợp lệ.');
    }

    const cleanEmail = email.trim().toLowerCase();
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 phút

    this.pendingOtps.set(cleanEmail, {
      code: otp,
      expiresAt,
      fullName,
      failedAttempts: 0,
    });

    const result = await this.mailService.sendOtpEmail(cleanEmail, otp, fullName);
    if (!result.success) {
      throw new BadRequestException(
        result.message || 'Không thể gửi mã OTP tới email.',
      );
    }

    return {
      success: true,
      message: `Đã gửi mã xác thực tới ${cleanEmail}. Vui lòng kiểm tra hộp thư.`,
    };
  }

  async verifyOtp(
    email: string,
    otp: string,
  ): Promise<{ success: boolean; message: string }> {
    if (!email || !otp) {
      throw new BadRequestException('Email và mã OTP là bắt buộc.');
    }

    const cleanEmail = email.trim().toLowerCase();
    const cleanOtp = otp.toString().trim();
    const pending = this.pendingOtps.get(cleanEmail);

    if (!pending) {
      throw new BadRequestException(
        'Không tìm thấy yêu cầu xác thực OTP cho email này.',
      );
    }

    // Kiểm tra hết hạn
    if (new Date() > pending.expiresAt) {
      this.pendingOtps.delete(cleanEmail);
      throw new BadRequestException('Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới.');
    }

    // Kiểm tra số lần nhập sai (chống brute-force OTP)
    if (pending.failedAttempts >= this.OTP_MAX_ATTEMPTS) {
      this.pendingOtps.delete(cleanEmail);
      throw new BadRequestException(
        `Bạn đã nhập sai OTP ${this.OTP_MAX_ATTEMPTS} lần. Mã đã bị hủy, vui lòng yêu cầu gửi lại.`,
      );
    }

    if (pending.code !== cleanOtp) {
      pending.failedAttempts++;
      const remaining = this.OTP_MAX_ATTEMPTS - pending.failedAttempts;
      throw new BadRequestException(
        remaining > 0
          ? `Mã OTP không chính xác. Còn ${remaining} lần thử.`
          : `Mã OTP không chính xác. Đã hết lần thử — mã bị hủy.`,
      );
    }

    // OTP hợp lệ — xóa để chống replay
    this.pendingOtps.delete(cleanEmail);
    return { success: true, message: 'Xác thực OTP thành công!' };
  }

  // ─── Change Password (invalidate old sessions) ────────────────────────────────

  async changePassword(
    userId: string,
    oldPassword: string,
    newPassword: string,
    currentToken: string,
  ): Promise<void> {
    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) throw new BadRequestException('Không tìm thấy tài khoản.');

    const isValid = await this.comparePassword(oldPassword, user.password_hash);
    if (!isValid) {
      throw new BadRequestException(
        'Mật khẩu hiện tại không chính xác. Vui lòng kiểm tra lại.',
      );
    }

    user.password_hash = await this.hashPassword(newPassword);
    await this.userRepository.save(user);

    // Thu hồi token hiện tại — bắt buộc đăng nhập lại
    this.revokeToken(currentToken);
  }
}
