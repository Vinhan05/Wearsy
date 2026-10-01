import {
  Injectable,
  Logger,
  BadRequestException,
  InternalServerErrorException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { GoogleGenAI } from '@google/genai';
import { CloudinaryService } from './cloudinary.service';
import { WardrobeItemEntity } from '../models/wardrobe-item.entity';
import { CategoryEntity } from '../models/category.entity';
import {
  ScanBulkResponseDto,
  DetectedItemDto,
  ScanBulkSummaryDto,
  BulkCommitDto,
} from '../dto/scan-bulk.dto';

interface GeminiDetectedItemRaw {
  name?: string;
  category_code?: string;
  sub_category?: string;
  primary_color?: string;
  box_2d?: [number, number, number, number];
  confidence?: number;
  season?: string;
  style_tags?: string[];
}

interface GeminiBulkScanResponseRaw {
  items?: GeminiDetectedItemRaw[];
}

@Injectable()
export class WardrobeScannerService {
  private readonly logger = new Logger(WardrobeScannerService.name);
  private aiClient: GoogleGenAI;

  constructor(
    private readonly configService: ConfigService,
    private readonly cloudinaryService: CloudinaryService,
    @InjectRepository(WardrobeItemEntity)
    private readonly wardrobeItemRepository: Repository<WardrobeItemEntity>,
    @InjectRepository(CategoryEntity)
    private readonly categoryRepository: Repository<CategoryEntity>,
  ) {
    const apiKey =
      this.configService.get<string>('AI_ENGINE_API_KEY') ||
      this.configService.get<string>('GEMINI_API_KEY') ||
      '';
    this.aiClient = new GoogleGenAI({ apiKey });
  }

  /**
   * Quét toàn bộ tủ đồ / sào đồ qua 1 bức ảnh chụp:
   * 1. Kiểm tra tính hợp lệ của tệp ảnh.
   * 2. Lưu trữ ảnh lên Cloudinary (hoặc cấp URL lưu tạm).
   * 3. Gửi ảnh đến Gemini Vision với Prompt tối ưu nhận diện tủ đồ.
   * 4. Ánh xạ danh mục vào bảng categories trong cơ sở dữ liệu.
   * 5. Tổng hợp số lượng (Áo thun, sơ mi, quần jeans, áo khoác, ...).
   * 6. Tùy chọn lưu thẳng vào bảng wardrobe_items nếu bật saveToCloset.
   */
  async scanWardrobeImage(
    file: Express.Multer.File,
    options?: { userId?: string; saveToCloset?: boolean },
  ): Promise<ScanBulkResponseDto> {
    if (!file || !file.buffer) {
      throw new BadRequestException(
        'Vui lòng tải lên tệp hình ảnh tủ đồ hợp lệ.',
      );
    }

    if (!file.mimetype.startsWith('image/')) {
      throw new BadRequestException(
        'Định dạng tệp không được hỗ trợ. Vui lòng tải lên ảnh (JPG, PNG, WEBP).',
      );
    }

    // 1. Chuẩn bị prompt và cấu hình cho Gemini Vision
    const systemInstruction = `
[SYSTEM ROLE]
Bạn là Chuyên gia Thị giác Máy tính (Computer Vision) & AI Thời trang của ứng dụng WEARSY.
Nhiệm vụ của bạn là nhận diện, đếm số lượng và định vị từng món trang phục trong bức ảnh chụp toàn cảnh tủ đồ, sào đồ, hoặc chồng quần áo của người dùng.

[NHIỆM VỤ CHI TIẾT]
1. Phát hiện tất cả các món đồ thời trang nhìn thấy được (kể cả bị che khuất một phần khi treo trên móc hoặc gấp gọn).
2. Với mỗi món đồ, hãy cung cấp:
   - name: Tên mô tả trang phục bằng Tiếng Việt thân thiện (ví dụ: "Áo sơ mi trắng", "Áo thun oversize đen", "Quần jeans xanh indigo", "Áo khoác blazer be", "Chân váy chữ A").
   - category_code: CHỈ ĐƯỢC CHỌN 1 trong 5 mã sau: ["TOPS", "BOTTOMS", "OUTERWEAR", "FOOTWEAR", "ACCESSORIES"].
     + TOPS: Áo thun, sơ mi, áo polo, áo len, hoodie, croptop, ba lỗ...
     + BOTTOMS: Quần jeans, quần tây/âu, quần short, quần kaki, chân váy...
     + OUTERWEAR: Áo blazer, áo khoác gió, áo phao, măng tô, áo vest...
     + FOOTWEAR: Giày sneakers, cao gót, boots, sandal...
     + ACCESSORIES: Túi xách, thắt lưng, nón/mũ, khăn quàng...
   - sub_category: Loại trang phục chi tiết bằng Tiếng Việt (ví dụ: "Áo thun", "Áo sơ mi", "Quần jeans", "Quần âu", "Áo khoác", "Chân váy", "Giày thể thao").
   - primary_color: Màu sắc chủ đạo bằng Tiếng Việt (ví dụ: "Trắng", "Đen", "Xanh navy", "Xanh lam", "Xám", "Be", "Nâu", "Đỏ", "Hồng", "Vàng", "Xanh lá").
   - box_2d: Khung chữ nhật bao quanh món đồ dạng [ymin, xmin, ymax, xmax] trong khoảng tọa độ chuẩn hóa từ 0 đến 1000.
   - confidence: Độ tin cậy nhận diện từ 0.70 đến 0.99.
   - season: "SPRING" | "SUMMER" | "AUTUMN" | "WINTER" | "ALL".
   - style_tags: Mảng 2-3 phong cách gợi ý (ví dụ: ["Casual", "Basic"], ["Office", "Smart Casual"]).

[CRITICAL FORMAT]
Trả về duy nhất định dạng JSON thuần túy theo schema:
{
  "items": [
    {
      "name": "string",
      "category_code": "TOPS" | "BOTTOMS" | "OUTERWEAR" | "FOOTWEAR" | "ACCESSORIES",
      "sub_category": "string",
      "primary_color": "string",
      "box_2d": [ymin, xmin, ymax, xmax],
      "confidence": number,
      "season": "string",
      "style_tags": ["string"]
    }
  ]
}
Tuyệt đối không giải thích thêm hay bọc mã markdown ngoài JSON.
`;

    // 2. Chạy song song Cloudinary upload, lấy Category Map và Gemini Vision analysis để tối ưu tốc độ (< 2s)
    const uploadPromise = this.cloudinaryService
      .uploadImage(file, 'wearsy/wardrobe_scans')
      .then((res) => res.secure_url)
      .catch((uploadError) => {
        this.logger.warn(
          `Không thể upload ảnh lên Cloudinary (${uploadError.message}). Sử dụng Data URI làm fallback tạm thời.`,
        );
        return `data:${file.mimetype};base64,${file.buffer.toString('base64').substring(0, 50)}...`;
      });

    const categoryMapPromise = this.getCategoryMap();

    const geminiPromise = (async () => {
      const model = this.configService.get<string>(
        'GEMINI_MODEL',
        'gemini-flash-lite-latest',
      );
      return this.aiClient.models.generateContent({
        model,
        contents: [
          {
            role: 'user',
            parts: [
              {
                text: 'Hãy quét bức ảnh tủ đồ này, đếm số lượng và định vị tất cả các loại quần áo, phụ kiện có trong ảnh.',
              },
              {
                inlineData: {
                  mimeType: file.mimetype,
                  data: file.buffer.toString('base64'),
                },
              },
            ],
          },
        ],
        config: {
          systemInstruction,
          responseMimeType: 'application/json',
          temperature: 0.1,
        },
      });
    })();

    let imageUrl = '';
    let categoryMap: Record<string, { id: number; name: string }> = {};
    let detectedRawItems: GeminiDetectedItemRaw[] = [];

    try {
      const [uploadedUrl, catMap, geminiResponse] = await Promise.all([
        uploadPromise,
        categoryMapPromise,
        geminiPromise,
      ]);

      imageUrl = uploadedUrl;
      categoryMap = catMap;

      const responseText = geminiResponse?.text || '{"items": []}';
      const parsed: GeminiBulkScanResponseRaw = JSON.parse(responseText);
      detectedRawItems = Array.isArray(parsed.items) ? parsed.items : [];
    } catch (aiError) {
      this.logger.error('Lỗi khi phân tích ảnh tủ đồ song song:', aiError);
      throw new InternalServerErrorException(
        `Không thể phân tích ảnh tủ đồ qua AI: ${aiError.message || 'Lỗi kết nối AI'}`,
      );
    }

    // 4. Chuẩn hóa và ánh xạ kết quả với cơ sở dữ liệu
    const detectedItems: DetectedItemDto[] = [];
    const summary: ScanBulkSummaryDto = {
      topsCount: 0,
      bottomsCount: 0,
      outerwearCount: 0,
      footwearCount: 0,
      accessoriesCount: 0,
      bySubCategory: {},
    };

    for (const raw of detectedRawItems) {
      const code = this.normalizeCategoryCode(raw.category_code);
      const catInfo = categoryMap[code] || {
        id: 1,
        name: 'Áo (Tops)',
      };

      const subCategory = raw.sub_category || 'Trang phục';
      const item: DetectedItemDto = {
        name: raw.name || `${subCategory} ${raw.primary_color || ''}`.trim(),
        categoryCode: code,
        categoryId: catInfo.id,
        categoryName: catInfo.name,
        subCategory,
        primaryColor: raw.primary_color || 'Đa sắc',
        box2d:
          Array.isArray(raw.box_2d) && raw.box_2d.length === 4
            ? raw.box_2d
            : [0, 0, 1000, 1000],
        confidence: typeof raw.confidence === 'number' ? raw.confidence : 0.9,
        season: raw.season || 'ALL',
        styleTags: Array.isArray(raw.style_tags) ? raw.style_tags : ['Casual'],
      };

      detectedItems.push(item);

      // Thống kê tổng hợp
      switch (code) {
        case 'TOPS':
          summary.topsCount++;
          break;
        case 'BOTTOMS':
          summary.bottomsCount++;
          break;
        case 'OUTERWEAR':
          summary.outerwearCount++;
          break;
        case 'FOOTWEAR':
          summary.footwearCount++;
          break;
        case 'ACCESSORIES':
          summary.accessoriesCount++;
          break;
      }

      summary.bySubCategory[subCategory] =
        (summary.bySubCategory[subCategory] || 0) + 1;
    }

    // 5. Tự động lưu vào tủ đồ nếu người dùng có yêu cầu
    let savedItemsCount = 0;
    if (options?.saveToCloset && options?.userId && detectedItems.length > 0) {
      savedItemsCount = await this.saveItemsToWardrobe(
        options.userId,
        detectedItems,
        imageUrl,
      );
    }

    return {
      success: true,
      message: `Quét thành công! Phát hiện ${detectedItems.length} món trang phục trong tủ đồ.`,
      imageUrl,
      totalDetected: detectedItems.length,
      summary,
      items: detectedItems,
      ...(options?.saveToCloset ? { savedItemsCount } : {}),
    };
  }

  /**
   * Lưu hàng loạt các món đồ đã qua kiểm duyệt/điều chỉnh của người dùng vào DB
   */
  async commitBulkItems(
    dto: BulkCommitDto,
  ): Promise<{ success: boolean; createdCount: number; itemIds: string[] }> {
    if (!dto.items || dto.items.length === 0) {
      throw new BadRequestException(
        'Danh sách trang phục cần lưu không được rỗng.',
      );
    }

    const defaultImg =
      dto.sourceImageUrl ||
      'https://res.cloudinary.com/wearsy/image/upload/v1/placeholder-item.png';

    const entities = dto.items.map((item) =>
      this.wardrobeItemRepository.create({
        user_id: dto.userId,
        category_id: item.categoryId || 1,
        name: item.name,
        image_url: item.imageUrl || defaultImg,
        bg_removed_url: null,
        primary_color: item.primaryColor || 'Đa sắc',
        sub_colors: item.subColors || [],
        style_tags: item.styleTags || ['Casual'],
        season: item.season || 'ALL',
        ai_processing_status: 'BULK_SCANNED',
        status: 'ACTIVE',
        wear_count: 0,
      }),
    );

    const saved = await this.wardrobeItemRepository.save(entities);

    return {
      success: true,
      createdCount: saved.length,
      itemIds: saved.map((i) => i.id),
    };
  }

  /**
   * Helper: Lưu tự động danh sách DetectedItem vào tủ đồ
   */
  private async saveItemsToWardrobe(
    userId: string,
    items: DetectedItemDto[],
    sourceImageUrl: string,
  ): Promise<number> {
    try {
      const entities = items.map((item) =>
        this.wardrobeItemRepository.create({
          user_id: userId,
          category_id: item.categoryId,
          name: item.name,
          image_url: sourceImageUrl,
          bg_removed_url: null,
          primary_color: item.primaryColor,
          sub_colors: [],
          style_tags: item.styleTags,
          season: item.season,
          ai_processing_status: 'BULK_SCANNED',
          status: 'ACTIVE',
          wear_count: 0,
        }),
      );

      const saved = await this.wardrobeItemRepository.save(entities);
      return saved.length;
    } catch (err) {
      this.logger.error(
        'Lỗi khi tự động lưu trang phục vào bảng wardrobe_items:',
        err,
      );
      return 0;
    }
  }

  /**
   * Helper: Tạo bảng ánh xạ mã Category với ID và Tên trong Database
   */
  private async getCategoryMap(): Promise<
    Record<string, { id: number; name: string }>
  > {
    const fallbackMap: Record<string, { id: number; name: string }> = {
      TOPS: { id: 1, name: 'Áo (Tops)' },
      BOTTOMS: { id: 2, name: 'Quần & Váy (Bottoms)' },
      FOOTWEAR: { id: 3, name: 'Giày Dép (Footwear)' },
      OUTERWEAR: { id: 4, name: 'Áo Khoác (Outerwear)' },
      ACCESSORIES: { id: 5, name: 'Phụ Kiện (Accessories)' },
    };

    try {
      const categories = await this.categoryRepository.find();
      if (!categories || categories.length === 0) {
        return fallbackMap;
      }

      const map: Record<string, { id: number; name: string }> = {};
      for (const cat of categories) {
        if (cat.code) {
          map[cat.code.toUpperCase()] = { id: cat.id, name: cat.name };
        }
      }
      return { ...fallbackMap, ...map };
    } catch (err) {
      this.logger.warn(
        `Không thể nạp categories từ DB (${err.message}). Sử dụng fallback map chuẩn.`,
      );
      return fallbackMap;
    }
  }

  /**
   * Helper: Chuẩn hóa category_code từ AI
   */
  private normalizeCategoryCode(
    code?: string,
  ): 'TOPS' | 'BOTTOMS' | 'OUTERWEAR' | 'FOOTWEAR' | 'ACCESSORIES' {
    if (!code) return 'TOPS';
    const upper = code.trim().toUpperCase();
    if (['TOPS', 'TOP', 'SHIRT', 'T_SHIRT'].includes(upper)) return 'TOPS';
    if (['BOTTOMS', 'BOTTOM', 'PANTS', 'JEANS', 'SKIRT'].includes(upper))
      return 'BOTTOMS';
    if (['OUTERWEAR', 'JACKET', 'COAT', 'BLAZER'].includes(upper))
      return 'OUTERWEAR';
    if (['FOOTWEAR', 'SHOES', 'SNEAKERS'].includes(upper)) return 'FOOTWEAR';
    if (['ACCESSORIES', 'ACCESSORY', 'BAG', 'HAT'].includes(upper))
      return 'ACCESSORIES';
    return 'TOPS';
  }
}
