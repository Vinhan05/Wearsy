import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenAI } from '@google/genai';
import { ColorScoreRequestDto } from '../dto/color-score.dto';

export interface ColorHarmonyAnalysisResult {
  score: number;
  harmony_type: string;
  rule_applied: string;
  feedback: string;
  color_ratio_evaluation: string;
  styling_tips: string[];
}

export interface ChallengeItem {
  challenge_id: string;
  title: string;
  category: string;
  description: string;
  reward_badge: string;
  reward_points: number;
  status: 'AVAILABLE' | 'IN_PROGRESS' | 'COMPLETED';
  progress_text: string;
}

@Injectable()
export class GamificationService {
  private readonly logger = new Logger(GamificationService.name);
  private aiClient: GoogleGenAI;

  constructor(private readonly configService: ConfigService) {
    const apiKey = this.configService.get<string>('AI_ENGINE_API_KEY');
    this.aiClient = new GoogleGenAI({ apiKey: apiKey || '' });
  }

  /**
   * Tính toán và chấm điểm phối màu (Color Harmony Score)
   */
  async calculateColorScore(
    dto: ColorScoreRequestDto,
  ): Promise<ColorHarmonyAnalysisResult> {
    try {
      return await this.evaluateWithGemini(dto.colors, dto.occasion);
    } catch (error) {
      this.logger.warn(
        `Gemini Color Score fallback triggered: ${error.message}`,
      );
      return this.evaluateFallback(dto.colors);
    }
  }

