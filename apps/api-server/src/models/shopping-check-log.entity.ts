import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index,
} from 'typeorm';

@Entity('shopping_check_logs')
@Index('idx_shopping_logs_user_date', ['user_id', 'created_at'])
export class ShoppingCheckLogEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  @Index()
  user_id: string;

  @Column({ type: 'varchar', length: 150 })
  target_item_name: string;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  target_item_price: number;

  @Column({ type: 'varchar', length: 512, nullable: true })
  target_image_url: string;

  @Column({ type: 'int', default: 0 })
  compatible_item_count: number;

  @Column({ type: 'varchar', length: 20 })
  compatibility_score: string;

  @Column({ type: 'varchar', length: 30 })
  recommendation_status: string;

  @Column({ type: 'jsonb', default: {} })
  analysis_details: Record<string, any>;

  @CreateDateColumn({ type: 'timestamp with time zone' })
  created_at: Date;
}
