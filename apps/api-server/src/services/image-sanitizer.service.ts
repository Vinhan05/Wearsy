import { Injectable, Logger } from '@nestjs/common';
import * as sharpModule from 'sharp';
const sharp = ((sharpModule as any).default ||
  sharpModule) as typeof sharpModule;

export interface SanitizeResult {
  buffer: Buffer;
  wasSanitized: boolean;
  hadExif: boolean;
  hadGps: boolean;
  format?: string;
  width?: number;
  height?: number;
}

@Injectable()
export class ImageSanitizerService {
  private readonly logger = new Logger(ImageSanitizerService.name);

  /**
   * Kiểm tra thông tin siêu dữ liệu của ảnh (EXIF, GPS, thiết bị, ...)
   */
  async inspectMetadata(buffer: Buffer): Promise<{
    hasExif: boolean;
    hasGps: boolean;
    hasIptc: boolean;
    hasXmp: boolean;
    format?: string;
    width?: number;
    height?: number;
  }> {
    try {
      const metadata = await sharp(buffer).metadata();
      const hasExif = !!metadata.exif;
      let hasGps = false;

      if (metadata.exif) {
        // Kiểm tra xem trong buffer EXIF có chứa thẻ GPS (tag 0x8825 trong TIFF IFD little/big endian) hoặc chuỗi GPS
        const hex = metadata.exif.toString('hex');
        const str = metadata.exif.toString('binary');
        hasGps =
          hex.includes('2588') || hex.includes('8825') || str.includes('GPS');
      }

      return {
        hasExif,
        hasGps,
        hasIptc: !!metadata.iptc,
        hasXmp: !!metadata.xmp,
        format: metadata.format,
        width: metadata.width,
        height: metadata.height,
      };
    } catch (error) {
      this.logger.warn(`Không thể đọc metadata của ảnh: ${error.message}`);
      return {
        hasExif: false,
        hasGps: false,
        hasIptc: false,
        hasXmp: false,
      };
    }
  }

  /**
   * Tự động loại bỏ 100% siêu dữ liệu nhạy cảm (EXIF, GPS, Model thiết bị, Ngày giờ chụp)
   * Tuân thủ quy định Nghị định 13/2023/NĐ-CP và GDPR.
   * Đồng thời tự động xoay ảnh theo đúng chiều thực tế (Orientation) trước khi loại bỏ tag.
   */
  async sanitize(buffer: Buffer): Promise<SanitizeResult> {
    try {
      const inspect = await this.inspectMetadata(buffer);

      if (
        inspect.hasExif ||
        inspect.hasGps ||
        inspect.hasIptc ||
        inspect.hasXmp
      ) {
        this.logger.log(
          `[NĐ13/GDPR Compliance] Phát hiện siêu dữ liệu nhạy cảm (EXIF: ${inspect.hasExif}, GPS: ${inspect.hasGps}). Đang tiến hành cắt bỏ toàn bộ metadata...`,
        );
      }

      // sharp().rotate() tự động xoay ảnh đúng chiều dựa trên EXIF orientation
      // và mặc định DROP toàn bộ EXIF, GPS, IPTC, XMP metadata khi ghi ra buffer mới.
      const sanitizedBuffer = await sharp(buffer).rotate().toBuffer();

      return {
        buffer: sanitizedBuffer,
        wasSanitized: true,
        hadExif: inspect.hasExif,
        hadGps: inspect.hasGps,
        format: inspect.format,
        width: inspect.width,
        height: inspect.height,
      };
    } catch (error) {
      this.logger.error(
        `Lỗi trong quá trình cắt bỏ EXIF metadata: ${error.message}. Giữ nguyên buffer.`,
      );
      return {
        buffer,
        wasSanitized: false,
        hadExif: false,
        hadGps: false,
      };
    }
  }

  /**
   * Tiện ích lấy trực tiếp buffer sạch sau khi đã strip metadata
   */
  async stripMetadata(buffer: Buffer): Promise<Buffer> {
    const result = await this.sanitize(buffer);
    return result.buffer;
  }
}
