import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { v2 as cloudinary, UploadApiResponse } from 'cloudinary';
import * as streamifier from 'streamifier';
import axios from 'axios';
import { BgRemovalService } from './bg-removal.service';
import { ImageSanitizerService } from './image-sanitizer.service';

@Injectable()
export class CloudinaryService {
  private readonly logger = new Logger(CloudinaryService.name);

  constructor(
    private readonly configService: ConfigService,
    private readonly bgRemovalService: BgRemovalService,
    private readonly imageSanitizerService: ImageSanitizerService,
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

  private async uploadBufferToCloudinary(
    buffer: Buffer,
    folder = 'wearsy/wardrobe_items',
    format?: string,
  ): Promise<UploadApiResponse> {
    const creds = this.getCredentials();

    // 1. EXIF Metadata Stripping: Tự động loại bỏ toàn bộ tọa độ GPS, model thiết bị, ngày giờ chụp
    // Tuân thủ nghiêm ngặt Nghị định 13/2023/NĐ-CP và tiêu chuẩn GDPR
    const cleanBuffer = await this.imageSanitizerService.stripMetadata(buffer);

    return new Promise((resolve, reject) => {
      const options: any = {
        ...creds,
        folder,
        image_metadata: false, // Lớp bảo vệ bổ sung phía Cloudinary uploader
        exif: false,
      };
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

      streamifier.createReadStream(cleanBuffer).pipe(uploadStream);
    });
  }

  /**
   * Upload ảnh lên Cloudinary kèm tính năng tách nền AI Miễn phí 100% vĩnh viễn (Node.js AI)
   * và lưu trữ dưới dạng PNG trong suốt.
   * Toàn bộ siêu dữ liệu EXIF/GPS đều được cắt bỏ sạch trước khi tách nền hoặc lưu trữ.
   */
  async uploadImageWithBgRemoval(
    file: Express.Multer.File,
  ): Promise<UploadApiResponse> {
    // Tiền xử lý làm sạch EXIF/GPS cho file gốc ngay từ cổng nhận
    const sanitizedOriginal = await this.imageSanitizerService.stripMetadata(
      file.buffer,
    );

    try {
      this.logger.log(
        'Đang chạy tách nền AI (Free 100%) cho file ảnh đã strip EXIF...',
      );
      const pngBuffer =
        await this.bgRemovalService.removeBackground(sanitizedOriginal);
      return await this.uploadBufferToCloudinary(
        pngBuffer,
        'wearsy/wardrobe_items',
        'png',
      );
    } catch (bgError) {
      this.logger.warn(
        `Tách nền AI thất bại (${bgError.message}). Fallback sử dụng ảnh gốc (đã làm sạch EXIF/GPS) tải lên Cloudinary.`,
      );
      return await this.uploadBufferToCloudinary(
        sanitizedOriginal,
        'wearsy/wardrobe_items',
      );
    }
  }

  /**
   * Upload ảnh thông thường (không tách nền, ví dụ quét ảnh tủ đồ)
   * Vẫn đảm bảo 100% cắt bỏ EXIF/GPS trước khi lưu trữ đám mây.
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
        `Tách nền AI từ URL thất bại (${bgError.message}). Đang tải ảnh về để làm sạch EXIF/GPS trước khi upload.`,
      );
      try {
        const response = await axios.get(imageUrl, {
          responseType: 'arraybuffer',
          timeout: 10000,
        });
        const urlBuffer = Buffer.from(response.data);
        return await this.uploadBufferToCloudinary(
          urlBuffer,
          'wearsy/wardrobe_items',
        );
      } catch (fetchError) {
        this.logger.warn(
          `Không thể tải URL trực tiếp (${fetchError.message}). Upload qua Cloudinary với cờ tắt metadata.`,
        );
        return await cloudinary.uploader.upload(imageUrl, {
          ...creds,
          folder: 'wearsy/wardrobe_items',
          image_metadata: false,
          exif: false,
        });
      }
    }
  }

  /**
   * EXIF Metadata Stripping: Tự động cắt bỏ toàn bộ thông tin nhạy cảm
   * (tọa độ GPS, model thiết bị, thời gian chụp) trước khi lưu trữ,
   * tuân thủ Nghị định 13/2023/NĐ-CP và tiêu chuẩn GDPR.
   */
  async stripExifMetadata(
    fileOrBuffer: Express.Multer.File | Buffer,
  ): Promise<Buffer> {
    const buffer = Buffer.isBuffer(fileOrBuffer)
      ? fileOrBuffer
      : fileOrBuffer.buffer;
    return await this.imageSanitizerService.stripMetadata(buffer);
  }
}
