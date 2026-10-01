import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserEntity } from './entities/user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(UserEntity)
    private readonly userRepository: Repository<UserEntity>,
  ) {}

  async upgradeVip(coupon: string, email?: string) {
    const cleanCoupon = (coupon || '').trim().toUpperCase();

    if (cleanCoupon !== 'WEARSY') {
      throw new BadRequestException(
        'Mã Coupon không hợp lệ. Vui lòng nhập đúng mã "WEARSY" để nhận 7 ngày VIP!',
      );
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

    // Cộng thêm 7 ngày VIP
    const vipExpiresAt = new Date(baseTime.getTime() + 7 * 24 * 60 * 60 * 1000);

    if (user) {
      user.is_vip = true;
      user.vip_expires_at = vipExpiresAt;
      await this.userRepository.save(user);
    }

    return {
      success: true,
      message:
        'Chúc mừng! Bạn đã nâng cấp thành công gói VIP Fashionista 7 ngày.',
      is_vip: true,
      vip_expires_at: vipExpiresAt.toISOString(),
      days_added: 7,
      user: user
        ? {
            id: user.id,
            email: user.email,
            full_name: user.full_name,
            is_vip: user.is_vip,
            vip_expires_at: user.vip_expires_at,
          }
        : null,
    };
  }
}
