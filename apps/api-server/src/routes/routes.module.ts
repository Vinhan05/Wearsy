import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';

// Models (Data Access Layer)
import {
  UserEntity,
  UserProfileEntity,
  CategoryEntity,
  WardrobeItemEntity,
  OutfitEntity,
  OutfitItemEntity,
  ShoppingCheckLogEntity,
} from '../models';

// Controllers (Presentation Layer)
import {
  HealthController,
  AuthController,
  UsersController,
  WardrobeController,
  OutfitsController,
  ShoppingController,
  GamificationController,
  SystemController,
} from '../controllers';

// Services (Business Logic Layer)
import {
  AuthService,
  MailService,
  UsersService,
  WardrobeService,
  WardrobeScannerService,
  AiOutfitService,
  OutfitsService,
  ShoppingService,
  GamificationService,
  CloudinaryService,
  CloudinaryProvider,
  BgRemovalService,
  AiGatewayService,
} from '../services';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      UserEntity,
      UserProfileEntity,
      CategoryEntity,
      WardrobeItemEntity,
      OutfitEntity,
      OutfitItemEntity,
      ShoppingCheckLogEntity,
    ]),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret:
          config.get<string>('JWT_SECRET') ||
          process.env.JWT_SECRET ||
          'wearsy_fallback_secret_2024_super_secure',
        signOptions: { expiresIn: '24h' },
      }),
    }),
  ],
  controllers: [
    HealthController,
    AuthController,
    UsersController,
    WardrobeController,
    OutfitsController,
    ShoppingController,
    GamificationController,
    SystemController,
  ],
  providers: [
    AuthService,
    MailService,
    UsersService,
    WardrobeService,
    WardrobeScannerService,
    AiOutfitService,
    OutfitsService,
    ShoppingService,
    GamificationService,
    CloudinaryService,
    CloudinaryProvider,
    BgRemovalService,
    AiGatewayService,
  ],
  exports: [
    AuthService,
    UsersService,
    WardrobeService,
    WardrobeScannerService,
    AiOutfitService,
    OutfitsService,
    ShoppingService,
    GamificationService,
    CloudinaryService,
    BgRemovalService,
    AiGatewayService,
    JwtModule,
    TypeOrmModule,
  ],
})
export class RoutesModule {}
