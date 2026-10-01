import {
  Injectable,
  Logger,
  InternalServerErrorException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenAI } from '@google/genai';

export interface WardrobeItemDto {
  id: string;
  name: string;
  category_name: string;
  primary_color: string;
  style_tags: string[];
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
  smart_fit_advice: SmartFitAdviceDto;
  item_ids?: string[];
}

export interface UserBodySummaryDto {
  gender: string;
  height_cm: number;
  weight_kg: number;
  bmi: number;
  body_frame: string;
  estimated_size: string;
}

@Injectable()
export class AiOutfitService {
  private readonly logger = new Logger(AiOutfitService.name);
  private aiClient: GoogleGenAI;

  constructor(private configService: ConfigService) {
    const apiKey = this.configService.get<string>('AI_ENGINE_API_KEY');
    this.aiClient = new GoogleGenAI({ apiKey: apiKey || '' });
  }

  /**
   * Tạo gợi ý outfit kết hợp Layering Canvas 2D và Smart Fit (Chiều cao & Cân nặng)
   */
  async generateOutfitRecommendations(
    contextPrompt: string,
    wardrobeItems: WardrobeItemDto[],
    bodySummary?: UserBodySummaryDto,
  ): Promise<RecommendedOutfitDto[]> {
    if (!wardrobeItems || wardrobeItems.length === 0) {
      return [];
    }

    const availableItemIds = new Set(wardrobeItems.map((item) => item.id));

    // 1. System Prompt theo đúng đặc tả Layering Canvas 2D + Smart Fit
    const systemInstruction = `
[SYSTEM ROLE]
Bạn là Trợ lý AI Thời trang & Styling Cá nhân hóa cho ứng dụng WEARSY.
Nhiệm vụ của bạn là chọn các món đồ từ tủ đồ kỹ thuật số của người dùng để tạo thành một bộ trang phục (Outfit) hoàn chỉnh, đồng thời phân tích sự tương thích về thẩm mỹ và đưa ra lời khuyên về độ vừa vặn/tôn dáng dựa trên số liệu thể trạng thực tế (Chiều cao & Cân nặng).

[CRITICAL CONSTRAINTS]
1. CHỈ ĐƯỢC CHỌN item_id có thật trong mảng [User Wardrobe]. Tuyệt đối KHÔNG tự tạo ra ID giả mạo (No Hallucination).
2. Tối thiểu mỗi outfit phải gồm 2 items (Ví dụ: 1 Top + 1 Bottom, hoặc 1 Dress + 1 Shoes, kèm áo khoác hoặc phụ kiện nếu có).
3. Đánh giá tính thẩm mỹ dựa trên quy tắc bánh xe màu sắc và mức độ trang trọng (Elegance/Color Score từ 1.0 đến 10.0).
4. Phân tích độ tôn dáng dựa vào [User Body Summary]:
   - Người gầy: Ưu tiên gợi ý đồ sáng màu, họa tiết sọc ngang, hoặc phối layering nhiều lớp (như khoác thêm blazer/cardigan) để tạo độ dày cơ thể.
   - Người đậm người/chiều cao khiêm tốn: Ưu tiên phối màu đơn sắc (Monochrome), sơ vin hoặc chọn quần cạp cao để kéo dài tỷ lệ chân.
5. Luôn trả về dữ liệu đúng định dạng JSON Schema được yêu cầu. Không thêm văn bản chào hỏi hay kết luận bên ngoài JSON.
    `;

    const userPayload = {
      user_context: {
        occasion: contextPrompt,
        style_preference: 'Thanh lịch, hiện đại',
      },
      user_body_summary: bodySummary || {
        gender: 'Female',
        height_cm: 160,
        weight_kg: 50,
        bmi: 19.5,
        body_frame: 'Fit / Standard',
        estimated_size: 'S',
      },
      wardrobe_items: wardrobeItems.map((item) => ({
        id: item.id,
        name: item.name,
        category: item.category_name,
        primary_color: item.primary_color,
        style_tags: item.style_tags,
        layer_order: item.layer_order || 1,
      })),
    };

    try {
      const model = this.configService.get<string>(
        'GEMINI_MODEL',
        'gemini-1.5-flash',
      );
      const response = await this.aiClient.models.generateContent({
        model,
        contents: [
          { role: 'user', parts: [{ text: JSON.stringify(userPayload) }] },
        ],
        config: {
          systemInstruction,
          responseMimeType: 'application/json',
          temperature: 0.2,
        },
      });

      const responseText = response.text || '[]';
      let rawOutfits: any = JSON.parse(responseText);
      if (!Array.isArray(rawOutfits)) {
        rawOutfits = [rawOutfits];
      }

      // 3. Anti-Hallucination Validation Layer (Lọc ID hợp lệ)
      const validatedOutfits: RecommendedOutfitDto[] = rawOutfits
        .map((outfit: any) => {
          const selected = outfit.selected_item_ids || outfit.item_ids || [];
          const validItemIds = selected.filter((id: string) =>
            availableItemIds.has(id),
          );
          return {
            outfit_id: outfit.outfit_id || `outfit_${Date.now()}`,
            title: outfit.title || 'Bộ trang phục Smart Fit',
            elegance_score: outfit.elegance_score || 9.0,
            color_score: outfit.color_score || 9.0,
            selected_item_ids: validItemIds,
            item_ids: validItemIds,
            stylist_reasoning:
              outfit.stylist_reasoning || outfit.ai_reasoning || '',
            smart_fit_advice: outfit.smart_fit_advice || {
              size_recommendation: `Size chuẩn ${userPayload.user_body_summary.estimated_size}`,
              body_proportion_tip:
                'Sơ vin áo gọn gàng để nâng cao tỷ lệ eo và chân.',
              fit_warnings: [],
            },
          };
        })
        .filter(
          (outfit: RecommendedOutfitDto) =>
            outfit.selected_item_ids.length >= 2,
        );

      return validatedOutfits;
    } catch (error) {
      this.logger.error('Lỗi khi kết nối AI Engine:', error);
      throw new InternalServerErrorException(
        'Không thể khởi tạo gợi ý outfit từ AI Engine.',
      );
    }
  }
}
