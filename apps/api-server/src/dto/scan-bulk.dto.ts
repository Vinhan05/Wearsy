import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsOptional,
  IsBoolean,
  IsArray,
  ValidateNested,
  IsNumber,
  IsIn,
} from 'class-validator';
import { Type, Transform } from 'class-transformer';

export class ScanBulkBodyDto {
  @ApiPropertyOptional({
    description: 'UUID của người dùng (tùy chọn để lưu thẳng vào DB)',
    example: '123e4567-e89b-12d3-a456-426614174000',
  })
  @IsString()
  @IsOptional()
  userId?: string;

  @ApiPropertyOptional({
    description:
      'Tự động lưu các món nhận diện được vào bảng wardrobe_items ngay lập tức',
    example: false,
    default: false,
  })
  @IsOptional()
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean()
  saveToCloset?: boolean;
}

export class DetectedItemDto {
  @ApiProperty({
    description: 'Tên trang phục được AI đề xuất',
    example: 'Áo thun oversize trắng',
  })
  @IsString()
  name: string;

  @ApiProperty({
    description:
      'Mã danh mục chính (TOPS, BOTTOMS, OUTERWEAR, FOOTWEAR, ACCESSORIES)',
    example: 'TOPS',
    enum: ['TOPS', 'BOTTOMS', 'OUTERWEAR', 'FOOTWEAR', 'ACCESSORIES'],
  })
  @IsIn(['TOPS', 'BOTTOMS', 'OUTERWEAR', 'FOOTWEAR', 'ACCESSORIES'])
  categoryCode: 'TOPS' | 'BOTTOMS' | 'OUTERWEAR' | 'FOOTWEAR' | 'ACCESSORIES';

  @ApiProperty({
    description: 'ID danh mục tương ứng trong database',
    example: 1,
  })
  @IsNumber()
  categoryId: number;

  @ApiProperty({
    description: 'Tên danh mục hiển thị',
    example: 'Áo (Tops)',
  })
  @IsString()
  categoryName: string;

  @ApiProperty({
    description: 'Phân loại chi tiết của trang phục',
    example: 'Áo thun',
  })
  @IsString()
  subCategory: string;

  @ApiProperty({
    description: 'Màu sắc chủ đạo bằng Tiếng Việt',
    example: 'Trắng',
  })
  @IsString()
  primaryColor: string;

  @ApiProperty({
    description:
      'Tọa độ khung nhận diện 2D chuẩn hóa [ymin, xmin, ymax, xmax] trong thang đo 0-1000',
    example: [120, 45, 520, 210],
    type: [Number],
  })
  @IsArray()
  box2d: [number, number, number, number];

  @ApiProperty({
    description: 'Độ tin cậy của AI (0.0 -> 1.0)',
    example: 0.95,
  })
  @IsNumber()
  confidence: number;

  @ApiProperty({
    description: 'Mùa thích hợp',
    example: 'ALL',
    enum: ['SPRING', 'SUMMER', 'AUTUMN', 'WINTER', 'ALL'],
  })
  @IsString()
  season: string;

  @ApiProperty({
    description: 'Nhãn phong cách thời trang gợi ý',
    example: ['Casual', 'Minimalism'],
    type: [String],
  })
  @IsArray()
  styleTags: string[];
}

export class ScanBulkSummaryDto {
  @ApiProperty({ description: 'Tổng số áo nhận diện được', example: 5 })
  topsCount: number;

  @ApiProperty({ description: 'Tổng số quần & váy nhận diện được', example: 3 })
  bottomsCount: number;

  @ApiProperty({
    description: 'Tổng số áo khoác ngoài nhận diện được',
    example: 2,
  })
  outerwearCount: number;

  @ApiProperty({ description: 'Tổng số giày dép nhận diện được', example: 0 })
  footwearCount: number;

  @ApiProperty({ description: 'Tổng số phụ kiện nhận diện được', example: 1 })
  accessoriesCount: number;

  @ApiProperty({
    description:
      'Thống kê chi tiết theo từng loại phụ (Áo sơ mi, Jeans, Hoodie, ...)',
    example: { 'Áo thun': 3, 'Áo sơ mi': 2, 'Quần jeans': 3, 'Áo blazer': 2 },
  })
  bySubCategory: Record<string, number>;
}

export class ScanBulkResponseDto {
  @ApiProperty({ description: 'Trạng thái xử lý', example: true })
  success: boolean;

  @ApiProperty({
    description: 'Thông báo kết quả',
    example: 'Quét và nhận diện thành công 11 món đồ trong tủ đồ!',
  })
  message: string;

  @ApiProperty({
    description: 'Đường dẫn ảnh gốc lưu trữ trên Cloudinary (nếu khả dụng)',
    example: 'https://res.cloudinary.com/.../wardrobe_rack.jpg',
  })
  imageUrl: string;

  @ApiProperty({ description: 'Tổng số món đồ được AI phát hiện', example: 11 })
  totalDetected: number;

  @ApiProperty({
    description: 'Tổng kết thống kê số lượng theo nhóm danh mục',
    type: ScanBulkSummaryDto,
  })
  summary: ScanBulkSummaryDto;

  @ApiProperty({
    description: 'Danh sách chi tiết từng món đồ được định vị trên ảnh',
    type: [DetectedItemDto],
  })
  items: DetectedItemDto[];

  @ApiPropertyOptional({
    description:
      'Số lượng đồ đã được tự động lưu vào tủ đồ (nếu bật saveToCloset)',
    example: 11,
  })
  savedItemsCount?: number;
}

export class BulkCommitItemDto {
  @ApiProperty({ example: 'Áo thun oversize trắng' })
  @IsString()
  name: string;

  @ApiProperty({ example: 1 })
  @IsNumber()
  categoryId: number;

  @ApiProperty({ example: 'Trắng' })
  @IsString()
  primaryColor: string;

  @ApiPropertyOptional({ example: ['Đen'], default: [] })
  @IsOptional()
  @IsArray()
  subColors?: string[];

  @ApiPropertyOptional({ example: ['Casual', 'Basic'], default: [] })
  @IsOptional()
  @IsArray()
  styleTags?: string[];

  @ApiPropertyOptional({ example: 'ALL', default: 'ALL' })
  @IsOptional()
  @IsString()
  season?: string;

  @ApiPropertyOptional({ example: 'https://res.cloudinary.com/.../item.jpg' })
  @IsOptional()
  @IsString()
  imageUrl?: string;
}

export class BulkCommitDto {
  @ApiProperty({
    description: 'UUID của người dùng sở hữu tủ đồ',
    example: '123e4567-e89b-12d3-a456-426614174000',
  })
  @IsString()
  userId: string;

  @ApiPropertyOptional({
    description: 'Ảnh gốc góc tủ đồ dùng làm avatar tạm cho các item',
    example: 'https://res.cloudinary.com/.../wardrobe_rack.jpg',
  })
  @IsOptional()
  @IsString()
  sourceImageUrl?: string;

  @ApiProperty({
    description:
      'Danh sách các món đồ người dùng đã kiểm tra và bấm xác nhận thêm',
    type: [BulkCommitItemDto],
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => BulkCommitItemDto)
  items: BulkCommitItemDto[];
}
