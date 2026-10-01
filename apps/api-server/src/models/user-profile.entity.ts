import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  UpdateDateColumn,
  OneToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { UserEntity } from './user.entity';

@Entity('user_profiles')
export class UserProfileEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid', unique: true })
  @Index({ unique: true })
  user_id: string;

  @OneToOne(() => UserEntity, (user) => user.profile, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: UserEntity;

  @Column({ type: 'jsonb', default: [] })
  preferred_styles: string[];

  @Column({ type: 'jsonb', default: {} })
  color_preferences: Record<string, any>;

  @Column({ type: 'jsonb', default: { tier: 'medium' } })
  budget_range: Record<string, any>;

  @Column({ type: 'jsonb', default: {} })
  body_measurements: Record<string, any>;

  @Column({ type: 'jsonb', default: {} })
  ai_learning_data: Record<string, any>;

  @UpdateDateColumn({ type: 'timestamp with time zone' })
  updated_at: Date;
}
