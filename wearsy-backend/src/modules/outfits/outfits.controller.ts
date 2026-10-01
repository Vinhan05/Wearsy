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
import { OutfitsService, RecommendOutfitRequestDto } from './services/outfits.service';

@ApiTags('Outfits & AI Stylist')
@Controller('outfits')
export class OutfitsController {
  constructor(private readonly outfitsService: OutfitsService) {}

  @Post('ai-recommend')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Nhận tư vấn phối đồ từ WEARSY AI (Gemma 4 Multimodal + ComfyUI Try-on)',
  })
  @ApiResponse({ status: 200, description: 'Gợi ý phối đồ và ảnh render thành công' })
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
}
