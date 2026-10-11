import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';

export interface WardrobeItemDto {
  id: string;
  name: string;
  category_name?: string;
  category?: string;
  primary_color: string;
  style_tags: string[];
  image_url?: string;
  bg_removed_url?: string;
  layer_order?: number;
}

export interface SmartFitAdviceDto {
  size_recommendation: string;
  body_proportion_tip: string;
  fit_warnings: string[];
}

export interface RecommendedOutfitDto {
  outfit_id?: string;
  title: string;
  elegance_score: number;
  color_score: number;
  selected_item_ids: string[];
  stylist_reasoning: string;
  image_url?: string;
  image_base64?: string;
  smart_fit_advice?: SmartFitAdviceDto;
  item_ids?: string[];
  is_ai_rendered?: boolean;
}

export interface UserBodySummaryDto {
  gender: string;
  height_cm: number;
  weight_kg: number;
  bmi: number;
  body_frame: string;
  estimated_size: string;
}

import { AiGatewayService } from './ai-gateway.service';

@Injectable()
export class AiOutfitService {
  private readonly logger = new Logger(AiOutfitService.name);

  constructor(
    private configService: ConfigService,
    private aiGatewayService: AiGatewayService,
  ) {}

  private get orchestratorUrl(): string {
    return this.aiGatewayService.getOrchestratorUrl();
  }

  /**
   * Gửi yêu cầu phối đồ đến AI Orchestrator (Gemma 4 Multimodal + ComfyUI Try-on)
   */
  async generateOutfitRecommendations(
    contextPrompt: string,
    wardrobeItems: WardrobeItemDto[],
    bodySummary?: UserBodySummaryDto,
    userName: string = 'Bạn',
  ): Promise<RecommendedOutfitDto[]> {
    if (!wardrobeItems || wardrobeItems.length === 0) {
      return [];
    }

    const availableItemIds = new Set(
      wardrobeItems.map((item) => String(item.id)),
    );

    const payload = {
      user_prompt: contextPrompt,
      user_name: userName,
      user_body_summary: bodySummary || {
        gender: 'Female',
        height_cm: 160,
        weight_kg: 50,
        bmi: 19.5,
        body_frame: 'Fit / Standard',
        estimated_size: 'S',
      },
      wardrobe_items: wardrobeItems.map((item) => ({
        id: String(item.id),
        name: item.name,
        category: item.category_name || item.category || 'Trang phục',
        primary_color: item.primary_color || 'Đa sắc',
        style_tags: item.style_tags || [],
        image_url: item.bg_removed_url || item.image_url || '',
        layer_order: item.layer_order || 1,
      })),
    };

    try {
      this.logger.log(
        `Connecting to AI Orchestrator at: ${this.orchestratorUrl}/api/v1/stylist/recommend`,
      );
      const response = await axios.post(
        `${this.orchestratorUrl}/api/v1/stylist/recommend`,
        payload,
        { timeout: 1800000 },
      );

      const data = response.data;
      const rawSelected = data.selected_item_ids || [];
      const validItemIds = rawSelected.filter((id: string) =>
        availableItemIds.has(String(id)),
      );

      // Fallback if needed
      const finalItemIds =
        validItemIds.length > 0
          ? validItemIds
          : wardrobeItems.slice(0, 3).map((i) => String(i.id));

      const orchestratorBase = this.orchestratorUrl.replace(/\/+$/, '');
      const formattedImageUrl = data.image_url
        ? data.image_url.startsWith('http')
          ? data.image_url
          : `${orchestratorBase}${data.image_url.startsWith('/') ? '' : '/'}${data.image_url}`
        : data.image_base64 || undefined;

      const outfitResult: RecommendedOutfitDto = {
        outfit_id: `outfit_${Date.now()}`,
        title: data.title || 'Bộ trang phục đề xuất từ AI',
        elegance_score: Number(data.elegance_score) || 9.2,
        color_score: Number(data.color_score) || 9.0,
        selected_item_ids: finalItemIds,
        item_ids: finalItemIds,
        stylist_reasoning:
          data.reply ||
          'Set đồ kết hợp hài hòa, tôn dáng và phù hợp hoàn cảnh.',
        image_url: formattedImageUrl,
        image_base64: data.image_base64,
        is_ai_rendered: data.is_ai_rendered ?? false,
        smart_fit_advice: {
          size_recommendation: `Size ${payload.user_body_summary.estimated_size}`,
          body_proportion_tip:
            'Phối đồ cân đối tỷ lệ cơ thể và tôn nét thanh lịch.',
          fit_warnings: [],
        },
      };

      return [outfitResult];
    } catch (error: any) {
      this.logger.warn(
        `AI Orchestrator unavailable or error (${error.message}), using smart fallback heuristic.`,
      );

      // Fallback heuristic if AI service is offline
      const selected = wardrobeItems.slice(0, 3).map((i) => String(i.id));
      const names = wardrobeItems
        .slice(0, 3)
        .map((i) => i.name)
        .join(', ');

      return [
        {
          outfit_id: `outfit_${Date.now()}`,
          title: `Gợi ý phối đồ cho "${contextPrompt}"`,
          elegance_score: 9.0,
          color_score: 8.8,
          selected_item_ids: selected,
          item_ids: selected,
          stylist_reasoning: `Dựa trên tủ đồ hiện tại, bộ phối kết hợp ${names} là sự lựa chọn hài hòa và trang nhã nhất cho dịp "${contextPrompt}".`,
          smart_fit_advice: {
            size_recommendation: 'Chuẩn form dáng',
            body_proportion_tip:
              'Sơ vin gọn gàng để tạo điểm nhấn eo và tôn chiều cao.',
            fit_warnings: [],
          },
        },
      ];
    }
  }

