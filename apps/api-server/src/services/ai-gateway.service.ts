import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';

@Injectable()
export class AiGatewayService {
  private readonly logger = new Logger(AiGatewayService.name);

  constructor(private readonly configService: ConfigService) {}

  /**
   * Lấy URL AI Orchestrator trực tiếp từ biến môi trường (AI_ORCHESTRATOR_URL):
   * Người dùng thiết lập thủ công trên Render Dashboard / file .env.
   */
  getOrchestratorUrl(): string {
    const rawEnv =
      this.configService.get<string>('AI_ORCHESTRATOR_URL') ||
      process.env.AI_ORCHESTRATOR_URL ||
      '';
    if (rawEnv && rawEnv.trim().length > 5) {
      // Tách chuỗi nếu người dùng vô tình dán nhiều URL hoặc có khoảng trắng
      const urls = rawEnv
        .trim()
        .split(/\s+/)
        .filter((u) => u.startsWith('http'));
      if (urls.length > 0) {
        // Lấy URL cuối cùng được dán vào
        return urls[urls.length - 1].trim().replace(/\/+$/, '');
      }
      return rawEnv.trim().replace(/\/+$/, '');
    }
    return 'http://127.0.0.1:8000';
  }

  /**
   * Kiểm tra trạng thái kết nối tới AI Orchestrator theo ENV
   */
  async getStatus() {
    const activeUrl = this.getOrchestratorUrl();
    let isReachable = false;
    let reachError: string | null = null;

    try {
      const resp = await axios.get(`${activeUrl}/health`, { timeout: 4000 });
      if (resp.status === 200) {
        isReachable = true;
      }
    } catch (e: any) {
      reachError = e.message;
    }

    return {
      active_url: activeUrl,
      is_manual_env: true,
      is_reachable: isReachable,
      error: reachError,
    };
  }
}
