import {
  Controller,
  Post,
  Get,
  Body,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { GamificationService } from '../services/gamification.service';
import { ColorScoreRequestDto } from '../dto/color-score.dto';

@ApiTags('Gamification & Style Score')
@Controller('gamification')
export class GamificationController {
  constructor(private readonly gamificationService: GamificationService) {}

  @Post('color-score')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Tính toán và chấm điểm phối màu (Color Harmony Score) cho outfit',
    description:
      'Đánh giá sự kết hợp màu sắc dựa trên quy tắc bánh xe màu sắc (Analogous, Complementary, Triadic, 60-30-10) và trả về điểm số cùng lời khuyên cải thiện.',
  })
  @ApiResponse({
    status: 200,
    description: 'Điểm số phối màu và phân tích quy tắc bánh xe màu sắc',
  })
  async calculateColorScore(@Body() dto: ColorScoreRequestDto) {
    const result = await this.gamificationService.calculateColorScore(dto);
    return {
      success: true,
      code: 200,
      data: result,
      meta: {
        timestamp: new Date().toISOString(),
      },
    };
  }

  @Get('challenges')
  @ApiOperation({
    summary: 'Lấy danh sách thử thách phối đồ theo chủ đề và huy hiệu',
    description:
      'Cung cấp các nhiệm vụ phối đồ hàng tuần giúp người dùng khám phá phong cách mới và tích điểm thưởng VIP.',
  })
  @ApiResponse({
    status: 200,
    description: 'Danh sách thử thách phối đồ',
  })
  getChallenges() {
    const list = this.gamificationService.getChallenges();
    return {
      success: true,
      code: 200,
      data: list,
      meta: {
        total: list.length,
        timestamp: new Date().toISOString(),
      },
    };
  }
}
