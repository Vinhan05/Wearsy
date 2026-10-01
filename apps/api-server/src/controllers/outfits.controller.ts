import { Controller, Post, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import {
  AiOutfitService,
  WardrobeItemDto,
  UserBodySummaryDto,
} from '../services/ai-outfit.service';

export class RecommendOutfitDto {
  contextPrompt: string;
  wardrobeItems: WardrobeItemDto[];
  bodySummary?: UserBodySummaryDto;
}

@ApiTags('AI Outfits')
@Controller('outfits')
export class OutfitsController {
  constructor(private readonly aiOutfitService: AiOutfitService) {}

  @Post('recommend')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Gợi ý outfit kết hợp Layering Canvas 2D và Smart Fit AI',
  })
  @ApiResponse({ status: 200, description: 'Gợi ý outfit thành công' })
  async recommendOutfits(@Body() body: RecommendOutfitDto) {
    const outfits = await this.aiOutfitService.generateOutfitRecommendations(
      body.contextPrompt || 'Đi làm văn phòng thanh lịch',
      body.wardrobeItems || [],
      body.bodySummary,
    );
    return {
      success: true,
      data: outfits,
    };
  }

  @Post('recommend-by-context')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Gợi ý outfit nâng cao theo ngữ cảnh thời tiết, địa điểm',
  })
  @ApiResponse({ status: 200, description: 'Gợi ý outfit thành công' })
  async recommendByContext(@Body() body: RecommendOutfitDto) {
    return this.recommendOutfits(body);
  }
}
