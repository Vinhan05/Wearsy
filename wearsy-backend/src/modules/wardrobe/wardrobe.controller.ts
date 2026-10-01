import {
  Controller,
  Post,
  Body,
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
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import { WardrobeScannerService } from './services/wardrobe-scanner.service';
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
}
