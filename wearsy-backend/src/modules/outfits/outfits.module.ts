import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { OutfitEntity } from './entities/outfit.entity';
import { OutfitItemEntity } from './entities/outfit-item.entity';
import { AiOutfitService } from './services/ai-outfit.service';

@Module({
  imports: [TypeOrmModule.forFeature([OutfitEntity, OutfitItemEntity])],
  providers: [AiOutfitService],
  exports: [AiOutfitService],
})
export class OutfitsModule {}
