import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { getRepositoryToken } from '@nestjs/typeorm';
import {
  BadRequestException,
  InternalServerErrorException,
} from '@nestjs/common';
import { WardrobeScannerService } from './wardrobe-scanner.service';
import { CloudinaryService } from './cloudinary.service';
import { WardrobeItemEntity } from '../models/wardrobe-item.entity';
import { CategoryEntity } from '../models/category.entity';

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

describe('WardrobeScannerService', () => {
  let service: WardrobeScannerService;
  let mockWardrobeItemRepo: any;
  let mockCategoryRepo: any;
  let mockCloudinaryService: any;
  let mockConfigService: any;

  const mockImageFile: Express.Multer.File = {
    fieldname: 'image',
    originalname: 'wardrobe_closet.jpg',
    encoding: '7bit',
    mimetype: 'image/jpeg',
    size: 1024 * 50,
    buffer: Buffer.from('fake-image-bytes-for-closet'),
    stream: null as any,
    destination: '',
    filename: '',
    path: '',
  };

  const sampleCategories: Partial<CategoryEntity>[] = [
    { id: 1, code: 'TOPS', name: 'Áo (Tops)' },
    { id: 2, code: 'BOTTOMS', name: 'Quần & Váy (Bottoms)' },
    { id: 3, code: 'FOOTWEAR', name: 'Giày Dép (Footwear)' },
    { id: 4, code: 'OUTERWEAR', name: 'Áo Khoác (Outerwear)' },
    { id: 5, code: 'ACCESSORIES', name: 'Phụ Kiện (Accessories)' },
  ];

  beforeEach(async () => {
    jest.clearAllMocks();

    mockConfigService = {
      get: jest.fn((key: string, defaultVal?: string) => {
        if (key === 'AI_ENGINE_API_KEY') return 'mock-key';
        if (key === 'GEMINI_MODEL') return 'gemini-1.5-flash';
        return defaultVal;
      }),
    };

    mockCloudinaryService = {
      uploadImage: jest.fn().mockResolvedValue({
        secure_url:
          'https://res.cloudinary.com/wearsy/image/upload/v1/rack.jpg',
      }),
    };

    mockCategoryRepo = {
      find: jest.fn().mockResolvedValue(sampleCategories),
    };

    mockWardrobeItemRepo = {
      create: jest
        .fn()
        .mockImplementation((dto) => ({ id: 'mock-uuid', ...dto })),
      save: jest.fn().mockImplementation((entities) => {
        if (Array.isArray(entities)) {
          return entities.map((e, idx) => ({ id: `uuid-${idx + 1}`, ...e }));
        }
        return { id: 'mock-uuid-single', ...entities };
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        WardrobeScannerService,
        { provide: ConfigService, useValue: mockConfigService },
        { provide: CloudinaryService, useValue: mockCloudinaryService },
        {
          provide: getRepositoryToken(WardrobeItemEntity),
          useValue: mockWardrobeItemRepo,
        },
        {
          provide: getRepositoryToken(CategoryEntity),
          useValue: mockCategoryRepo,
        },
      ],
    }).compile();

    service = module.get<WardrobeScannerService>(WardrobeScannerService);
  });

  it('1. Khởi tạo service thành công', () => {
    expect(service).toBeDefined();
  });

  describe('scanWardrobeImage', () => {
    it('2. Báo lỗi BadRequestException khi không có file hoặc mimetype sai', async () => {
      await expect(service.scanWardrobeImage(null as any)).rejects.toThrow(
        BadRequestException,
      );

      const invalidFile = { ...mockImageFile, mimetype: 'application/pdf' };
      await expect(
        service.scanWardrobeImage(invalidFile as any),
      ).rejects.toThrow(BadRequestException);
    });

    it('3. Quét thành công và đếm chính xác số lượng trang phục theo danh mục', async () => {
      const mockGeminiOutput = {
        items: [
          {
            name: 'Áo thun trắng basic',
            category_code: 'TOPS',
            sub_category: 'Áo thun',
            primary_color: 'Trắng',
            box_2d: [100, 50, 400, 200],
            confidence: 0.95,
            season: 'ALL',
            style_tags: ['Casual', 'Basic'],
          },
          {
            name: 'Áo sơ mi xanh dương',
            category_code: 'TOPS',
            sub_category: 'Áo sơ mi',
            primary_color: 'Xanh dương',
            box_2d: [110, 210, 420, 360],
            confidence: 0.92,
            season: 'SPRING',
            style_tags: ['Office', 'Smart Casual'],
          },
          {
            name: 'Quần jeans xanh đậm',
            category_code: 'BOTTOMS',
            sub_category: 'Quần jeans',
            primary_color: 'Xanh navy',
            box_2d: [450, 50, 900, 200],
            confidence: 0.96,
            season: 'ALL',
            style_tags: ['Denim', 'Casual'],
          },
          {
            name: 'Áo khoác blazer đen',
            category_code: 'OUTERWEAR',
            sub_category: 'Áo blazer',
            primary_color: 'Đen',
            box_2d: [100, 370, 500, 550],
            confidence: 0.94,
            season: 'AUTUMN',
            style_tags: ['Formal', 'Classic'],
          },
        ],
      };

      mockGenerateContent.mockResolvedValueOnce({
        text: JSON.stringify(mockGeminiOutput),
      });

      const result = await service.scanWardrobeImage(mockImageFile);

      expect(result.success).toBe(true);
      expect(result.totalDetected).toBe(4);
      expect(result.imageUrl).toBe(
        'https://res.cloudinary.com/wearsy/image/upload/v1/rack.jpg',
      );

      // Kiểm tra thống kê
      expect(result.summary.topsCount).toBe(2);
      expect(result.summary.bottomsCount).toBe(1);
      expect(result.summary.outerwearCount).toBe(1);
      expect(result.summary.footwearCount).toBe(0);
      expect(result.summary.bySubCategory['Áo thun']).toBe(1);
      expect(result.summary.bySubCategory['Áo sơ mi']).toBe(1);
      expect(result.summary.bySubCategory['Quần jeans']).toBe(1);

      // Kiểm tra ánh xạ danh mục
      expect(result.items[0].categoryId).toBe(1);
      expect(result.items[0].categoryName).toBe('Áo (Tops)');
      expect(result.items[2].categoryId).toBe(2);
      expect(result.items[2].categoryName).toBe('Quần & Váy (Bottoms)');
    });

    it('4. Tự động lưu vào tủ đồ khi saveToCloset=true và có userId', async () => {
      const mockGeminiOutput = {
        items: [
          {
            name: 'Áo thun oversize',
            category_code: 'TOPS',
            sub_category: 'Áo thun',
            primary_color: 'Trắng',
            box_2d: [100, 50, 400, 200],
            confidence: 0.95,
          },
        ],
      };

      mockGenerateContent.mockResolvedValueOnce({
        text: JSON.stringify(mockGeminiOutput),
      });

      const result = await service.scanWardrobeImage(mockImageFile, {
        userId: 'test-user-uuid',
        saveToCloset: true,
      });

      expect(result.savedItemsCount).toBe(1);
      expect(mockWardrobeItemRepo.save).toHaveBeenCalled();
    });

    it('5. Ném ra InternalServerErrorException khi Gemini API gặp sự cố', async () => {
      mockGenerateContent.mockRejectedValueOnce(new Error('AI Engine Timeout'));

      await expect(service.scanWardrobeImage(mockImageFile)).rejects.toThrow(
        InternalServerErrorException,
      );
    });
  });

  describe('commitBulkItems', () => {
    it('6. Báo lỗi BadRequestException khi danh sách items rỗng', async () => {
      await expect(
        service.commitBulkItems({ userId: 'user-1', items: [] }),
      ).rejects.toThrow(BadRequestException);
    });

    it('7. Lưu thành công danh sách đồ đã chỉnh sửa vào tủ đồ', async () => {
      const result = await service.commitBulkItems({
        userId: 'user-1',
        sourceImageUrl: 'https://cdn.wearsy.app/rack.jpg',
        items: [
          {
            name: 'Áo thun trắng',
            categoryId: 1,
            primaryColor: 'Trắng',
            styleTags: ['Casual'],
          },
          {
            name: 'Quần jeans xanh',
            categoryId: 2,
            primaryColor: 'Xanh',
            styleTags: ['Casual'],
          },
        ],
      });

      expect(result.success).toBe(true);
      expect(result.createdCount).toBe(2);
      expect(result.itemIds.length).toBe(2);
      expect(mockWardrobeItemRepo.save).toHaveBeenCalled();
    });
  });
});
