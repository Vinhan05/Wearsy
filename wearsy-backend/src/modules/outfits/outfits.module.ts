import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { OutfitEntity } from './entities/outfit.entity';
import { OutfitItemEntity } from './entities/outfit-item.entity';
import { WardrobeItemEntity } from '../wardrobe/entities/wardrobe-item.entity';
import { AiOutfitService } from './services/ai-outfit.service';
import { OutfitsService } from './services/outfits.service';
import { OutfitsController } from './outfits.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      OutfitEntity,
      OutfitItemEntity,
      WardrobeItemEntity,
    ]),
  ],
  controllers: [OutfitsController],
  providers: [AiOutfitService, OutfitsService],
  exports: [AiOutfitService, OutfitsService],
})
export class OutfitsModule {}
