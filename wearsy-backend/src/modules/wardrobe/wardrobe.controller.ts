import {
  Controller,
  Post,
  UploadedFile,
  UseInterceptors,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiTags, ApiOperation, ApiConsumes, ApiBody } from '@nestjs/swagger';
import { CloudinaryService } from '../cloudinary/cloudinary.service';

@ApiTags('Wardrobe & Computer Vision')
@Controller('wardrobe')
export class WardrobeController {
  constructor(private readonly cloudinaryService: CloudinaryService) {}

  @Post('upload')
  @ApiOperation({ summary: 'Tải ảnh trang phục và tự động tách nền AI qua Cloudinary' })
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
      throw new BadRequestException('Vui lòng chọn hoặc tải lên tệp hình ảnh hợp lệ.');
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
}
