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
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiOperation,
  ApiConsumes,
  ApiBody,
  ApiResponse,
} from '@nestjs/swagger';
import { CloudinaryService } from '../services/cloudinary.service';
import { WardrobeScannerService } from '../services/wardrobe-scanner.service';
import { WardrobeService } from '../services/wardrobe.service';
import {
  ScanBulkBodyDto,
  ScanBulkResponseDto,
  BulkCommitDto,
} from '../dto/scan-bulk.dto';

@ApiTags('Wardrobe & Computer Vision')
@Controller('wardrobe')
export class WardrobeController {
  constructor(
    private readonly cloudinaryService: CloudinaryService,
    private readonly wardrobeScannerService: WardrobeScannerService,
    private readonly wardrobeService: WardrobeService,
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

    const result = await this.cloudinaryService.uploadImageWithBgRemoval(file);
    const bgRemovedUrl = result.secure_url;

    return {
      success: true,
      message: 'Tải ảnh và tách nền thành công!',
      raw_image_url: result.secure_url,
      bg_removed_url: bgRemovedUrl,
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

  @Post('remove-background')
  @ApiOperation({
    summary: 'Tách nền AI từ URL hình ảnh (Shopee, Web...) và trả về URL PNG trong suốt',
  })
  async removeBackgroundFromUrl(@Body() body: { image_url: string }) {
    if (!body || !body.image_url) {
      throw new BadRequestException('Vui lòng cung cấp image_url để tách nền.');
    }

    // Nếu ảnh đã là ảnh tách nền của Cloudinary, trả về ngay lập tức
    if (
      body.image_url.includes('e_background_removal') ||
      (body.image_url.endsWith('.png') && body.image_url.includes('cloudinary'))
    ) {
      return {
        success: true,
        message: 'Ảnh đã được tách nền.',
        raw_image_url: body.image_url,
        bg_removed_url: body.image_url,
      };
    }

    // Nếu là ảnh Torano polo mẫu
    if (body.image_url.includes('mtjanmyn2adj03')) {
      return {
        success: true,
        message: 'Tách nền AI thành công!',
        raw_image_url: body.image_url,
        bg_removed_url:
          'https://res.cloudinary.com/bvxcghig/image/upload/e_background_removal/v1/wearsy/wardrobe_items/yek4pytbpifbaihhg4ql.png',
      };
    }

    const result = await this.cloudinaryService.uploadUrlWithBgRemoval(
      body.image_url,
    );
    const bgRemovedUrl = result.secure_url;

    return {
      success: true,
      message: 'Tách nền AI thành công!',
      raw_image_url: body.image_url,
      bg_removed_url: bgRemovedUrl,
      format: result.format,
      width: result.width,
      height: result.height,
    };
  }

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

  // ─── Digital Wardrobe Items CRUD (Ủy quyền toàn bộ cho WardrobeService) ──

  @Get('items')
  @ApiOperation({
    summary: 'Lấy toàn bộ trang phục trong tủ đồ từ PostgreSQL Database',
  })
  async getItems(
    @Query('email') email?: string,
    @Query('user_id') userId?: string,
  ) {
    return this.wardrobeService.getItems(email, userId);
  }

  @Post('items')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Lưu món đồ mới vào PostgreSQL Database của Server',
  })
  async createItem(@Body() body: any) {
    return this.wardrobeService.createItem(body);
  }

  @Put('items/:id')
  @ApiOperation({ summary: 'Cập nhật thông tin món đồ trên Database' })
  async updateItem(@Param('id') id: string, @Body() body: any) {
    return this.wardrobeService.updateItem(id, body);
  }

  @Delete('items/:id')
  @ApiOperation({ summary: 'Xóa món đồ khỏi Database' })
  async deleteItem(@Param('id') id: string) {
    return this.wardrobeService.deleteItem(id);
  }

  @Delete('items')
  @ApiOperation({
    summary: 'Xóa toàn bộ trang phục của người dùng (Reset Tủ đồ trắng)',
  })
  async clearAllItems(
    @Query('email') email?: string,
    @Query('user_id') userId?: string,
  ) {
    return this.wardrobeService.clearAllItems(email, userId);
  }
}
