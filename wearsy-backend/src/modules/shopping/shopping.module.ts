import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ShoppingCheckLogEntity } from './entities/shopping-check-log.entity';
import { ShoppingService } from './services/shopping.service';
import { ShoppingController } from './shopping.controller';

@Module({
  imports: [TypeOrmModule.forFeature([ShoppingCheckLogEntity])],
  controllers: [ShoppingController],
  providers: [ShoppingService],
  exports: [ShoppingService],
})
export class ShoppingModule {}