  /**
   * Trò chuyện cùng AI Stylist (hỏi thăm, đối thoại, chốt phối đồ)
   */
  async chatWithStylist(
    messages: { role: string; content: string }[],
    wardrobeItems: WardrobeItemDto[],
    userProfile?: any,
    userName: string = 'Bạn',
    forceFinalize: boolean = false,
  ) {
    const payload = {
      messages,
      user_name: userName,
      user_profile: userProfile,
      wardrobe_items: wardrobeItems.map((item) => ({
        id: String(item.id),
        name: item.name,
        category: item.category_name || item.category || 'Trang phục',
        primary_color: item.primary_color || 'Đa sắc',
        style_tags: item.style_tags || [],
        image_url: item.bg_removed_url || item.image_url || '',
      })),
      force_finalize: forceFinalize,
    };

    try {
      this.logger.log(
        `Connecting to AI Stylist Chat: ${this.orchestratorUrl}/api/v1/stylist/chat`,
      );
      const response = await axios.post(
        `${this.orchestratorUrl}/api/v1/stylist/chat`,
        payload,
        { timeout: 60000 },
      );
      const data = response.data;
      if (data.action === 'FINALIZE_OUTFIT') {
        const orchestratorBase = this.orchestratorUrl.replace(/\/+$/, '');
        const formattedImageUrl = data.image_url
          ? data.image_url.startsWith('http')
            ? data.image_url
            : `${orchestratorBase}${data.image_url.startsWith('/') ? '' : '/'}${data.image_url}`
          : data.image_base64 || undefined;
        data.image_url = formattedImageUrl;
      }
      return data;
    } catch (err: any) {
      this.logger.warn(`AI Stylist Chat error: ${err.message}`);
      return {
        success: true,
        action: 'CONVERSATION',
        reply: `Chào ${userName}! Stylist sẵn sàng hỗ trợ bạn. Bạn dự định diện trang phục này ở không gian nào (nhà hàng, quán cà phê hay dạo phố)? Khi bạn đã sẵn sàng, hãy bấm '✨ Chốt & Phối đồ' nhé!`,
      };
    }
  }
}
