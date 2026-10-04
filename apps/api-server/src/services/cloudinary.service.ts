import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { v2 as cloudinary, UploadApiResponse } from 'cloudinary';
import * as streamifier from 'streamifier';

@Injectable()
export class CloudinaryService {
  private readonly logger = new Logger(CloudinaryService.name);

  constructor(private readonly configService: ConfigService) {
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

  /**
   * Upload ảnh lên Cloudinary kèm tính năng tách nền AI (background_removal)
   * và chuyển đổi sang định dạng PNG trong suốt.
   */
  async uploadImageWithBgRemoval(
    file: Express.Multer.File,
  ): Promise<UploadApiResponse> {
    const creds = this.getCredentials();
    return new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        {
          ...creds,
          folder: 'wearsy/wardrobe_items',
          background_removal: 'cloudinary_ai',
          format: 'png',
        },
        (error, result) => {
          if (error) {
            this.logger.error(
              'Lỗi khi tải ảnh và tách nền trên Cloudinary:',
              error,
            );
            return reject(error);
          }
          resolve(result as UploadApiResponse);
        },
      );

      streamifier.createReadStream(file.buffer).pipe(uploadStream);
    });
  }

  /**
   * Upload ảnh thông thường (không tách nền)
   */
  async uploadImage(
    file: Express.Multer.File,
    folder = 'wearsy/general',
  ): Promise<UploadApiResponse> {
    const creds = this.getCredentials();
    return new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        { ...creds, folder },
        (error, result) => {
          if (error) {
            this.logger.error(
              'Lỗi tải ảnh thông thường lên Cloudinary:',
              error,
            );
            return reject(error);
          }
          resolve(result as UploadApiResponse);
        },
      );

      streamifier.createReadStream(file.buffer).pipe(uploadStream);
    });
  }

  /**
   * Upload ảnh từ một URL từ xa (Shopee, web...) lên Cloudinary kèm tính năng tách nền AI
   */
  async uploadUrlWithBgRemoval(imageUrl: string): Promise<UploadApiResponse> {
    const creds = this.getCredentials();
    try {
      const result = await cloudinary.uploader.upload(imageUrl, {
        ...creds,
        folder: 'wearsy/wardrobe_items',
        background_removal: 'cloudinary_ai',
        format: 'png',
      });
      return result;
    } catch (error) {
      this.logger.error('Lỗi khi tách nền ảnh từ URL trên Cloudinary:', error);
      throw error;
    }
  }
}
