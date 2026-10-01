import {
  Controller,
  Post,
  Body,
  HttpCode,
  HttpStatus,
  Headers,
  Request,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { AuthService } from '../services/auth.service';
import {
  RegisterDto,
  LoginDto,
  SsoLoginDto,
  SendOtpDto,
  VerifyOtpDto,
  ChangePasswordDto,
} from '../dto/auth.dto';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  /** Đăng ký tài khoản mới — giới hạn 5 lần/phút */
  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @ApiOperation({
    summary: 'Đăng ký tài khoản mới (password được hash bcrypt)',
  })
  @ApiResponse({ status: 201, description: 'Đăng ký thành công, trả về JWT' })
  @ApiResponse({ status: 400, description: 'Dữ liệu không hợp lệ' })
  async register(@Body() body: RegisterDto) {
    return this.authService.register(body);
  }

  /** Đăng nhập — giới hạn 10 lần/phút (server-side brute force protection) */
  @Post('login')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @ApiOperation({
    summary: 'Đăng nhập — rate limited 10 req/phút, thông báo lỗi chung',
  })
  @ApiResponse({ status: 200, description: 'Đăng nhập thành công, trả về JWT' })
  @ApiResponse({
    status: 401,
    description: 'Thông tin đăng nhập không chính xác',
  })
  async login(@Body() body: LoginDto) {
    return this.authService.login(body);
  }

  /** Đăng nhập Google SSO — tự động lưu trữ tài khoản vào Database Server */
  @Post('google')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Đăng nhập Google SSO — lưu và đồng bộ vào PostgreSQL Database',
  })
  async googleLogin(@Body() body: SsoLoginDto) {
    return this.authService.ssoLogin(body);
  }

  /** Đăng nhập Facebook SSO — tự động lưu trữ tài khoản vào Database Server */
  @Post('facebook')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Đăng nhập Facebook SSO — lưu và đồng bộ vào PostgreSQL Database',
  })
  async facebookLogin(@Body() body: SsoLoginDto) {
    return this.authService.ssoLogin(body);
  }

  /** Đăng xuất — thu hồi token (blacklist) */
  @Post('logout')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Đăng xuất — token bị thu hồi ngay lập tức' })
  async logout(@Headers('authorization') authHeader: string) {
    const token = authHeader?.replace('Bearer ', '').trim();
    if (token) {
      this.authService.revokeToken(token);
    }
    return { success: true, message: 'Đăng xuất thành công.' };
  }

  /** Đổi mật khẩu — vô hiệu hóa tất cả session cũ */
  @Post('change-password')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Đổi mật khẩu — thu hồi token hiện tại' })
  async changePassword(
    @Body() body: ChangePasswordDto,
    @Headers('authorization') authHeader: string,
    @Request() req: any,
  ) {
    const token = authHeader?.replace('Bearer ', '').trim() ?? '';
    const userId: string = req.user?.sub ?? req.user?.id ?? '';
    await this.authService.changePassword(
      userId,
      body.old_password,
      body.new_password,
      token,
    );
    return {
      success: true,
      message: 'Đổi mật khẩu thành công. Vui lòng đăng nhập lại.',
    };
  }

  /** Gửi OTP — giới hạn 3 lần/phút */
  @Post('send-otp')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 3, ttl: 60000 } })
  @ApiOperation({
    summary: 'Gửi mã OTP xác thực tới Email người dùng (SMTP server-side)',
  })
  @ApiResponse({ status: 200, description: 'Gửi OTP thành công' })
  @ApiResponse({
    status: 400,
    description: 'Email không hợp lệ hoặc lỗi gửi thư',
  })
  async sendOtp(@Body() body: SendOtpDto) {
    return this.authService.sendOtp(body.email, body.fullName);
  }

  /** Xác thực OTP — giới hạn 5 lần/phút */
  @Post('verify-otp')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @ApiOperation({
    summary: 'Xác thực mã OTP 6 số — tối đa 5 lần nhập sai',
  })
  @ApiResponse({ status: 200, description: 'Xác thực thành công' })
  @ApiResponse({ status: 400, description: 'Mã OTP không hợp lệ hoặc hết hạn' })
  async verifyOtp(@Body() body: VerifyOtpDto) {
    return this.authService.verifyOtp(body.email, body.otp);
  }
}
