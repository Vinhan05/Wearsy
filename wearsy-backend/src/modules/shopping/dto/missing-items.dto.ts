import { ApiProperty } from '@nestjs/swagger';

export class MissingItemRecommendationDto {
  @ApiProperty({ example: 'Áo Blazer Đen Basic / Oversize' })
  recommended_item_type: string;

  @ApiProperty({ example: 'Outerwear' })
  category: string;

  @ApiProperty({ example: 'Đen' })
  suggested_color: string;

  @ApiProperty({ example: 'HIGH', enum: ['HIGH', 'MEDIUM', 'LOW'] })
  priority: 'HIGH' | 'MEDIUM' | 'LOW';

  @ApiProperty({
    example:
      'Giúp mở khóa thêm 8 outfit công sở sang trọng kết hợp cùng sơ mi trắng và quần tây hiện có.',
  })
  reason: string;

  @ApiProperty({ example: '350.000đ - 750.000đ' })
  estimated_price_range: string;

  @ApiProperty({
    example: [
      'https://shopee.vn/search?keyword=blazer+den+oversize',
      'https://tiktok.com/@wearsy/blazer-tips',
    ],
  })
  reference_links?: string[];
}
