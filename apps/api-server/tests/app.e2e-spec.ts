import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { RoutesModule } from '../src/routes/routes.module';
import { MailService } from '../src/services/mail.service';
import { ConfigModule } from '@nestjs/config';
import { DataSource } from 'typeorm';
import { getRepositoryToken } from '@nestjs/typeorm';
import {
  UserEntity,
  UserProfileEntity,
  CategoryEntity,
  WardrobeItemEntity,
  OutfitEntity,
  OutfitItemEntity,
  ShoppingCheckLogEntity,
} from '../src/models';

import { HealthController } from '../src/controllers/health.controller';

describe('Auth Integration Tests (e2e)', () => {
  let app: INestApplication;

  const mockMailService = {
    sendOtpEmail: jest.fn().mockResolvedValue({
      success: true,
      messageId: 'mock-msg-id-12345',
    }),
  };

  const mockRepo = {
    findOne: jest.fn(),
    find: jest.fn().mockResolvedValue([]),
    create: jest.fn((dto) => dto),
    save: jest.fn(async (dto) => ({ id: 'mock-id', ...dto })),
    update: jest.fn().mockResolvedValue({ affected: 1 }),
  };

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [ConfigModule.forRoot({ isGlobal: true }), RoutesModule],
      controllers: [HealthController],
    })
      .overrideProvider(MailService)
      .useValue(mockMailService)
      .overrideProvider(DataSource)
      .useValue({
        getRepository: () => mockRepo,
        options: { type: 'postgres' },
      })
      .overrideProvider(getRepositoryToken(UserEntity))
      .useValue(mockRepo)
      .overrideProvider(getRepositoryToken(UserProfileEntity))
      .useValue(mockRepo)
      .overrideProvider(getRepositoryToken(CategoryEntity))
      .useValue(mockRepo)
      .overrideProvider(getRepositoryToken(WardrobeItemEntity))
      .useValue(mockRepo)
      .overrideProvider(getRepositoryToken(OutfitEntity))
      .useValue(mockRepo)
      .overrideProvider(getRepositoryToken(OutfitItemEntity))
      .useValue(mockRepo)
      .overrideProvider(getRepositoryToken(ShoppingCheckLogEntity))
      .useValue(mockRepo)
      .compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        transform: true,
      }),
    );
    await app.init();
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  describe('/auth/send-otp (POST)', () => {
    it('1. Trả về 200 và gửi OTP thành công với email hợp lệ', async () => {
      const response = await request(app.getHttpServer())
        .post('/auth/send-otp')
        .send({
          email: 'test.user@wearsy.app',
          fullName: 'Test User',
        })
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body.message).toContain('test.user@wearsy.app');
      expect(mockMailService.sendOtpEmail).toHaveBeenCalled();
    });

    it('2. Trả về 400 khi email không đúng định dạng', async () => {
      const response = await request(app.getHttpServer())
        .post('/auth/send-otp')
        .send({
          email: 'invalid-email-format',
        })
        .expect(400);

      const msg = Array.isArray(response.body.message)
        ? response.body.message.join(' ')
        : response.body.message;
      expect(msg).toContain('Email');
    });
  });

  describe('/auth/verify-otp (POST)', () => {
    it('1. Trả về 400 khi OTP không chính xác', async () => {
      // Đầu tiên gọi send-otp để có email trong pendingOtps
      await request(app.getHttpServer())
        .post('/auth/send-otp')
        .send({ email: 'verify.test@wearsy.app' })
        .expect(200);

      const response = await request(app.getHttpServer())
        .post('/auth/verify-otp')
        .send({
          email: 'verify.test@wearsy.app',
          otp: '000000',
        })
        .expect(400);

      expect(response.body.message).toContain('Mã OTP không chính xác');
    });

    it('2. Trả về 400 khi email chưa từng yêu cầu gửi OTP', async () => {
      const response = await request(app.getHttpServer())
        .post('/auth/verify-otp')
        .send({
          email: 'unknown@wearsy.app',
          otp: '123456',
        })
        .expect(400);

      expect(response.body.message).toContain(
        'Không tìm thấy yêu cầu xác thực OTP',
      );
    });
  });

  describe('/health (GET)', () => {
    it('1. Trả về status 200 và payload trạng thái dịch vụ (CI/CD Health Check)', async () => {
      const response = await request(app.getHttpServer())
        .get('/health')
        .expect(200);

      expect(response.body).toHaveProperty('status', 'ok');
      expect(response.body).toHaveProperty('service', 'wearsy-backend');
      expect(response.body).toHaveProperty('version', '1.0.0');
      expect(response.body).toHaveProperty('uptime');
      expect(response.body).toHaveProperty('timestamp');
    });
  });
});
