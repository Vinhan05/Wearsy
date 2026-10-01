import {
  Controller,
  Post,
  Get,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UploadedFile,
  UseInterceptors,
  BadRequestException,
  HttpCode,
  HttpStatus,
  Headers,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiOperation,
  ApiConsumes,
  ApiBody,
  ApiResponse,
} from '@nestjs/swagger';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import { WardrobeScannerService } from './services/wardrobe-scanner.service';
import { WardrobeItemEntity } from './entities/wardrobe-item.entity';
import { UserEntity } from '../users/entities/user.entity';
import {
  ScanBulkBodyDto,
  ScanBulkResponseDto,
  BulkCommitDto,
} from './dto/scan-bulk.dto';

@ApiTags('Wardrobe & Computer Vision')
@Controller('wardrobe')
export class WardrobeController {
  constructor(
    private readonly cloudinaryService: CloudinaryService,
    private readonly wardrobeScannerService: WardrobeScannerService,
    @InjectRepository(WardrobeItemEntity)
    private readonly itemRepo: Repository<WardrobeItemEntity>,
    @InjectRepository(UserEntity)
    private readonly userRepo: Repository<UserEntity>,
  ) {}

  @Post('upload')
  @ApiOperation({
    summary: 'Tải ảnh trang phục và tự động tách nền AI qua Cloudinary',
  })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        image: {
          type: 'string',
          format: 'binary',
          description: 'Tệp hình ảnh trang phục (JPG, PNG, WEBP)',
        },
      },
    },
  })
  @UseInterceptors(FileInterceptor('image'))
  async uploadItemImage(@UploadedFile() file: Express.Multer.File) {
    if (!file) {
      throw new BadRequestException(
        'Vui lòng chọn hoặc tải lên tệp hình ảnh hợp lệ.',
      );
    }

    // Gọi Cloudinary Service xử lý upload và tách nền AI
    const result = await this.cloudinaryService.uploadImageWithBgRemoval(file);

    return {
      success: true,
      message: 'Tải ảnh và tách nền thành công!',
      raw_image_url: result.secure_url,
      bg_removed_url: result.secure_url, // Định dạng PNG trong suốt đã xóa phông nền
      public_id: result.public_id,
      format: result.format,
      width: result.width,
      height: result.height,
    };
  }

  @Post('analyze-image')
  @ApiOperation({ summary: 'Phân tích và tách nền ảnh cho tủ đồ' })
  @UseInterceptors(FileInterceptor('image'))
  async analyzeItemImage(@UploadedFile() file: Express.Multer.File) {
    return this.uploadItemImage(file);
  }

  /**
   * Quét và đếm toàn bộ trang phục trong 1 bức ảnh chụp tủ đồ / sào đồ bằng Gemini Vision
   */
  @Post('scan-bulk')
  @ApiOperation({
    summary:
      'Quét toàn cảnh tủ đồ bằng Gemini Vision: đếm số lượng áo thun, sơ mi, quần jeans, áo khoác...',
    description:
      'Nhận 1 bức ảnh chụp toàn cảnh tủ đồ/sào đồ, sử dụng Gemini Multimodal để định vị khung 2D, phân loại danh mục, màu sắc và thống kê số lượng.',
  })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      required: ['image'],
      properties: {
        image: {
          type: 'string',
          format: 'binary',
          description: 'Ảnh chụp toàn cảnh tủ đồ hoặc sào quần áo',
        },
        userId: {
          type: 'string',
          format: 'uuid',
          description: 'UUID của người dùng (tùy chọn)',
        },
        saveToCloset: {
          type: 'boolean',
          description: 'Tự động lưu các món tìm thấy vào tủ đồ ngay lập tức',
          default: false,
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Quét và nhận diện thành công',
    type: ScanBulkResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Tệp tải lên không hợp lệ' })
  @UseInterceptors(FileInterceptor('image'))
  async scanWardrobeBulk(
    @UploadedFile() file: Express.Multer.File,
    @Body() body: ScanBulkBodyDto,
  ): Promise<ScanBulkResponseDto> {
    return this.wardrobeScannerService.scanWardrobeImage(file, {
      userId: body.userId,
      saveToCloset: body.saveToCloset,
    });
  }

  /**
   * Xác nhận và lưu hàng loạt các món đồ người dùng đã kiểm tra vào tủ đồ kỹ thuật số
   */
  @Post('bulk-commit')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Xác nhận thêm hàng loạt trang phục vào tủ đồ cá nhân (sau khi xem kết quả quét)',
  })
  @ApiResponse({
    status: 200,
    description: 'Lưu hàng loạt trang phục vào tủ đồ thành công',
  })
  async commitBulkItems(@Body() body: BulkCommitDto) {
    return this.wardrobeScannerService.commitBulkItems(body);
  }

  // ─── Digital Wardrobe Items CRUD (Lưu trữ Database Máy chủ) ────────────────

  @Get('items')
  @ApiOperation({ summary: 'Lấy toàn bộ trang phục trong tủ đồ từ PostgreSQL Database' })
  async getItems(
    @Query('email') email?: string,
    @Query('user_id') userId?: string,
  ) {
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

  @Post('items')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Lưu món đồ mới vào PostgreSQL Database của Server' })
  async createItem(@Body() body: any) {
    const targetUserId = await this.getOrCreateUserId(body.email || body.user_email, body.user_id);
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

  @Put('items/:id')
  @ApiOperation({ summary: 'Cập nhật thông tin món đồ trên Database' })
  async updateItem(@Param('id') id: string, @Body() body: any) {
    const item = await this.itemRepo.findOne({ where: { id } });
    if (!item) {
      throw new BadRequestException('Không tìm thấy món đồ cần cập nhật');
    }

    if (body.name) item.name = body.name.trim();
    if (body.category) item.category_id = this.mapCategoryCodeToId(body.category);
    if (body.color) item.primary_color = body.color;
    if (body.brand !== undefined) item.brand = body.brand;
    if (body.image_url) item.image_url = body.image_url;
    if (body.tags) item.style_tags = body.tags;
    if (body.wardrobe_id) item.wardrobe_id = body.wardrobe_id;
    if (body.layer_order !== undefined) item.layer_order = Number(body.layer_order);

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

  @Delete('items/:id')
  @ApiOperation({ summary: 'Xóa món đồ khỏi Database' })
  async deleteItem(@Param('id') id: string) {
    const item = await this.itemRepo.findOne({ where: { id } });
    if (item) {
      item.status = 'DELETED';
      await this.itemRepo.save(item);
    }
    return { success: true, message: 'Đã xóa món đồ thành công' };
  }

  @Delete('items')
  @ApiOperation({ summary: 'Xóa toàn bộ trang phục của người dùng (Reset Tủ đồ trắng)' })
  async clearAllItems(
    @Query('email') email?: string,
    @Query('user_id') userId?: string,
  ) {
    const targetUserId = await this.getOrCreateUserId(email, userId);
    await this.itemRepo.update(
      { user_id: targetUserId, status: 'ACTIVE' },
      { status: 'DELETED' },
    );
    return { success: true, message: 'Đã reset toàn bộ tủ đồ về trạng thái trắng trên Server Database' };
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  private async getOrCreateUserId(email?: string, userId?: string): Promise<string> {
    if (userId && userId.length > 10) return userId;
    const cleanEmail = (email || 'demo@wearsy.app').trim().toLowerCase();
    let user = await this.userRepo.findOne({ where: { email: cleanEmail } });
    if (!user) {
      user = this.userRepo.create({
        email: cleanEmail,
        password_hash: 'SSO_AUTO_ACCOUNT',
        full_name: cleanEmail.split('@')[0],
        role: 'USER',
        is_vip: false,
        is_active: true,
      });
      await this.userRepo.save(user);
    }
    return user.id;
  }

  private mapCategoryCodeToId(code?: string): number {
    const c = (code || '').toUpperCase();
    if (c === 'TOPS' || c === 'ÁO') return 1;
    if (c === 'BOTTOMS' || c === 'QUẦN' || c === 'DRESSES' || c === 'ĐẦM/VÁY') return 2;
    if (c === 'SHOES' || c === 'FOOTWEAR' || c === 'GIÀY') return 3;
    if (c === 'OUTERWEAR' || c === 'ÁO KHOÁC') return 4;
    if (c === 'ACCESSORIES' || c === 'PHỤ KIỆN') return 5;
    return 1;
  }

  private mapCategoryIdToCode(id: number): string {
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
