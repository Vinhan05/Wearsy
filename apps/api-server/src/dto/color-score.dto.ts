import { IsArray, IsNotEmpty, IsString, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ColorScoreRequestDto {
  @ApiProperty({
    description: 'Danh sách mã màu Hex hoặc tên màu sắc trong outfit',
    example: ['#FFFFFF', '#1E3A8A', '#8B5CF6'],
  })
  @IsArray()
  @IsNotEmpty({ message: 'Danh sách màu không được để trống' })
  colors: string[];

  @ApiPropertyOptional({
    description: 'Dịp mặc (Casual, Office, Dating, Party...)',
    example: 'Office',
  })
  @IsString()
  @IsOptional()
  occasion?: string;
}
