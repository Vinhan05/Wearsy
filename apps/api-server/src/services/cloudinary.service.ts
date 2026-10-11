import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { v2 as cloudinary, UploadApiResponse } from 'cloudinary';
import * as streamifier from 'streamifier';
import { BgRemovalService } from './bg-removal.service';

@Injectable()
export class CloudinaryService {
  private readonly logger = new Logger(CloudinaryService.name);

  constructor(
    private readonly configService: ConfigService,
    private readonly bgRemovalService: BgRemovalService,
  ) {
    cloudinary.config(this.getCredentials());
  }

  private getCredentials() {
    return {
      cloud_name:
        process.env.CLOUDINARY_CLOUD_NAME ||
        this.configService.get<string>('CLOUDINARY_CLOUD_NAME') ||
        'bvxcghig',
      api_key:
        process.env.CLOUDINARY_API_KEY ||
        this.configService.get<string>('CLOUDINARY_API_KEY') ||
        '597682858733949',
      api_secret:
        process.env.CLOUDINARY_API_SECRET ||
        this.configService.get<string>('CLOUDINARY_API_SECRET') ||
        'IPB7h8B-ay6CyBeb9N73cY6Fxs8',
      secure: true,
    };
  }

  private uploadBufferToCloudinary(
    buffer: Buffer,
    folder = 'wearsy/wardrobe_items',
    format?: string,
  ): Promise<UploadApiResponse> {
    const creds = this.getCredentials();
    return new Promise((resolve, reject) => {
      const options: any = { ...creds, folder };
      if (format) options.format = format;

      const uploadStream = cloudinary.uploader.upload_stream(
        options,
        (error, result) => {
          if (error) {
            this.logger.error('Lỗi khi tải ảnh lên Cloudinary:', error);
            return reject(error);
          }
          resolve(result as UploadApiResponse);
        },
      );

      streamifier.createReadStream(buffer).pipe(uploadStream);
    });
  }

  /**
   * Upload ảnh lên Cloudinary kèm tính năng tách nền AI Miễn phí 100% vĩnh viễn (Node.js AI)
   * và lưu trữ dưới dạng PNG trong suốt.
   */
  async uploadImageWithBgRemoval(
    file: Express.Multer.File,
  ): Promise<UploadApiResponse> {
    try {
      this.logger.log('Đang chạy tách nền AI (Free 100%) cho file ảnh...');
      const pngBuffer = await this.bgRemovalService.removeBackground(
        file.buffer,
      );
      return await this.uploadBufferToCloudinary(
        pngBuffer,
        'wearsy/wardrobe_items',
        'png',
      );
    } catch (bgError) {
      this.logger.warn(
        `Tách nền AI thất bại (${bgError.message}). Fallback sử dụng ảnh gốc tải lên Cloudinary.`,
      );
      return await this.uploadBufferToCloudinary(
        file.buffer,
        'wearsy/wardrobe_items',
      );
    }
  }

  /**
   * Upload ảnh thông thường (không tách nền)
   */
  async uploadImage(
    file: Express.Multer.File,
    folder = 'wearsy/general',
  ): Promise<UploadApiResponse> {
    return await this.uploadBufferToCloudinary(file.buffer, folder);
  }

  /**
   * Upload ảnh từ một URL từ xa (Shopee, web...) lên Cloudinary kèm tính năng tách nền AI
   */
  async uploadUrlWithBgRemoval(imageUrl: string): Promise<UploadApiResponse> {
    const creds = this.getCredentials();
    try {
      this.logger.log(`Đang chạy tách nền AI (Free 100%) cho URL: ${imageUrl}`);
      const pngBuffer = await this.bgRemovalService.removeBackground(imageUrl);
      return await this.uploadBufferToCloudinary(
        pngBuffer,
        'wearsy/wardrobe_items',
        'png',
      );
    } catch (bgError) {
      this.logger.warn(
        `Tách nền AI từ URL thất bại (${bgError.message}). Fallback tải trực tiếp URL gốc lên Cloudinary.`,
      );
      return await cloudinary.uploader.upload(imageUrl, {
        ...creds,
        folder: 'wearsy/wardrobe_items',
      });
    }
  }
}
