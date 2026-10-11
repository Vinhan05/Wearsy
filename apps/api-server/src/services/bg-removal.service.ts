import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';

@Injectable()
export class BgRemovalService {
  private readonly logger = new Logger(BgRemovalService.name);
  private aiOrchestratorUrl: string;

  constructor(private readonly configService: ConfigService) {
    this.aiOrchestratorUrl = this.configService.get<string>(
      'AI_ORCHESTRATOR_URL',
      process.env.AI_ORCHESTRATOR_URL || 'http://127.0.0.1:8000',
    );
  }

  /**
   * Tách nền AI trực tiếp từ Image Buffer hoặc URL hình ảnh
   * Trả về PNG Buffer trong suốt
   */
  async removeBackground(input: Buffer | string): Promise<Buffer> {
    // 1. Ưu tiên gọi Wearsy AI Orchestrator (rembg U2Net Deep Learning trên GPU)
    try {
      this.logger.log(
        `Đang gửi yêu cầu tách nền AI tới Wearsy Orchestrator: ${this.aiOrchestratorUrl}/api/v1/wardrobe/remove-bg...`,
      );

      const payload: any = {};
      if (Buffer.isBuffer(input)) {
        payload.image_base64 = `data:image/png;base64,${input.toString('base64')}`;
      } else {
        payload.image_url = input;
      }

      const response = await axios.post(
        `${this.aiOrchestratorUrl}/api/v1/wardrobe/remove-bg`,
        payload,
        { timeout: 35000 },
      );

      if (response.data && response.data.image_base64) {
        const rawB64 = response.data.image_base64.split('base64,').pop();
        const resultBuffer = Buffer.from(rawB64, 'base64');
        this.logger.log(
          `Tách nền AI thành công qua Wearsy Engine! Kích thước PNG trong suốt: ${resultBuffer.length} bytes`,
        );
        return resultBuffer;
      }
    } catch (orchError) {
      this.logger.warn(
        `Không thể kết nối AI Orchestrator để tách nền (${orchError.message}). Đang thử fallback...`,
      );
    }

    // 2. Fallback: sử dụng @imgly/background-removal-node nếu có
    try {
      this.logger.log(
        'Đang xử lý tách nền fallback bằng mô hình @imgly/background-removal-node...',
      );

      const { removeBackground } = await import(
        '@imgly/background-removal-node'
      );

      let source: any = input;
      if (Buffer.isBuffer(input)) {
        source = new Blob([new Uint8Array(input)]);
      }

      const blob = await removeBackground(source);
      const arrayBuffer = await blob.arrayBuffer();
      const resultBuffer = Buffer.from(arrayBuffer);

      this.logger.log(
        `Tách nền fallback thành công! Kích thước: ${resultBuffer.length} bytes`,
      );
      return resultBuffer;
    } catch (fallbackError) {
      this.logger.error('Lỗi khi thực hiện tách nền AI:', fallbackError);
      throw fallbackError;
    }
  }
}
