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

  @Get('ai-status')
  @ApiOperation({
    summary: 'Kiểm tra URL AI Orchestrator đang hoạt động trên Render',
  })
  getAiStatus() {
    return this.aiGatewayService.getStatus();
  }
}
