import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { InternalServerErrorException } from '@nestjs/common';
import { AiOutfitService, WardrobeItemDto } from './ai-outfit.service';

// Mock module @google/genai
const mockGenerateContent = jest.fn();

jest.mock('@google/genai', () => {
  return {
    GoogleGenAI: jest.fn().mockImplementation(() => ({
      models: {
        generateContent: mockGenerateContent,
      },
    })),
  };
});

describe('AiOutfitService', () => {
  let service: AiOutfitService;
  let mockConfigService: Partial<ConfigService>;

  const sampleWardrobe: WardrobeItemDto[] = [
    {
      id: 'item-1',
      name: 'Áo sơ mi trắng Oxford',
      category_name: 'Áo (Tops)',
      primary_color: 'Trắng',
      style_tags: ['Thanh lịch', 'Công sở'],
    },
    {
      id: 'item-2',
      name: 'Quần âu đen',
      category_name: 'Quần (Bottoms)',
      primary_color: 'Đen',
      style_tags: ['Thanh lịch'],
    },
    {
      id: 'item-3',
      name: 'Giày Loafer da nâu',
      category_name: 'Giày (Footwear)',
      primary_color: 'Nâu',
      style_tags: ['Thanh lịch'],
    },
  ];

  beforeEach(async () => {
    mockConfigService = {
      get: jest.fn().mockReturnValue('mock-gemini-api-key'),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AiOutfitService,
        {
          provide: ConfigService,
          useValue: mockConfigService,
        },
      ],
    }).compile();

    service = module.get<AiOutfitService>(AiOutfitService);
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('generateOutfitRecommendations', () => {
    it('1. Trả về mảng rỗng nếu tủ đồ của người dùng trống', async () => {
      const result = await service.generateOutfitRecommendations(
        'Đi thuyết trình đồ án',
        [],
      );

      expect(result).toEqual([]);
      expect(mockGenerateContent).not.toHaveBeenCalled();
    });

    it('2. Trả về danh sách bộ outfit hợp lệ được AI gợi ý', async () => {
      const mockAiResponse = [
        {
          title: 'Trang phục Thuyết trình Thanh lịch',
          elegance_score: 9.5,
          color_score: 9.0,
          ai_reasoning: 'Áo sơ mi kết hợp quần âu đen mang lại vẻ lịch sự.',
          item_ids: ['item-1', 'item-2', 'item-3'],
        },
      ];

      mockGenerateContent.mockResolvedValueOnce({
        text: JSON.stringify(mockAiResponse),
      });

      const result = await service.generateOutfitRecommendations(
        'Đi thuyết trình đồ án',
        sampleWardrobe,
      );

      expect(result).toHaveLength(1);
      expect(result[0].title).toBe('Trang phục Thuyết trình Thanh lịch');
      expect(result[0].item_ids).toEqual(['item-1', 'item-2', 'item-3']);
      expect(mockGenerateContent).toHaveBeenCalledTimes(1);
    });

    it('3. Lọc bỏ các ID không hợp lệ (Chống AI Hallucination)', async () => {
      const mockResponseWithHallucination = [
        {
          title: 'Outfit có chứa ID ảo',
          elegance_score: 8.0,
          ai_reasoning: 'Gợi ý phối đồ',
          item_ids: ['item-1', 'item-2', 'fake-item-999'], // 'fake-item-999' không có trong tủ
        },
      ];

      mockGenerateContent.mockResolvedValueOnce({
        text: JSON.stringify(mockResponseWithHallucination),
      });

      const result = await service.generateOutfitRecommendations(
        'Họp nhóm cafe',
        sampleWardrobe,
      );

      expect(result).toHaveLength(1);
      expect(result[0].item_ids).toEqual(['item-1', 'item-2']);
      expect(result[0].item_ids).not.toContain('fake-item-999');
    });

    it('4. Ném ra InternalServerErrorException khi AI Engine gặp lỗi API', async () => {
      mockGenerateContent.mockRejectedValueOnce(
        new Error('Gemini API Rate Limit Exceeded'),
      );

      await expect(
        service.generateOutfitRecommendations('Đi tiệc tối', sampleWardrobe),
      ).rejects.toThrow(InternalServerErrorException);
    });
  });
});
