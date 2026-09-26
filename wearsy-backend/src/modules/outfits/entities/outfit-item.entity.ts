import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
  Unique,
} from 'typeorm';
import { OutfitEntity } from './outfit.entity';
import { WardrobeItemEntity } from '../../wardrobe/entities/wardrobe-item.entity';

@Entity('outfit_items')
@Unique('unique_outfit_item', ['outfit_id', 'item_id'])
export class OutfitItemEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  @Index()
  outfit_id: string;

  @ManyToOne(() => OutfitEntity, (outfit) => outfit.items, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'outfit_id' })
  outfit: OutfitEntity;

  @Column({ type: 'uuid' })
  @Index()
  item_id: string;

  @ManyToOne(() => WardrobeItemEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'item_id' })
  item: WardrobeItemEntity;

  @Column({ type: 'int', default: 1 })
  layer_order: number;

  @CreateDateColumn({ type: 'timestamp with time zone' })
  created_at: Date;
}
