import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WardrobeController } from './wardrobe.controller';
import { WardrobeItemEntity } from './entities/wardrobe-item.entity';
import { CategoryEntity } from './entities/category.entity';
import { CloudinaryModule } from '../cloudinary/cloudinary.module';
import { WardrobeScannerService } from './services/wardrobe-scanner.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([WardrobeItemEntity, CategoryEntity]),
    CloudinaryModule,
  ],
  controllers: [WardrobeController],
  providers: [WardrobeScannerService],
  exports: [TypeOrmModule, WardrobeScannerService],
})
export class WardrobeModule {}
