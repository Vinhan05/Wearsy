import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class BgRemovalService {
  private readonly logger = new Logger(BgRemovalService.name);

  /**
   * Tách nền AI trực tiếp từ Image Buffer hoặc URL hình ảnh
   * Trả về PNG Buffer trong suốt
   */
  async removeBackground(input: Buffer | string): Promise<Buffer> {
    try {
      this.logger.log('Đang xử lý tách nền AI bằng mô hình @imgly/background-removal-node...');
      
      // Dynamic import để tránh lỗi khi khởi động
      const { removeBackground } = await import('@imgly/background-removal-node');
      
      let source: any = input;
      if (Buffer.isBuffer(input)) {
        source = new Blob([new Uint8Array(input)]);
      }

      const blob = await removeBackground(source);
      const arrayBuffer = await blob.arrayBuffer();
      const resultBuffer = Buffer.from(arrayBuffer);
      
      this.logger.log(
        `Tách nền AI thành công! Kích thước PNG trong suốt: ${resultBuffer.length} bytes`,
      );
      return resultBuffer;
    } catch (error) {
      this.logger.error('Lỗi khi thực hiện tách nền AI:', error);
      throw error;
    }
  }
}
