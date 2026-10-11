import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  OneToMany,
  Index,
} from 'typeorm';
import { OutfitItemEntity } from './outfit-item.entity';

@Entity('outfits')
export class OutfitEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  @Index()
  user_id: string;

  @Column({ type: 'varchar', length: 150 })
  title: string;

  @Column({ type: 'varchar', length: 100, nullable: true })
  occasion: string;

  @Column({ type: 'boolean', default: true })
  @Index()
  ai_generated: boolean;

  @Column({ type: 'decimal', precision: 3, scale: 1, nullable: true })
  elegance_score: number;

  @Column({ type: 'text', nullable: true })
  ai_reasoning: string;

  @Column({ type: 'varchar', length: 512, nullable: true })
  image_url: string;

  @Column({ type: 'boolean', default: false })
  @Index()
  is_favorite: boolean;

  @CreateDateColumn({ type: 'timestamp with time zone' })
  created_at: Date;

  @OneToMany(() => OutfitItemEntity, (item) => item.outfit)
  items: OutfitItemEntity[];
}
