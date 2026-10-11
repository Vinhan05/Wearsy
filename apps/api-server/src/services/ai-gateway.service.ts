import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class AiGatewayService {
  private readonly logger = new Logger(AiGatewayService.name);
  private static dynamicUrl: string | null = null;
  private static lastRegisteredAt: Date | null = null;

  constructor(private readonly configService: ConfigService) {}

  /**
   * Cập nhật URL AI Orchestrator động (khi Cloudflare Tunnel sinh ra link mới)
   */
  setDynamicUrl(url: string): string {
    const cleanUrl = url.trim().replace(/\/+$/, '');
    AiGatewayService.dynamicUrl = cleanUrl;
    AiGatewayService.lastRegisteredAt = new Date();
    this.logger.log(
      `[AI Auto-Registration] Đã tự động cập nhật AI Orchestrator URL mới: ${cleanUrl}`,
    );
    return cleanUrl;
  }

  /**
   * Lấy URL AI Orchestrator đang hoạt động:
   * 1. Ưu tiên URL động vừa đăng ký từ máy local qua Cloudflare
   * 2. Kế tiếp là biến môi trường AI_ORCHESTRATOR_URL từ Render .env
   * 3. Mặc định là localhost http://127.0.0.1:8000
   */
  getOrchestratorUrl(): string {
    if (AiGatewayService.dynamicUrl && AiGatewayService.dynamicUrl.length > 5) {
      return AiGatewayService.dynamicUrl;
    }
    const envUrl = this.configService.get<string>('AI_ORCHESTRATOR_URL');
    if (envUrl && envUrl.trim().length > 5) {
      return envUrl.trim().replace(/\/+$/, '');
    }
    const procUrl = process.env.AI_ORCHESTRATOR_URL;
    if (procUrl && procUrl.trim().length > 5) {
      return procUrl.trim().replace(/\/+$/, '');
    }
    return 'http://127.0.0.1:8000';
  }

  /**
   * Lấy trạng thái kết nối
   */
  getStatus() {
    return {
      active_url: this.getOrchestratorUrl(),
      is_dynamic: Boolean(AiGatewayService.dynamicUrl),
      last_registered_at: AiGatewayService.lastRegisteredAt,
    };
  }
}
