import { Injectable, Logger } from '@nestjs/common';
import { v2 as cloudinary, UploadApiResponse } from 'cloudinary';
import * as streamifier from 'streamifier';

@Injectable()
export class CloudinaryService {
  private readonly logger = new Logger(CloudinaryService.name);

  /**
   * Upload ảnh lên Cloudinary kèm tính năng tách nền AI (background_removal)
   * và chuyển đổi sang định dạng PNG trong suốt.
   */
  async uploadImageWithBgRemoval(file: Express.Multer.File): Promise<UploadApiResponse> {
    return new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        {
          folder: 'wearsy/wardrobe_items',
          background_removal: 'cloudinary_ai',
          format: 'png',
        },
        (error, result) => {
          if (error) {
            this.logger.error('Lỗi khi tải ảnh và tách nền trên Cloudinary:', error);
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
  async uploadImage(file: Express.Multer.File, folder = 'wearsy/general'): Promise<UploadApiResponse> {
    return new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        { folder },
        (error, result) => {
          if (error) {
            this.logger.error('Lỗi tải ảnh thông thường lên Cloudinary:', error);
            return reject(error);
          }
          resolve(result as UploadApiResponse);
        },
      );

      streamifier.createReadStream(file.buffer).pipe(uploadStream);
    });
  }
}
