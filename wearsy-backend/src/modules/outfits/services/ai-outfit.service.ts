import { Injectable, Logger, InternalServerErrorException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenAI } from '@google/genai';

export interface WardrobeItemDto {
  id: string;
  name: string;
  category_name: string;
  primary_color: string;
  style_tags: string[];
}

export interface RecommendedOutfitDto {
  title: string;
  elegance_score: number;
  ai_reasoning: string;
  item_ids: string[];
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
   * Tạo gợi ý outfit dựa trên prompt bối cảnh và danh sách tủ đồ cá nhân
   */
  async generateOutfitRecommendations(
    contextPrompt: string,
    wardrobeItems: WardrobeItemDto[],
  ): Promise<RecommendedOutfitDto[]> {
    if (!wardrobeItems || wardrobeItems.length === 0) {
      return [];
    }

    const availableItemIds = new Set(wardrobeItems.map((item) => item.id));

    // 1. Xây dựng System Prompt với quy tắc ngặt nghèo chống Hallucination
    const systemInstruction = `
    Bạn là chuyên gia tư vấn thời trang cá nhân AI cho ứng dụng WEARSY (Wear + Easy).
    Nhiệm vụ: Phân tích tủ đồ cá nhân của người dùng và chọn ra các bộ trang phục (Outfit) phù hợp nhất với bối cảnh được yêu cầu.

    QUY TẮC BẮT BUỘC:
    1. CHỈ ĐƯỢC CHỌN các item_id TỒN TẠI trong danh sách tủ đồ bên dưới. Tuyệt đối KHÔNG TỰ TẠO ID MỚI.
    2. Mỗi outfit gồm: 1 Áo + 1 Quần/Váy (hoặc 1 Đầm/Jumpsuit), kèm Giày và Phụ kiện phù hợp nếu có trong tủ.
    3. Đánh giá điểm thanh lịch (elegance_score: từ 1.0 đến 10.0).
    4. Trả về đúng định dạng JSON Array chứa các object outfit với cấu trúc:
       [
         {
           "title": "Tên bộ trang phục",
           "elegance_score": 9.5,
           "ai_reasoning": "Lý do phối đồ chi tiết",
           "item_ids": ["uuid-item-1", "uuid-item-2"]
         }
       ]
    `;

    const userPayload = {
      context_prompt: contextPrompt,
      user_wardrobe: wardrobeItems.map((item) => ({
        id: item.id,
        name: item.name,
        category: item.category_name,
        color: item.primary_color,
        styles: item.style_tags,
      })),
    };

    try {
      // 2. Gọi Gemini API với Structured JSON Output Mode
      const model = this.configService.get<string>('GEMINI_MODEL', 'gemini-3.6-flash');
      const response = await this.aiClient.models.generateContent({
        model,
        contents: [
          { role: 'user', parts: [{ text: JSON.stringify(userPayload) }] },
        ],
        config: {
          systemInstruction,
          responseMimeType: 'application/json',
          temperature: 0.2, // Giảm sáng tạo do AI để đảm bảo tuân thủ ID
        },
      });

      const responseText = response.text || '[]';
      const rawOutfits: RecommendedOutfitDto[] = JSON.parse(responseText);

      // 3. Anti-Hallucination Validation Layer (Lọc ID hợp lệ)
      const validatedOutfits = rawOutfits
        .map((outfit) => {
          const validItemIds = (outfit.item_ids || []).filter((id) =>
            availableItemIds.has(id),
          );
          return {
            ...outfit,
            item_ids: validItemIds,
          };
        })
        .filter((outfit) => outfit.item_ids.length >= 2); // Outfit phải có tối thiểu 2 món

      return validatedOutfits;
    } catch (error) {
      this.logger.error('Lỗi khi kết nối AI Engine:', error);
      throw new InternalServerErrorException(
        'Không thể khởi tạo gợi ý outfit từ AI Engine.',
      );
    }
  }
}
