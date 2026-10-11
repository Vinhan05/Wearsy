import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { ConfigService } from '@nestjs/config';
import { ShoppingService } from './shopping.service';
import { ShoppingCheckLogEntity } from '../models/shopping-check-log.entity';

describe('ShoppingService', () => {
  let service: ShoppingService;
  let repoMock: any;

  beforeEach(async () => {
    repoMock = {
      create: jest.fn((dto) => dto),
      save: jest.fn(async (dto) => ({ id: 'mock-log-id', ...dto })),
      find: jest.fn(async () => []),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ShoppingService,
        {
          provide: getRepositoryToken(ShoppingCheckLogEntity),
          useValue: repoMock,
        },
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn().mockReturnValue('test-api-key'),
          },
        },
      ],
    }).compile();

    service = module.get<ShoppingService>(ShoppingService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should evaluate compatibility with fallback when AI offline', async () => {
    const result = await service.checkCompatibility({
      item_name: 'Áo Blazer Be Hàn Quốc',
      price: 650000,
      category: 'Outerwear',
      color: 'Be',
      wardrobe_items: [
        {
          id: '1',
          name: 'Quần Tây Đen',
          category_name: 'Bottoms',
          primary_color: 'Đen',
        },
      ],
    });

    expect(result).toBeDefined();
    expect(result.compatibility_score).toBeGreaterThanOrEqual(1.0);
    expect(result.matching_items_count).toBeGreaterThanOrEqual(1);
    expect(repoMock.save).toHaveBeenCalled();
  });

  it('should detect duplicate items', async () => {
    const result = await service.checkCompatibility({
      item_name: 'Áo Sơ Mi Trắng',
      price: 300000,
      category: 'Tops',
      color: 'Trắng',
      wardrobe_items: [
        {
          id: '1',
          name: 'Áo Sơ Mi Trắng Lụa',
          category_name: 'Tops',
          primary_color: 'Trắng',
        },
      ],
    });

    expect(result.is_duplicate).toBe(true);
    expect(result.recommendation_status).toContain('ĐÃ CÓ ĐỒ TƯƠNG TỰ');
  });

  it('should return missing items', async () => {
    const missing = await service.getMissingItems([]);
    expect(missing.length).toBeGreaterThan(0);
    expect(missing[0].recommended_item_type).toBeDefined();
  });
});
