import { Controller, Post, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { AuthService } from './auth.service';

class SendOtpDto {
  email: string;
  fullName?: string;
}

class VerifyOtpDto {
  email: string;
  otp: string;
}

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('send-otp')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Gửi mã OTP xác thực tới Email người dùng (sử dụng SMTP server-side)' })
  @ApiResponse({ status: 200, description: 'Gửi OTP thành công' })
  @ApiResponse({ status: 400, description: 'Email không hợp lệ hoặc lỗi gửi thư' })
  async sendOtp(@Body() body: SendOtpDto) {
    return this.authService.sendOtp(body.email, body.fullName);
  }

  @Post('verify-otp')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Xác thực mã OTP 6 số của Email' })
  @ApiResponse({ status: 200, description: 'Xác thực thành công' })
  @ApiResponse({ status: 400, description: 'Mã OTP không hợp lệ hoặc hết hạn' })
  async verifyOtp(@Body() body: VerifyOtpDto) {
    return this.authService.verifyOtp(body.email, body.otp);
  }
}
