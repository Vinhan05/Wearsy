import {
  Controller,
  Post,
  Get,
  Put,
  Query,
  Body,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { UsersService } from '../services/users.service';

@ApiTags('Users & VIP')
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post('upgrade-vip')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Nâng cấp tài khoản VIP bằng mã Coupon hoặc trực tiếp trên PostgreSQL Server',
  })
  @ApiResponse({ status: 200, description: 'Nâng cấp VIP thành công' })
  async upgradeVip(@Body() body: any) {
    const coupon = body?.coupon || 'WEARSY';
    return this.usersService.upgradeVip(coupon, body?.email);
  }

  @Get('profile')
  @ApiOperation({ summary: 'Lấy thông tin tài khoản từ PostgreSQL Database' })
  async getProfile(@Query('email') email?: string) {
    return this.usersService.getProfile(email);
  }

  @Put('profile')
  @ApiOperation({
    summary: 'Cập nhật thông tin tài khoản trên PostgreSQL Database',
  })
  async updateProfile(@Body() body: any) {
    return this.usersService.updateProfile(body?.email, body);
  }

  @Get('style-profile')
  @ApiOperation({ summary: 'Lấy hồ sơ phong cách thời trang của người dùng' })
  async getStyleProfile(@Query('email') email?: string) {
    const profile = await this.usersService.getProfile(email);
    return {
      success: true,
      data: {
        userId: profile.id,
        preferred_styles: ['Casual', 'Minimalism', 'Smart Casual'],
        color_preferences: { primary: ['Black', 'White', 'Beige'] },
        budget_range: { tier: 'medium' },
      },
    };
  }
}
