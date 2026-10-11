import {
  Controller,
  Post,
  Get,
  Patch,
  Delete,
  Body,
  Param,
  Headers,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import {
  AiOutfitService,
  WardrobeItemDto,
  UserBodySummaryDto,
} from '../services/ai-outfit.service';
import {
  OutfitsService,
  RecommendOutfitRequestDto,
} from '../services/outfits.service';

export class RecommendOutfitDto {
  contextPrompt: string;
  wardrobeItems: WardrobeItemDto[];
  bodySummary?: UserBodySummaryDto;
}

@ApiTags('Outfits & AI Stylist')
@Controller('outfits')
export class OutfitsController {
  constructor(
    private readonly aiOutfitService: AiOutfitService,
    private readonly outfitsService: OutfitsService,
  ) {}

  @Post('ai-recommend')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Nhận tư vấn phối đồ từ WEARSY AI (Gemma 4 Multimodal + ComfyUI Try-on)',
  })
  @ApiResponse({
    status: 200,
    description: 'Gợi ý phối đồ và ảnh render thành công',
  })
  async recommendOutfit(
    @Body() dto: RecommendOutfitRequestDto,
    @Headers('x-user-id') headerUserId?: string,
  ) {
    const userId = headerUserId || (dto as any).user_id || '';
    return this.outfitsService.recommendAndCreateOutfit(userId, dto);
  }

  @Get()
  @ApiOperation({ summary: 'Lấy toàn bộ danh sách outfit của người dùng' })
  async getOutfits(@Headers('x-user-id') headerUserId?: string) {
    const userId = headerUserId || '';
    return this.outfitsService.getOutfitsByUser(userId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Xem chi tiết outfit' })
  async getOutfitDetail(
    @Param('id') id: string,
    @Headers('x-user-id') headerUserId?: string,
  ) {
    const userId = headerUserId || '';
    return this.outfitsService.getOutfitById(id, userId);
  }

  @Patch(':id/favorite')
  @ApiOperation({ summary: 'Đổi trạng thái yêu thích outfit' })
  async toggleFavorite(
    @Param('id') id: string,
    @Headers('x-user-id') headerUserId?: string,
  ) {
    const userId = headerUserId || '';
    return this.outfitsService.toggleFavorite(id, userId);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Xóa outfit khỏi tủ đồ' })
  async deleteOutfit(
    @Param('id') id: string,
    @Headers('x-user-id') headerUserId?: string,
  ) {
    const userId = headerUserId || '';
    return this.outfitsService.deleteOutfit(id, userId);
  }

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
