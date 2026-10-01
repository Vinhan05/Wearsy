import {
  IsString,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsArray,
  IsUrl,
  Min,
  Max,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class WardrobeItemRefDto {
  @ApiProperty({ example: 'item-uuid-1' })
  @IsString()
  @IsNotEmpty()
  id: string;

  @ApiProperty({ example: 'Quần Jeans Xanh Ống Rộng' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiPropertyOptional({ example: 'Bottoms' })
  @IsString()
  @IsOptional()
  category_name?: string;

  @ApiPropertyOptional({ example: 'Xanh Jeans' })
  @IsString()
  @IsOptional()
  primary_color?: string;

  @ApiPropertyOptional({ example: 'https://res.cloudinary.com/demo/image.png' })
  @IsString()
  @IsOptional()
  image_url?: string;

  @ApiPropertyOptional({ example: ['Casual', 'Streetwear'] })
  @IsArray()
  @IsOptional()
  style_tags?: string[];
}

export class ShoppingCompatibilityCheckDto {
  @ApiProperty({
    description: 'Tên hoặc tiêu đề món đồ dự định mua',
    example: 'Áo Blazer Dáng Rộng Phong Cách Hàn Quốc',
  })
  @IsString()
  @IsNotEmpty({ message: 'Tên sản phẩm không được để trống' })
  item_name: string;

  @ApiProperty({
    description: 'Giá tiền sản phẩm (VND)',
    example: 599000,
  })
  @IsNumber({}, { message: 'Giá sản phẩm phải là định dạng số' })
  @Min(0, { message: 'Giá sản phẩm không được âm' })
  price: number;

  @ApiPropertyOptional({
    description: 'Danh mục trang phục (Tops, Bottoms, Outerwear, Shoes, Accessories, etc.)',
    example: 'Outerwear',
  })
  @IsString()
  @IsOptional()
  category?: string;

  @ApiPropertyOptional({
    description: 'Màu sắc chủ đạo',
    example: 'Be / Khaki',
  })
  @IsString()
  @IsOptional()
  color?: string;

  @ApiPropertyOptional({
    description: 'Thương hiệu sản phẩm',
    example: 'Zara Studio',
  })
  @IsString()
  @IsOptional()
  brand?: string;

  @ApiPropertyOptional({
    description: 'Link hình ảnh sản phẩm',
    example: 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea',
  })
  @IsString()
  @IsOptional()
  image_url?: string;

  @ApiPropertyOptional({
    description: 'Đường dẫn sản phẩm Shopee, Lazada, TikTok Shop, Taobao, etc.',
    example: 'https://shopee.vn/product/12345/67890',
  })
  @IsString()
  @IsOptional()
  product_url?: string;

  @ApiPropertyOptional({
    description: 'Danh sách tags phong cách',
    example: ['Smart Casual', 'Công sở', 'Minimalist'],
  })
  @IsArray()
  @IsOptional()
  tags?: string[];

  @ApiPropertyOptional({
    description: 'Sàn thương mại điện tử',
    example: 'Shopee Mall',
  })
  @IsString()
  @IsOptional()
  platform?: string;

  @ApiPropertyOptional({
    description: 'Danh sách món đồ trong tủ đồ hiện tại để đối chiếu phân tích AI',
    type: [WardrobeItemRefDto],
  })
  @IsArray()
  @IsOptional()
  wardrobe_items?: WardrobeItemRefDto[];
}
