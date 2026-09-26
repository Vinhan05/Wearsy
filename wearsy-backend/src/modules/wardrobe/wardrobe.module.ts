import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WardrobeController } from './wardrobe.controller';
import { WardrobeItemEntity } from './entities/wardrobe-item.entity';
import { CategoryEntity } from './entities/category.entity';
import { CloudinaryModule } from '../cloudinary/cloudinary.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([WardrobeItemEntity, CategoryEntity]),
    CloudinaryModule,
  ],
  controllers: [WardrobeController],
  exports: [TypeOrmModule],
})
export class WardrobeModule {}
