import {
  Controller,
  Post,
  Get,
  Body,
  HttpCode,
  HttpStatus,
  BadRequestException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { AiGatewayService } from '../services/ai-gateway.service';

@ApiTags('System & AI Bridge')
@Controller('system')
export class SystemController {
  constructor(private readonly aiGatewayService: AiGatewayService) {}

  @Post('register-ai-url')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Tự động đăng ký URL AI Orchestrator (Cloudflare/Ngrok) từ máy local lên Render',
    description:
      'Được gọi tự động bởi start_tunnel.bat / unified_ai_runner.py khi khởi động AI trên máy tính cá nhân.',
  })
  @ApiResponse({
    status: 200,
    description: 'Cập nhật AI URL động thành công',
  })
  registerAiUrl(@Body() body: { url: string; secret?: string }) {
    if (!body || !body.url || typeof body.url !== 'string') {
      throw new BadRequestException('Vui lòng cung cấp URL hợp lệ.');
    }

    const registered = this.aiGatewayService.setDynamicUrl(body.url);
    return {
      success: true,
      message: 'Đã tự động cập nhật AI Orchestrator URL thành công!',
      active_url: registered,
      registered_at: new Date().toISOString(),
    };
  }

  @Get('ai-status')
  @ApiOperation({
    summary: 'Kiểm tra URL AI Orchestrator đang hoạt động trên Render',
  })
  getAiStatus() {
    return this.aiGatewayService.getStatus();
  }
}