  private async evaluateWithGemini(
    colors: string[],
    occasion?: string,
  ): Promise<ColorHarmonyAnalysisResult> {
    const systemInstruction = `
[SYSTEM ROLE]
Bạn là Chuyên gia Lý thuyết Màu sắc & Styling Thời trang cao cấp cho WEARSY.
Bạn tính toán điểm phối màu (Color Harmony Score) từ danh sách màu và đánh giá theo các quy tắc bánh xe màu sắc (Color Wheel).

[QUY TẮC PHỐI MÀU THỜI TRANG]
1. Tương đồng (Analogous): Các màu nằm liền kề trên bánh xe màu sắc (Ví dụ: Xanh dương - Xanh ngọc - Xanh lá). Điểm cao: 9.0 - 9.6.
2. Bổ túc trực tiếp (Complementary): Đối lập 180 độ (Ví dụ: Xanh navy & Cam đất). Điểm: 8.8 - 9.4.
3. Tỷ lệ phối màu vàng thời trang 60 - 30 - 10: 60% màu nền/chủ đạo, 30% màu thứ cấp, 10% điểm nhấn (Accent).
4. Phối màu đơn sắc (Monochrome) & Neutrals (Trắng, Đen, Xám, Be, Nâu): Rất an toàn và thanh lịch, điểm: 9.2 - 9.8.
5. Quá 4 màu sặc sỡ không có màu trung tính làm cầu nối: Điểm thấp: 6.0 - 7.5.

[OUTPUT JSON SCHEMA]
{
  "score": 9.4,
  "harmony_type": "ANALOGOUS", // ANALOGOUS | COMPLEMENTARY | MONOCHROME | TRIADIC | CONTRAST
  "rule_applied": "Quy tắc phối màu tương đồng (Analogous) & tỷ lệ 60-30-10",
  "feedback": "Sự kết hợp màu sắc thanh thoát, độ tương phản vừa đủ tạo chiều sâu.",
  "color_ratio_evaluation": "60% Trắng nền + 30% Xanh Navy trang nhã + 10% Tím làm điểm nhấn tinh tế.",
  "styling_tips": [
    "Sử dụng phụ kiện kim loại bạc để tăng thêm độ sang trọng cho bảng màu lạnh này.",
    "Tránh thêm màu thứ 4 để giữ sự tinh gọn."
  ]
}
    `;

    const response = await this.aiClient.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: JSON.stringify({
        input_colors: colors,
        occasion: occasion || 'Casual / Everyday',
      }),
      config: {
        systemInstruction,
        responseMimeType: 'application/json',
        temperature: 0.2,
      },
    });

    const parsed = JSON.parse(response.text.trim());
    return {
      score: Number(parsed.score) || 9.2,
      harmony_type: parsed.harmony_type || 'ANALOGOUS',
      rule_applied:
        parsed.rule_applied ||
        'Quy tắc phối màu tương đồng & cân bằng sắc độ',
      feedback:
        parsed.feedback ||
        'Tông màu kết hợp hài hòa, mang lại vẻ ngoài lịch thiệp.',
      color_ratio_evaluation:
        parsed.color_ratio_evaluation ||
        'Tỷ lệ màu cân đối giữa màu chủ đạo và phụ kiện.',
      styling_tips: parsed.styling_tips || [
        'Giữ nguyên tông màu chủ đạo để tạo ấn tượng thị giác gọn gàng.',
      ],
    };
  }

  private evaluateFallback(colors: string[]): ColorHarmonyAnalysisResult {
    const count = colors.length;
    let score = 9.2;
    let harmonyType = 'MONOCHROME';
    let rule = 'Quy tắc phối màu hài hòa tối giản (Minimalist Harmony)';

    if (count === 1) {
      score = 9.5;
      harmonyType = 'MONOCHROME';
      rule = 'Quy tắc phối màu đơn sắc thanh lịch';
    } else if (count === 2 || count === 3) {
      score = 9.3;
      harmonyType = 'ANALOGOUS';
      rule = 'Quy tắc phối màu tương đồng & tỷ lệ chuẩn 60-30-10';
    } else if (count >= 4) {
      score = 8.0;
      harmonyType = 'CONTRAST';
      rule = 'Phối màu đa sắc tương phản';
    }

    return {
      score,
      harmony_type: harmonyType,
      rule_applied: rule,
      feedback:
        'Sự kết hợp các gam màu mang lại tổng thể cân đối, hiện đại và rất dễ ứng dụng.',
      color_ratio_evaluation:
        '60% Màu nền chính, 30% màu kết hợp và 10% chi tiết tạo điểm nhấn.',
      styling_tips: [
        'Chọn phụ kiện màu trung tính (đen, trắng, da bò) để hoàn thiện set đồ.',
        'Đảm bảo sự đồng điệu về độ sáng (saturation) giữa các món đồ.',
      ],
    };
  }

  /**
   * Lấy danh sách thử thách phối đồ (Fashion Gamification Challenges)
   */
  getChallenges(): ChallengeItem[] {
    return [
      {
        challenge_id: 'ch_earth_tone_2026',
        title: 'Thử Thách Tone Đất (Earth Tone Explorer)',
        category: 'Color Harmony',
        description:
          'Phối 1 outfit kết hợp hoàn hảo giữa Nâu, Be, Xanh rêu hoặc Khaki theo tỷ lệ 60-30-10.',
        reward_badge: 'Master of Earth Tone 🍂',
        reward_points: 150,
        status: 'IN_PROGRESS',
        progress_text: 'Đã hoàn thành 1/2 outfit',
      },
      {
        challenge_id: 'ch_capsule_minimalist',
        title: 'Thử Thách Tối Giản 5 Món (Minimalist Capsule)',
        category: 'Wardrobe Efficiency',
        description:
          'Tạo ra 3 outfit khác nhau cho 3 ngày liên tiếp chỉ bằng 5 món đồ trong tủ.',
        reward_badge: 'Capsule Champion ✨',
        reward_points: 200,
        status: 'AVAILABLE',
        progress_text: 'Chưa bắt đầu',
      },
      {
        challenge_id: 'ch_pastel_spring',
        title: 'Phối Màu Pastel Nhẹ Nhàng (Pastel Dreamer)',
        category: 'Color Harmony',
        description:
          'Sử dụng các gam màu phấn như Hồng Pastel, Xanh Baby, Vàng Bơ để đạt điểm màu > 9.0.',
        reward_badge: 'Pastel Stylist 🌸',
        reward_points: 120,
        status: 'AVAILABLE',
        progress_text: 'Chưa bắt đầu',
      },
      {
        challenge_id: 'ch_smart_shopping_saver',
        title: 'Người Mua Sắm Thông Thái (Smart Saver)',
        category: 'Smart Shopping',
        description:
          'Kiểm tra độ tương thích trước khi mua ít nhất 3 lần để tránh lãng phí đồ trùng.',
        reward_badge: 'Smart Fashion Shopper 🛍️',
        reward_points: 300,
        status: 'COMPLETED',
        progress_text: 'Đã hoàn thành (3/3)',
      },
    ];
  }
}
