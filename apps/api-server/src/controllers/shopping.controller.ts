import {
  Controller,
  Post,
  Get,
  Body,
  Query,
  HttpCode,
  HttpStatus,
  Req,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiQuery } from '@nestjs/swagger';
import { ShoppingService } from '../services/shopping.service';
import { ShoppingCompatibilityCheckDto } from '../dto/shopping-check.dto';

@ApiTags('Smart Shopping Check')
@Controller('shopping')
export class ShoppingController {
  constructor(private readonly shoppingService: ShoppingService) {}

  @Post('compatibility-check')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Đánh giá độ tương thích của món đồ dự định mua với tủ đồ hiện có',
    description:
      'Nhận thông tin món đồ định mua (tên, giá, màu sắc, loại đồ, ảnh) và danh sách tủ đồ để AI Gemini tính điểm tương thích, phát hiện trùng lặp và gợi ý outfit phối hợp.',
  })
  @ApiResponse({
    status: 200,
    description: 'Phân tích độ tương thích & khuyến nghị quyết định mua sắm',
  })
  async checkCompatibility(
    @Body() dto: ShoppingCompatibilityCheckDto,
    @Req() req: any,
  ) {
    const userId = req.user?.id || '00000000-0000-0000-0000-000000000001';
    const result = await this.shoppingService.checkCompatibility(dto, userId);

    return {
      success: true,
      code: 200,
      data: result,
      meta: {
        timestamp: new Date().toISOString(),
      },
    };
  }

  @Get('missing-items')
  @ApiOperation({
    summary: 'Xác định danh sách các món đồ thực sự còn thiếu trong tủ đồ',
    description:
      'Phân tích cơ cấu danh mục và màu sắc của tủ đồ hiện có để gợi ý các món đồ cơ bản cần bổ sung giúp mở khóa thêm nhiều outfit mới.',
  })
  @ApiResponse({
    status: 200,
    description:
      'Danh sách gợi ý các món đồ cơ bản cần bổ sung để tối ưu khả năng mix & match',
  })
  async getMissingItems() {
    const recommendations = await this.shoppingService.getMissingItems([]);
    return {
      success: true,
      code: 200,
      data: recommendations,
      meta: {
        timestamp: new Date().toISOString(),
      },
    };
  }

  @Get('history')
  @ApiOperation({
    summary: 'Lấy lịch sử các lần kiểm tra mua sắm thông minh',
  })
  @ApiQuery({ name: 'limit', required: false, type: Number, example: 20 })
  async getHistory(@Query('limit') limit?: number, @Req() req?: any) {
    const userId = req?.user?.id || '00000000-0000-0000-0000-000000000001';
    const logs = await this.shoppingService.getHistory(
      userId,
      limit ? Number(limit) : 20,
    );
    return {
      success: true,
      code: 200,
      data: logs,
      meta: {
        total: logs.length,
        timestamp: new Date().toISOString(),
      },
    };
  }

  @Get('sample-products')
  @ApiOperation({
    summary: 'Lấy danh sách các sản phẩm mẫu từ các sàn TMĐT để demo nhanh',
  })
  getSampleProducts() {
    const samples = this.shoppingService.getSampleProducts();
    return {
      success: true,
      code: 200,
      data: samples,
      meta: {
        total: samples.length,
        timestamp: new Date().toISOString(),
      },
    };
  }
}
