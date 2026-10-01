import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';

@ApiTags('Health')
@Controller('health')
export class AppController {
  @Get()
  @ApiOperation({
    summary: 'Health Check Endpoint for CI/CD Smoke Tests & Container Probes',
  })
  @ApiResponse({
    status: 200,
    description: 'Service is healthy and ready to serve traffic',
  })
  checkHealth() {
    return {
      status: 'ok',
      service: 'wearsy-backend',
      version: '1.0.0',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      environment: process.env.NODE_ENV || 'production',
    };
  }
}
