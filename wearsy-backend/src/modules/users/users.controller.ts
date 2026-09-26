import { Controller, Post, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { UsersService } from './users.service';

class UpgradeVipDto {
  coupon: string;
  email?: string;
}

@ApiTags('Users & VIP')
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post('upgrade-vip')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Nâng cấp tài khoản VIP bằng mã Coupon (Nhập mã "WEARSY" được 7 ngày VIP)' })
  @ApiResponse({ status: 200, description: 'Nâng cấp VIP thành công' })
  @ApiResponse({ status: 400, description: 'Mã coupon không hợp lệ' })
  async upgradeVip(@Body() body: UpgradeVipDto) {
    return this.usersService.upgradeVip(body.coupon, body.email);
  }
}
