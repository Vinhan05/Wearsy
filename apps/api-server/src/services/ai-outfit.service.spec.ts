import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';
import { AiOutfitService, WardrobeItemDto } from './ai-outfit.service';

jest.mock('axios');
const mockedAxios = axios as jest.Mocked<typeof axios>;

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
      get: jest.fn().mockImplementation((key: string, defaultValue?: string) => {
        if (key === 'AI_ORCHESTRATOR_URL') return 'http://127.0.0.1:8000';
        return defaultValue || '';
      }),
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
      expect(mockedAxios.post).not.toHaveBeenCalled();
    });

    it('2. Trả về danh sách bộ outfit hợp lệ được AI gợi ý', async () => {
      mockedAxios.post.mockResolvedValueOnce({
        data: {
          title: 'Trang phục Thuyết trình Thanh lịch',
          elegance_score: 9.5,
          color_score: 9.0,
          reply: 'Áo sơ mi kết hợp quần âu đen mang lại vẻ lịch sự.',
          selected_item_ids: ['item-1', 'item-2', 'item-3'],
        },
      });

      const result = await service.generateOutfitRecommendations(
        'Đi thuyết trình đồ án',
        sampleWardrobe,
      );

      expect(result).toHaveLength(1);
      expect(result[0].title).toBe('Trang phục Thuyết trình Thanh lịch');
      expect(result[0].item_ids).toEqual(['item-1', 'item-2', 'item-3']);
      expect(mockedAxios.post).toHaveBeenCalledTimes(1);
    });

    it('3. Lọc bỏ các ID không hợp lệ (Chống AI Hallucination)', async () => {
      mockedAxios.post.mockResolvedValueOnce({
        data: {
          title: 'Outfit có chứa ID ảo',
          elegance_score: 8.0,
          color_score: 8.5,
          reply: 'Gợi ý phối đồ',
          selected_item_ids: ['item-1', 'item-2', 'fake-item-999'],
        },
      });

      const result = await service.generateOutfitRecommendations(
        'Họp nhóm cafe',
        sampleWardrobe,
      );

      expect(result).toHaveLength(1);
      expect(result[0].item_ids).toEqual(['item-1', 'item-2']);
      expect(result[0].item_ids).not.toContain('fake-item-999');
    });

    it('4. Tự động chuyển sang smart fallback heuristic khi AI Orchestrator ngoại tuyến', async () => {
      mockedAxios.post.mockRejectedValueOnce(
        new Error('Connection refused to AI Orchestrator'),
      );

      const result = await service.generateOutfitRecommendations(
        'Đi tiệc tối',
        sampleWardrobe,
      );

      expect(result).toHaveLength(1);
      expect(result[0].title).toContain('Đi tiệc tối');
      expect(result[0].selected_item_ids.length).toBeGreaterThan(0);
    });
  });
});
