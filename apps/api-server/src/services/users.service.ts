import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserEntity } from '../models/user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(UserEntity)
    private readonly userRepository: Repository<UserEntity>,
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
        'Chúc mừng! Bạn đã nâng cấp thành công gói VIP Fashionista 1 năm.',
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
    const cleanEmail = (email || 'demo@wearsy.app').trim().toLowerCase();
    let user = await this.userRepository.findOne({
      where: { email: cleanEmail },
    });
    if (!user) {
      user = this.userRepository.create({
        email: cleanEmail,
        full_name: cleanEmail.split('@')[0],
        password_hash: 'SSO_AUTO_ACCOUNT',
        role: 'USER',
        is_vip: false,
        is_active: true,
      });
      await this.userRepository.save(user);
    }
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

  async updateProfile(
    email: string,
    data: { full_name?: string; avatar_url?: string },
  ) {
    const cleanEmail = (email || 'demo@wearsy.app').trim().toLowerCase();
    let user = await this.userRepository.findOne({
      where: { email: cleanEmail },
    });
    if (!user) {
      user = this.userRepository.create({
        email: cleanEmail,
        full_name: data.full_name || cleanEmail.split('@')[0],
        avatar_url: data.avatar_url || null,
        password_hash: 'SSO_AUTO_ACCOUNT',
        role: 'USER',
        is_vip: false,
        is_active: true,
      });
      await this.userRepository.save(user);
    } else {
      if (data.full_name) user.full_name = data.full_name.trim();
      if (data.avatar_url !== undefined) user.avatar_url = data.avatar_url;
      await this.userRepository.save(user);
    }

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
}
