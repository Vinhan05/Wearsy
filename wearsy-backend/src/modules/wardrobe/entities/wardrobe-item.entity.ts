import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index,
} from 'typeorm';

@Entity('wardrobe_items')
export class WardrobeItemEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  @Index()
  user_id: string;

  @Column({ type: 'int' })
  category_id: number;

  @Column({ type: 'varchar', length: 150 })
  name: string;

  @Column({ type: 'varchar', length: 512 })
  image_url: string;

  @Column({ type: 'varchar', length: 512, nullable: true })
  bg_removed_url: string;

  @Column({ type: 'varchar', length: 50 })
  primary_color: string;

  @Column({ type: 'jsonb', default: [] })
  sub_colors: string[];

  @Column({ type: 'jsonb', default: [] })
  style_tags: string[];

  @Column({ type: 'varchar', length: 30, default: 'ALL' })
  season: string;

  @Column({ type: 'decimal', precision: 12, scale: 2, nullable: true })
  purchase_price: number;

  @Column({ type: 'int', default: 0 })
  wear_count: number;

  @Column({ type: 'varchar', length: 20, default: 'COMPLETED' })
  ai_processing_status: string;

  @Column({ type: 'varchar', length: 20, default: 'ACTIVE' })
  status: string;

  @CreateDateColumn({ type: 'timestamp with time zone' })
  created_at: Date;
}
