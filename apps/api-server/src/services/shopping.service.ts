import {
  Injectable,
  Logger,
  InternalServerErrorException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import { GoogleGenAI } from '@google/genai';
import { ShoppingCheckLogEntity } from '../models/shopping-check-log.entity';
import {
  ShoppingCompatibilityCheckDto,
  WardrobeItemRefDto,
} from '../dto/shopping-check.dto';
import { MissingItemRecommendationDto } from '../dto/missing-items.dto';

export interface SuggestedOutfitPair {
  title: string;
  style: string;
  wardrobe_item_ids: string[];
  wardrobe_items?: WardrobeItemRefDto[];
  styling_tip: string;
}

export interface ShoppingCompatibilityResult {
  prospective_item: string;
  category: string;
  color: string;
  price: number;
  image_url?: string;
  compatibility_score: number;
  score_level: 'HIGH' | 'MEDIUM' | 'LOW';
  recommendation_status: string;
  recommendation_reason: string;
  matching_items_count: number;
  compatible_items: WardrobeItemRefDto[];
  suggested_outfits: SuggestedOutfitPair[];
  color_harmony_analysis: string;
  silhouette_analysis: string;
  is_duplicate: boolean;
  duplicate_item_name?: string;
}

@Injectable()
export class ShoppingService {
  private readonly logger = new Logger(ShoppingService.name);
  private aiClient: GoogleGenAI;

  constructor(
    @InjectRepository(ShoppingCheckLogEntity)
    private readonly shoppingLogRepo: Repository<ShoppingCheckLogEntity>,
    private readonly configService: ConfigService,
  ) {
    const apiKey = this.configService.get<string>('AI_ENGINE_API_KEY');
    this.aiClient = new GoogleGenAI({ apiKey: apiKey || '' });
  }

  /**
   * Phân tích tính tương thích của món đồ dự định mua với tủ đồ hiện có
   */
  async checkCompatibility(
    dto: ShoppingCompatibilityCheckDto,
    userId: string = '00000000-0000-0000-0000-000000000001',
  ): Promise<ShoppingCompatibilityResult> {
    const wardrobe = dto.wardrobe_items || [];

    let result: ShoppingCompatibilityResult;

    try {
      result = await this.evaluateCompatibilityWithGemini(dto, wardrobe);
    } catch (error) {
      this.logger.warn(
        `Gemini AI Shopping Check fallback triggered due to: ${error.message}`,
      );
      result = this.evaluateCompatibilityFallback(dto, wardrobe);
    }

    // Ghi log vào cơ sở dữ liệu PostgreSQL
    try {
      const logEntry = this.shoppingLogRepo.create({
        user_id: userId,
        target_item_name: dto.item_name,
        target_item_price: dto.price,
        target_image_url: dto.image_url || null,
        compatible_item_count: result.matching_items_count,
        compatibility_score: result.compatibility_score.toString(),
        recommendation_status: result.recommendation_status,
        analysis_details: {
          score_level: result.score_level,
          recommendation_reason: result.recommendation_reason,
          color_harmony_analysis: result.color_harmony_analysis,
          silhouette_analysis: result.silhouette_analysis,
          is_duplicate: result.is_duplicate,
          duplicate_item_name: result.duplicate_item_name,
          suggested_outfits: result.suggested_outfits,
        },
      });
      await this.shoppingLogRepo.save(logEntry);
    } catch (dbError) {
      this.logger.error(`Failed to save shopping log: ${dbError.message}`);
    }

    return result;
  }

  /**
   * Gọi Gemini 2.5 Flash để phân tích độ tương thích thông minh
   */
  private async evaluateCompatibilityWithGemini(
    product: ShoppingCompatibilityCheckDto,
    wardrobe: WardrobeItemRefDto[],
  ): Promise<ShoppingCompatibilityResult> {
    const systemInstruction = `
[SYSTEM ROLE]
Bạn là Chuyên gia Tư vấn Mua sắm Thông minh & AI Stylist của ứng dụng WEARSY (Smart Shopping Assistant).
Mục tiêu của bạn là giúp người dùng TRÁNH MUA SẮM LÃNG PHÍ và TỐI ƯU HÓA TỦ ĐỒ CÁ NHÂN.

[NHIỆM VỤ ĐÁNH GIÁ]
Khi người dùng chuẩn bị mua một món đồ mới (Prospective Product), bạn cần đối chiếu với toàn bộ tủ đồ của họ để:
1. Phát hiện trùng lặp (Duplicate Detection): Nếu tủ đồ đã có món đồ cùng loại và cùng tông màu tương tự > 85%, hãy cảnh báo "ĐÃ CÓ ĐỒ TƯƠNG TỰ".
2. Tính điểm tương thích (Compatibility Score 0.0 - 10.0):
   - Món đồ có kết hợp được với ít nhất 3-5 món đồ có sẵn không?
   - Tính ứng dụng: Phối được nhiều phong cách (Work, Casual, Party) hay chỉ dùng được 1 lần?
   - Độ hài hòa màu sắc (Color Harmony): Dựa theo bánh xe màu sắc (Tương đồng, Bổ túc, Tỷ lệ 60-30-10).
3. Đưa ra Khuyến nghị Mua sắm dứt khoát:
   - "RẤT ĐÁNG MUA ✨" (Score >= 8.8)
   - "NÊN MUA 🔥" (7.5 <= Score < 8.8)
   - "CÂN NHẮC ⚠️" (5.0 <= Score < 7.5)
   - "KHÔNG NÊN MUA ❌" (Score < 5.0)
   - "ĐÃ CÓ ĐỒ TƯƠNG TỰ 🔁" (Nếu bị trùng lặp)
4. Gợi ý 2-3 bộ Outfit hoàn chỉnh kết hợp giữa món đồ mới và các món đồ có sẵn (CHỈ DÙNG ID CÓ THẬT trong danh sách tủ đồ).

[ĐỊNH DẠNG JSON SCHEMA BẮT BUỘC]
Trả về JSON chuẩn không có văn bản thừa bên ngoài:
{
  "compatibility_score": 8.8,
  "score_level": "HIGH", // "HIGH" | "MEDIUM" | "LOW"
  "recommendation_status": "RẤT ĐÁNG MUA ✨",
  "recommendation_reason": "Giải thích chi tiết lý do và tính ứng dụng của món đồ...",
  "matching_item_ids": ["id_1", "id_2"],
  "color_harmony_analysis": "Phân tích độ phối màu chi tiết...",
  "silhouette_analysis": "Phân tích vóc dáng và phom dáng trang phục...",
  "is_duplicate": false,
  "duplicate_item_name": null,
  "suggested_outfits": [
    {
      "title": "Office Chic Hiện Đại",
      "style": "Smart Casual",
      "wardrobe_item_ids": ["id_1", "id_2"],
      "styling_tip": "Mẹo phối đồ..."
    }
  ]
}
    `;

    const userPrompt = {
      prospective_product: {
        title: product.item_name,
        price: product.price,
        category: product.category || 'Chưa rõ',
        color: product.color || 'Chưa rõ',
        brand: product.brand || 'Khác',
        tags: product.tags || [],
        platform: product.platform || 'Online Store',
      },
      current_wardrobe_items: wardrobe.map((item) => ({
        id: item.id,
        name: item.name,
        category: item.category_name,
        color: item.primary_color,
        tags: item.style_tags,
      })),
    };

    const response = await this.aiClient.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: JSON.stringify(userPrompt),
      config: {
        systemInstruction,
        responseMimeType: 'application/json',
        temperature: 0.2,
      },
    });

    const parsed = JSON.parse(response.text.trim());

    // Map matched items
    const matchedIds = new Set<string>(parsed.matching_item_ids || []);
    const compatibleItems = wardrobe.filter((i) => matchedIds.has(i.id));

    const suggestedOutfits: SuggestedOutfitPair[] = (
      parsed.suggested_outfits || []
    ).map((so: any) => {
      const soIds = new Set<string>(so.wardrobe_item_ids || []);
      return {
        title: so.title || 'Outfit gợi ý',
        style: so.style || 'Casual',
        wardrobe_item_ids: so.wardrobe_item_ids || [],
        wardrobe_items: wardrobe.filter((w) => soIds.has(w.id)),
        styling_tip: so.styling_tip || '',
      };
    });

    return {
      prospective_item: product.item_name,
      category: product.category || 'Thời trang',
      color: product.color || 'Đa sắc',
      price: product.price,
      image_url: product.image_url,
      compatibility_score: Number(parsed.compatibility_score) || 8.5,
      score_level: parsed.score_level || 'HIGH',
      recommendation_status: parsed.recommendation_status || 'NÊN MUA 🔥',
      recommendation_reason:
        parsed.recommendation_reason ||
        'Sản phẩm phối hợp tốt với nhiều món đồ có sẵn trong tủ đồ.',
      matching_items_count: compatibleItems.length || matchedIds.size,
      compatible_items: compatibleItems,
      suggested_outfits: suggestedOutfits,
      color_harmony_analysis:
        parsed.color_harmony_analysis ||
        'Tông màu hài hòa theo quy tắc phối màu chuẩn.',
      silhouette_analysis:
        parsed.silhouette_analysis ||
        'Phom dáng vừa vặn, dễ dàng phối nhiều lớp (layering).',
      is_duplicate: Boolean(parsed.is_duplicate),
      duplicate_item_name: parsed.duplicate_item_name || undefined,
    };
  }

  /**
   * Logic Fallback nội bộ nhanh và ổn định khi AI offline
   */
  private evaluateCompatibilityFallback(
    product: ShoppingCompatibilityCheckDto,
    wardrobe: WardrobeItemRefDto[],
  ): ShoppingCompatibilityResult {
    const lowerName = product.item_name.toLowerCase();
    const lowerColor = (product.color || '').toLowerCase();
    const lowerCategory = (product.category || '').toLowerCase();

    // 1. Kiểm tra trùng lặp đơn giản
    const duplicate = wardrobe.find((item) => {
      const itemCat = (item.category_name || '').toLowerCase();
      const itemColor = (item.primary_color || '').toLowerCase();
      return (
        itemCat &&
        lowerCategory &&
        itemCat.includes(lowerCategory) &&
        itemColor &&
        lowerColor &&
        itemColor.includes(lowerColor)
      );
    });

    if (duplicate) {
      return {
        prospective_item: product.item_name,
        category: product.category || 'Thời trang',
        color: product.color || 'Đa sắc',
        price: product.price,
        image_url: product.image_url,
        compatibility_score: 4.5,
        score_level: 'LOW',
        recommendation_status: 'ĐÃ CÓ ĐỒ TƯƠNG TỰ 🔁',
        recommendation_reason: `Bạn đã có món đồ tương tự: "${duplicate.name}" (${duplicate.primary_color}). Việc mua thêm có thể gây lãng phí trừ khi bạn thực sự cần thay thế.`,
        matching_items_count: 2,
        compatible_items: wardrobe.slice(0, 2),
        suggested_outfits: [],
        color_harmony_analysis: 'Trùng gam màu với món đồ đã có trong tủ.',
        silhouette_analysis: 'Kiểu dáng tương đương các món đã sở hữu.',
        is_duplicate: true,
        duplicate_item_name: duplicate.name,
      };
    }

    // 2. Tính toán tương thích cơ bản
    const isNeutralColor = [
      'đen',
      'black',
      'trắng',
      'white',
      'be',
      'beige',
      'xám',
      'grey',
      'navy',
    ].some((c) => lowerColor.includes(c) || lowerName.includes(c));

    const matchingItems = wardrobe.filter((item) => {
      const itemCat = (item.category_name || '').toLowerCase();
      if (
        lowerCategory.includes('outerwear') ||
        lowerName.includes('blazer') ||
        lowerName.includes('khoác')
      ) {
        return (
          itemCat.includes('top') ||
          itemCat.includes('bottom') ||
          itemCat.includes('dress')
        );
      }
      if (lowerCategory.includes('top') || lowerName.includes('áo')) {
        return itemCat.includes('bottom') || itemCat.includes('outerwear');
      }
      if (
        lowerCategory.includes('bottom') ||
        lowerName.includes('quần') ||
        lowerName.includes('váy')
      ) {
        return itemCat.includes('top') || itemCat.includes('shoes');
      }
      return true;
    });

    const matchingCount = Math.max(matchingItems.length, 3);
    const baseScore = isNeutralColor ? 8.8 : 7.6;

    return {
      prospective_item: product.item_name,
      category: product.category || 'Thời trang',
      color: product.color || 'Đa sắc',
      price: product.price,
      image_url: product.image_url,
      compatibility_score: baseScore,
      score_level: baseScore >= 8.0 ? 'HIGH' : 'MEDIUM',
      recommendation_status:
        baseScore >= 8.0 ? 'RẤT ĐÁNG MUA ✨' : 'NÊN MUA 🔥',
      recommendation_reason: `Sản phẩm này có thể phối hợp linh hoạt với ${matchingCount} món đồ trong tủ đồ của bạn, mang lại tính ứng dụng cao.`,
      matching_items_count: matchingCount,
      compatible_items: matchingItems.slice(0, 4),
      suggested_outfits: [
        {
          title: 'Phong cách Tối giản Hiện đại',
          style: 'Minimalist Casual',
          wardrobe_item_ids: matchingItems.slice(0, 2).map((i) => i.id),
          wardrobe_items: matchingItems.slice(0, 2),
          styling_tip:
            'Kết hợp cùng item trung tính để tạo sự cân bằng và thanh lịch.',
        },
      ],
      color_harmony_analysis:
        'Tông màu hài hòa, dễ dàng phối hợp với các sắc độ cơ bản.',
      silhouette_analysis: 'Tỷ lệ phom dáng cân đối, tôn dáng người mặc.',
      is_duplicate: false,
    };
  }

  /**
   * Xác định các món đồ còn thiếu (Missing Items) trong tủ đồ để đề xuất bổ sung
   */
  async getMissingItems(
    wardrobe: WardrobeItemRefDto[] = [],
  ): Promise<MissingItemRecommendationDto[]> {
    const categories = wardrobe.map((w) =>
      (w.category_name || '').toLowerCase(),
    );
    const hasWhiteTop = wardrobe.some(
      (w) =>
        (w.primary_color || '').toLowerCase().includes('trắng') ||
        (w.name || '').toLowerCase().includes('trắng'),
    );
    const hasOuterwear = categories.some(
      (c) => c.includes('outerwear') || c.includes('khoác'),
    );
    const hasFormalBottom = wardrobe.some(
      (w) =>
        (w.name || '').toLowerCase().includes('tây') ||
        (w.name || '').toLowerCase().includes('âu'),
    );

    const recommendations: MissingItemRecommendationDto[] = [];

    if (!hasOuterwear) {
      recommendations.push({
        recommended_item_type: 'Áo Blazer Neutral (Beige / Đen)',
        category: 'Outerwear',
        suggested_color: 'Be hoặc Đen',
        priority: 'HIGH',
        reason:
          'Bổ sung 1 chiếc áo blazer dáng suông sẽ nâng cấp ngay lập tức ít nhất 6 outfit từ casual lên smart casual cho công sở hoặc sự kiện.',
        estimated_price_range: '450.000đ - 950.000đ',
        reference_links: [
          'https://shopee.vn/search?keyword=blazer+han+quoc+oversize',
        ],
      });
    }

    if (!hasWhiteTop) {
      recommendations.push({
        recommended_item_type: 'Áo Sơ Mi Trắng Form Rộng',
        category: 'Tops',
        suggested_color: 'Trắng',
        priority: 'HIGH',
        reason:
          'Item kinh điển ("capsule wardrobe essential") có thể phối với 100% các loại quần jeans, quần tây và chân váy hiện có.',
        estimated_price_range: '250.000đ - 450.000đ',
        reference_links: ['https://shopee.vn/search?keyword=so+mi+trang+basic'],
      });
    }

    if (!hasFormalBottom) {
      recommendations.push({
        recommended_item_type: 'Quần Tây Ống Suông Cạp Cao',
        category: 'Bottoms',
        suggested_color: 'Đen / Xám Than / Nâu Đất',
        priority: 'MEDIUM',
        reason:
          'Tạo hiệu ứng kéo dài chân, tôn dáng người mặc và phù hợp cho môi trường học tập, công sở chuyên nghiệp.',
        estimated_price_range: '280.000đ - 520.000đ',
        reference_links: [
          'https://shopee.vn/search?keyword=quan+tay+ong+suong+cap+cao',
        ],
      });
    }

    // Default universal recommendation if wardrobe is already well-stocked
    if (recommendations.length === 0) {
      recommendations.push({
        recommended_item_type: 'Thắt Lưng Da Khóa Kim Loại Tối Giản',
        category: 'Accessories',
        suggested_color: 'Nâu Da Bò / Đen',
        priority: 'LOW',
        reason:
          'Phụ kiện tạo điểm nhấn 10% theo quy tắc 60-30-10, giúp phân chia tỷ lệ cơ thể chuẩn hơn khi sơ vin.',
        estimated_price_range: '120.000đ - 250.000đ',
        reference_links: [
          'https://shopee.vn/search?keyword=that+lung+da+minimalist',
        ],
      });
    }

    return recommendations;
  }

  /**
   * Lấy lịch sử kiểm tra mua sắm của người dùng
   */
  async getHistory(userId: string, limit: number = 20) {
    return this.shoppingLogRepo.find({
      where: { user_id: userId },
      order: { created_at: 'DESC' },
      take: limit,
    });
  }

  /**
   * Danh sách sản phẩm mẫu để thử nghiệm nhanh trên ứng dụng
   */
  getSampleProducts() {
    return [
      {
        item_name: 'Áo Blazer Dáng Rộng Phong Cách Hàn Quốc',
        category: 'Outerwear',
        color: 'Be',
        brand: 'Zara Studio',
        price: 1290000,
        image_url:
          'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?q=80&w=800&auto=format&fit=crop',
        product_url: 'https://shopee.vn/product/zara-blazer-beige-oversized',
        tags: ['Smart Casual', 'Công sở', 'Minimalist'],
        platform: 'Shopee Mall',
      },
      {
        item_name: 'Quần Jeans Ống Suông Wide-Leg Vintage',
        category: 'Bottoms',
        color: 'Xanh Nhạt',
        brand: 'Levis Premium',
        price: 850000,
        image_url:
          'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?q=80&w=800&auto=format&fit=crop',
        product_url: 'https://shopee.vn/product/levis-wide-leg-vintage-jeans',
        tags: ['Streetwear', 'Casual', 'Y2K'],
        platform: 'Shopee Mall',
      },
      {
        item_name: 'Áo Sơ Mi Lụa Cổ V Thanh Lịch',
        category: 'Tops',
        color: 'Trắng Ngà',
        brand: 'Mango Formal',
        price: 490000,
        image_url:
          'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?q=80&w=800&auto=format&fit=crop',
        product_url: 'https://lazada.vn/product/mango-silk-shirt-white',
        tags: ['Office', 'Elegant', 'Minimalist'],
        platform: 'Lazada',
      },
      {
        item_name: 'Giày Sneaker Da Tối Giản Trắng',
        category: 'Shoes',
        color: 'Trắng',
        brand: 'Stan Classic',
        price: 1150000,
        image_url:
          'https://images.unsplash.com/photo-1549298916-b41d501d3772?q=80&w=800&auto=format&fit=crop',
        product_url: 'https://tiktok.com/@sneaker/white-classic',
        tags: ['Casual', 'Sporty', 'All-Match'],
        platform: 'TikTok Shop',
      },
    ];
  }
}
