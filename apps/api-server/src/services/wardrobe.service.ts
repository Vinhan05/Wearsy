import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { WardrobeItemEntity } from '../models/wardrobe-item.entity';
import { UserEntity } from '../models/user.entity';

@Injectable()
export class WardrobeService {
  constructor(
    @InjectRepository(WardrobeItemEntity)
    private readonly itemRepo: Repository<WardrobeItemEntity>,
    @InjectRepository(UserEntity)
    private readonly userRepo: Repository<UserEntity>,
  ) {}

  async getItems(email?: string, userId?: string) {
    const targetUserId = await this.getOrCreateUserId(email, userId);
    const items = await this.itemRepo.find({
      where: { user_id: targetUserId, status: 'ACTIVE' },
      order: { created_at: 'DESC' },
    });

    return items.map((item) => ({
      id: item.id,
      name: item.name,
      category: this.mapCategoryIdToCode(item.category_id),
      color: item.primary_color || '',
      brand: item.brand || '',
      image_url: item.image_url || '',
      tags: item.style_tags || [],
      ai_match_score: Number(item.ai_match_score) || 9.0,
      layer_order: item.layer_order || 1,
      wardrobe_id: item.wardrobe_id || 'default',
    }));
  }

  async createItem(body: any) {
    const targetUserId = await this.getOrCreateUserId(
      body.email || body.user_email,
      body.user_id,
    );
    const catId = this.mapCategoryCodeToId(body.category);

    const newItem = this.itemRepo.create({
      user_id: targetUserId,
      category_id: catId,
      name: (body.name || 'Món đồ thời trang').trim(),
      image_url: body.image_url || '',
      primary_color: body.color || 'Chưa xác định',
      brand: body.brand || '',
      style_tags: Array.isArray(body.tags) ? body.tags : [],
      ai_match_score: Number(body.ai_match_score) || 9.0,
      layer_order: Number(body.layer_order) || 1,
      wardrobe_id: body.wardrobe_id || 'default',
      season: body.season || 'ALL',
      ai_processing_status: 'COMPLETED',
      status: 'ACTIVE',
      wear_count: 0,
    });

    const saved = await this.itemRepo.save(newItem);
    return {
      id: saved.id,
      name: saved.name,
      category: this.mapCategoryIdToCode(saved.category_id),
      color: saved.primary_color,
      brand: saved.brand,
      image_url: saved.image_url,
      tags: saved.style_tags,
      ai_match_score: Number(saved.ai_match_score),
      layer_order: saved.layer_order,
      wardrobe_id: saved.wardrobe_id,
    };
  }

  async updateItem(id: string, body: any) {
    const item = await this.itemRepo.findOne({ where: { id } });
    if (!item) {
      throw new BadRequestException('Không tìm thấy món đồ cần cập nhật');
    }

    if (body.name) item.name = body.name.trim();
    if (body.category)
      item.category_id = this.mapCategoryCodeToId(body.category);
    if (body.color) item.primary_color = body.color;
    if (body.brand !== undefined) item.brand = body.brand;
    if (body.image_url) item.image_url = body.image_url;
    if (body.tags) item.style_tags = body.tags;
    if (body.wardrobe_id) item.wardrobe_id = body.wardrobe_id;
    if (body.layer_order !== undefined)
      item.layer_order = Number(body.layer_order);

    const saved = await this.itemRepo.save(item);
    return {
      id: saved.id,
      name: saved.name,
      category: this.mapCategoryIdToCode(saved.category_id),
      color: saved.primary_color,
      brand: saved.brand,
      image_url: saved.image_url,
      tags: saved.style_tags,
      ai_match_score: Number(saved.ai_match_score),
      layer_order: saved.layer_order,
      wardrobe_id: saved.wardrobe_id,
    };
  }

  async deleteItem(id: string) {
    const item = await this.itemRepo.findOne({ where: { id } });
    if (item) {
      item.status = 'DELETED';
      await this.itemRepo.save(item);
    }
    return { success: true, message: 'Đã xóa món đồ thành công' };
  }

  async clearAllItems(email?: string, userId?: string) {
    const targetUserId = await this.getOrCreateUserId(email, userId);
    await this.itemRepo.update(
      { user_id: targetUserId, status: 'ACTIVE' },
      { status: 'DELETED' },
    );
    return {
      success: true,
      message:
        'Đã reset toàn bộ tủ đồ về trạng thái trắng trên Server Database',
    };
  }

  private async getOrCreateUserId(
    email?: string,
    userId?: string,
  ): Promise<string> {
    if (userId && userId.length > 10) return userId;
    if (!email || !email.trim()) {
      throw new BadRequestException('Email hoặc User ID là bắt buộc!');
    }
    const cleanEmail = email.trim().toLowerCase();
    const user = await this.userRepo.findOne({ where: { email: cleanEmail } });
    if (!user) {
      throw new BadRequestException('Không tìm thấy người dùng với email này!');
    }
    return user.id;
  }

  mapCategoryCodeToId(code?: string): number {
    const c = (code || '').toUpperCase();
    if (c === 'TOPS' || c === 'ÁO') return 1;
    if (c === 'BOTTOMS' || c === 'QUẦN' || c === 'DRESSES' || c === 'ĐẦM/VÁY')
      return 2;
    if (c === 'SHOES' || c === 'FOOTWEAR' || c === 'GIÀY') return 3;
    if (c === 'OUTERWEAR' || c === 'ÁO KHOÁC') return 4;
    if (c === 'ACCESSORIES' || c === 'PHỤ KIỆN') return 5;
    return 1;
  }

  mapCategoryIdToCode(id: number): string {
    switch (id) {
      case 1:
        return 'tops';
      case 2:
        return 'bottoms';
      case 3:
        return 'shoes';
      case 4:
        return 'outerwear';
      case 5:
        return 'accessories';
      default:
        return 'tops';
    }
  }
}
