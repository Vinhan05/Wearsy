import { Test, TestingModule } from '@nestjs/testing';
import { ImageSanitizerService } from './image-sanitizer.service';
import * as sharpModule from 'sharp';
const sharp = ((sharpModule as any).default ||
  sharpModule) as typeof sharpModule;

describe('ImageSanitizerService', () => {
  let service: ImageSanitizerService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [ImageSanitizerService],
    }).compile();

    service = module.get<ImageSanitizerService>(ImageSanitizerService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('inspectMetadata', () => {
    it('should correctly report clean image when no EXIF exists', async () => {
      const cleanImage = await sharp({
        create: {
          width: 50,
          height: 50,
          channels: 3,
          background: { r: 255, g: 0, b: 0 },
        },
      })
        .jpeg()
        .toBuffer();

      const metadata = await service.inspectMetadata(cleanImage);
      expect(metadata.hasExif).toBe(false);
      expect(metadata.hasGps).toBe(false);
      expect(metadata.format).toBe('jpeg');
    });

    it('should detect EXIF and GPS tags when present', async () => {
      const baseImage = await sharp({
        create: {
          width: 50,
          height: 50,
          channels: 3,
          background: { r: 0, g: 255, b: 0 },
        },
      })
        .jpeg()
        .toBuffer();

      const imageWithGps = await sharp(baseImage)
        .withMetadata({
          exif: {
            IFD0: {
              Make: 'Apple',
              Model: 'iPhone 15 Pro',
            },
            IFD3: {
              GPSLatitudeRef: 'N',
              GPSLatitude: '10/1 46/1 30/1',
              GPSLongitudeRef: 'E',
              GPSLongitude: '106/1 40/1 20/1',
            },
          },
        })
        .toBuffer();

      const metadata = await service.inspectMetadata(imageWithGps);
      expect(metadata.hasExif).toBe(true);
      expect(metadata.hasGps).toBe(true);
    });
  });

  describe('sanitize & stripMetadata', () => {
    it('should strip 100% EXIF and GPS metadata, complying with ND 13 and GDPR', async () => {
      // 1. Tạo ảnh giả lập chứa thông tin nhạy cảm (GPS, Model điện thoại)
      const baseImage = await sharp({
        create: {
          width: 64,
          height: 64,
          channels: 3,
          background: { r: 50, g: 100, b: 150 },
        },
      })
        .jpeg()
        .toBuffer();

      const rawUserPhoto = await sharp(baseImage)
        .withMetadata({
          exif: {
            IFD0: {
              Make: 'Samsung',
              Model: 'Galaxy S24 Ultra',
              DateTime: '2026:10:13 16:30:00',
            },
            IFD3: {
              GPSLatitudeRef: 'N',
              GPSLatitude: '10/1 46/1 30/1',
              GPSLongitudeRef: 'E',
              GPSLongitude: '106/1 40/1 20/1',
            },
          },
        })
        .toBuffer();

      // Kiểm tra trước khi strip: chắc chắn có EXIF & GPS
      const beforeMeta = await service.inspectMetadata(rawUserPhoto);
      expect(beforeMeta.hasExif).toBe(true);
      expect(beforeMeta.hasGps).toBe(true);

      // 2. Chạy qua ImageSanitizerService
      const result = await service.sanitize(rawUserPhoto);
      expect(result.wasSanitized).toBe(true);
      expect(result.hadExif).toBe(true);
      expect(result.hadGps).toBe(true);

      // 3. Kiểm tra buffer kết quả: hoàn toàn sạch bóng EXIF & GPS
      const afterMeta = await service.inspectMetadata(result.buffer);
      expect(afterMeta.hasExif).toBe(false);
      expect(afterMeta.hasGps).toBe(false);

      // Kiểm tra trực tiếp bằng sharp low-level
      const sharpMeta = await sharp(result.buffer).metadata();
      expect(sharpMeta.exif).toBeUndefined();
    });

    it('should stripMetadata returning clean buffer directly', async () => {
      const baseImage = await sharp({
        create: {
          width: 32,
          height: 32,
          channels: 3,
          background: { r: 200, g: 200, b: 200 },
        },
      })
        .jpeg()
        .toBuffer();

      const imageWithExif = await sharp(baseImage)
        .withMetadata({
          exif: {
            IFD0: {
              Make: 'Sony',
              Model: 'Alpha A7 IV',
            },
          },
        })
        .toBuffer();

      const cleanBuffer = await service.stripMetadata(imageWithExif);
      const afterMeta = await service.inspectMetadata(cleanBuffer);
      expect(afterMeta.hasExif).toBe(false);
    });

    it('should safely handle corrupted non-image buffers without crashing', async () => {
      const corruptedBuffer = Buffer.from('this is not an image');
      const result = await service.sanitize(corruptedBuffer);
      expect(result.wasSanitized).toBe(false);
      expect(result.buffer).toEqual(corruptedBuffer);
    });
  });
});
