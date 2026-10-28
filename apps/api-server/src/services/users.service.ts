import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserEntity } from '../models/user.entity';
import { UserProfileEntity } from '../models/user-profile.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(UserEntity)
    private readonly userRepository: Repository<UserEntity>,
    @InjectRepository(UserProfileEntity)
    private readonly userProfileRepository: Repository<UserProfileEntity>,
  ) {}

  async upgradeVip(coupon: string, email?: string) {
    const cleanCoupon = (coupon || '').trim().toUpperCase();

    if (cleanCoupon !== 'WEARSY') {
      throw new BadRequestException('Mã Coupon không hợp lệ!');
    }

    const cleanEmail = email?.trim().toLowerCase();
    let user: UserEntity | null = null;

    if (cleanEmail) {
      user = await this.userRepository.findOne({
        where: { email: cleanEmail },
      });
    }

    const now = new Date();
    let baseTime = now;

    if (user && user.vip_expires_at) {
      const currentExpiry = new Date(user.vip_expires_at);
      if (currentExpiry > now) {
        baseTime = currentExpiry;
      }
    }

    // Cộng thêm 1 năm (365 ngày) VIP
    const vipExpiresAt = new Date(
      baseTime.getTime() + 365 * 24 * 60 * 60 * 1000,
    );

    if (!user && cleanEmail) {
      user = this.userRepository.create({
        email: cleanEmail,
        full_name: cleanEmail.split('@')[0],
        password_hash: 'SSO_AUTO_ACCOUNT',
        role: 'USER',
        is_vip: true,
        vip_expires_at: vipExpiresAt,
        is_active: true,
      });
      await this.userRepository.save(user);
    } else if (user) {
      user.is_vip = true;
      user.vip_expires_at = vipExpiresAt;
      await this.userRepository.save(user);
    }

    return {
      success: true,
      message:
        'Chúc mừng! Bạn đã nâng cấp thành công gói WEARSY PREMIUM Fashionista 1 năm.',
      is_vip: true,
      vip_expires_at: vipExpiresAt.toISOString(),
      days_added: 365,
      user: user
        ? {
            id: user.id,
            email: user.email,
            full_name: user.full_name,
            avatar_url: user.avatar_url,
            is_vip: user.is_vip,
            vip_expires_at: user.vip_expires_at,
          }
        : null,
    };
  }

  async getProfile(email?: string) {
    if (!email || !email.trim()) {
      throw new BadRequestException('Email người dùng là bắt buộc!');
    }
    const cleanEmail = email.trim().toLowerCase();
    const user = await this.userRepository.findOne({
      where: { email: cleanEmail },
      relations: ['profile'],
    });
    if (!user) {
      throw new BadRequestException('Không tìm thấy tài khoản người dùng!');
    }
    return {
      id: user.id,
      email: user.email,
      full_name: user.full_name,
      avatar_url: user.avatar_url,
      role: user.role,
      is_vip: user.is_vip,
      vip_expires_at: user.vip_expires_at,
      profile: user.profile || null,
    };
  }

  async updateProfile(
    email: string,
    data: { full_name?: string; avatar_url?: string },
  ) {
    if (!email || !email.trim()) {
      throw new BadRequestException('Email người dùng là bắt buộc!');
    }
    const cleanEmail = email.trim().toLowerCase();
    const user = await this.userRepository.findOne({
      where: { email: cleanEmail },
    });
    if (!user) {
      throw new BadRequestException('Không tìm thấy tài khoản người dùng!');
    }
    if (data.full_name) user.full_name = data.full_name.trim();
    if (data.avatar_url !== undefined) user.avatar_url = data.avatar_url;
    await this.userRepository.save(user);

    return {
      id: user.id,
      email: user.email,
      full_name: user.full_name,
      avatar_url: user.avatar_url,
      role: user.role,
      is_vip: user.is_vip,
      vip_expires_at: user.vip_expires_at,
    };
  }

  /**
   * Đồng bộ hồ sơ phong cách cá nhân (Style Persona) từ Client lên Cloud Database
   */
  async syncProfile(
    email: string,
    data: {
      preferred_styles?: string[];
      color_preferences?: Record<string, any>;
      budget_range?: Record<string, any>;
      body_measurements?: Record<string, any>;
      ai_learning_data?: Record<string, any>;
    },
  ) {
    if (!email || !email.trim()) {
      throw new BadRequestException('Email người dùng là bắt buộc!');
    }
    const cleanEmail = email.trim().toLowerCase();
    const user = await this.userRepository.findOne({
      where: { email: cleanEmail },
      relations: ['profile'],
    });

    if (!user) {
      throw new BadRequestException('Không tìm thấy tài khoản người dùng!');
    }

    let profile = user.profile;
    if (!profile) {
      profile = this.userProfileRepository.create({
        user_id: user.id,
      });
    }

    if (data.preferred_styles) profile.preferred_styles = data.preferred_styles;
    if (data.color_preferences)
      profile.color_preferences = data.color_preferences;
    if (data.budget_range) profile.budget_range = data.budget_range;
    if (data.body_measurements)
      profile.body_measurements = data.body_measurements;
    if (data.ai_learning_data) profile.ai_learning_data = data.ai_learning_data;

    const savedProfile = await this.userProfileRepository.save(profile);
    return {
      success: true,
      message:
        'Hồ sơ phong cách cá nhân đã được đồng bộ lên Cloud Database thành công!',
      profile: savedProfile,
    };
  }
}
