import {
  Injectable,
  NotFoundException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { OutfitEntity, OutfitItemEntity, WardrobeItemEntity } from '../models';
import { AiOutfitService, UserBodySummaryDto } from './ai-outfit.service';

export interface RecommendOutfitRequestDto {
  occasion: string;
  user_name?: string;
  body_summary?: UserBodySummaryDto;
  wardrobe_items?: any[];
}

@Injectable()
export class OutfitsService {
  private readonly logger = new Logger(OutfitsService.name);

  constructor(
    @InjectRepository(OutfitEntity)
    private readonly outfitRepo: Repository<OutfitEntity>,
    @InjectRepository(OutfitItemEntity)
    private readonly outfitItemRepo: Repository<OutfitItemEntity>,
    @InjectRepository(WardrobeItemEntity)
    private readonly wardrobeItemRepo: Repository<WardrobeItemEntity>,
    private readonly aiOutfitService: AiOutfitService,
  ) {}

  /**
   * Tạo gợi ý outfit thông minh từ AI (Gemma 4 + ComfyUI)
   */
  async recommendAndCreateOutfit(
    userId: string,
    dto: RecommendOutfitRequestDto,
  ) {
    // Lấy đồ trong tủ của người dùng từ database (hoặc từ danh sách gửi lên)
    let itemsToAnalyze: WardrobeItemEntity[] = [];
    if (userId) {
      itemsToAnalyze = await this.wardrobeItemRepo.find({
        where: { user_id: userId, status: 'ACTIVE' },
      });
    }

    // Nếu gửi kèm danh sách đồ từ client (cho mục đích test/demo)
    if ((!itemsToAnalyze || itemsToAnalyze.length === 0) && dto.wardrobe_items && dto.wardrobe_items.length > 0) {
      itemsToAnalyze = dto.wardrobe_items as any[];
    }

    // Format danh sách đồ
    const wardrobeDtoList = itemsToAnalyze.map((item) => ({
      id: item.id,
      name: item.name,
      category_name: (item as any).category_name || (item as any).category || '',
      primary_color: item.primary_color || 'Đa sắc',
      style_tags: item.style_tags || [],
      image_url: item.image_url,
      bg_removed_url: item.bg_removed_url,
      layer_order: item.layer_order || 1,
    }));

    // Gọi AI Engine
    const recommendations = await this.aiOutfitService.generateOutfitRecommendations(
      dto.occasion,
      wardrobeDtoList,
      dto.body_summary,
      dto.user_name || 'Bạn',
    );

    if (!recommendations || recommendations.length === 0) {
      throw new NotFoundException('Không tìm thấy gợi ý outfit phù hợp.');
    }

    const rec = recommendations[0];

    // Lưu vào database nếu có userId
    let savedOutfit: OutfitEntity | null = null;
    if (userId) {
      const newOutfit = this.outfitRepo.create({
        user_id: userId,
        title: rec.title,
        occasion: dto.occasion,
        ai_generated: true,
        elegance_score: rec.elegance_score,
        ai_reasoning: rec.stylist_reasoning,
        image_url: rec.image_url || undefined,
        is_favorite: false,
      });
      savedOutfit = await this.outfitRepo.save(newOutfit);

      // Lưu các items trong outfit
      if (rec.selected_item_ids && rec.selected_item_ids.length > 0) {
        const outfitItems = rec.selected_item_ids.map((itemId, idx) =>
          this.outfitItemRepo.create({
            outfit_id: savedOutfit!.id,
            item_id: itemId,
            layer_order: idx + 1,
          }),
        );
        await this.outfitItemRepo.save(outfitItems);
      }
    }

    return {
      success: true,
      outfit_id: savedOutfit ? savedOutfit.id : rec.outfit_id,
      title: rec.title,
      occasion: dto.occasion,
      elegance_score: rec.elegance_score,
      color_score: rec.color_score,
      stylist_reasoning: rec.stylist_reasoning,
      selected_item_ids: rec.selected_item_ids,
      image_url: rec.image_url,
      image_base64: rec.image_base64,
      is_ai_rendered: rec.is_ai_rendered,
      smart_fit_advice: rec.smart_fit_advice,
    };
  }

  /**
   * Lấy danh sách outfits của người dùng
   */
  async getOutfitsByUser(userId: string) {
    return this.outfitRepo.find({
      where: { user_id: userId },
      relations: ['items', 'items.item'],
      order: { created_at: 'DESC' },
    });
  }

  /**
   * Lấy chi tiết 1 outfit
   */
  async getOutfitById(id: string, userId: string) {
    const outfit = await this.outfitRepo.findOne({
      where: { id, user_id: userId },
      relations: ['items', 'items.item'],
    });
    if (!outfit) {
      throw new NotFoundException('Outfit không tồn tại.');
    }
    return outfit;
  }

  /**
   * Đổi trạng thái yêu thích
   */
  async toggleFavorite(id: string, userId: string) {
    const outfit = await this.getOutfitById(id, userId);
    outfit.is_favorite = !outfit.is_favorite;
    return this.outfitRepo.save(outfit);
  }

  /**
   * Xóa outfit
   */
  async deleteOutfit(id: string, userId: string) {
    const outfit = await this.getOutfitById(id, userId);
    await this.outfitRepo.remove(outfit);
    return { success: true, message: 'Đã xóa outfit thành công.' };
  }
}
