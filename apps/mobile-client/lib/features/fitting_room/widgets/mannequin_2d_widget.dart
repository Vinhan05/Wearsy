import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../wardrobe/models/wardrobe_item_model.dart';
import '../../../core/theme/app_theme.dart';

enum MannequinGender { female, male }

class Mannequin2DWidget extends StatelessWidget {
  final MannequinGender gender;
  final WardrobeItemModel? topItem;
  final WardrobeItemModel? bottomItem;
  final WardrobeItemModel? outerwearItem;
  final WardrobeItemModel? shoesItem;
  final WardrobeItemModel? accessoriesItem;
  final Function(WardrobeCategory category)? onSlotTapped;
  final double topOffset;
  final double bottomOffset;
  final double itemScale;

  const Mannequin2DWidget({
    super.key,
    this.gender = MannequinGender.female,
    this.topItem,
    this.bottomItem,
    this.outerwearItem,
    this.shoesItem,
    this.accessoriesItem,
    this.onSlotTapped,
    this.topOffset = 0.0,
    this.bottomOffset = 0.0,
    this.itemScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 420.0;
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 240.0;

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Mannequin Silhouette & Stand
              CustomPaint(
                size: Size(width, height),
                painter: _MannequinPainter(
                  gender: gender,
                  primaryColor: AppTheme.primaryColor,
                  surfaceColor: AppTheme.cardColor,
                ),
              ),

              // 2. Bottoms (Quần / Chân váy)
              if (bottomItem != null)
                Positioned(
                  top: height * 0.44 + bottomOffset,
                  child: _buildItemImage(
                    item: bottomItem!,
                    category: WardrobeCategory.bottoms,
                    width: width * 0.72 * itemScale,
                    height: height * 0.44 * itemScale,
                  ),
                ),

              // 3. Tops (Áo trong)
              if (topItem != null)
                Positioned(
                  top: height * 0.20 + topOffset,
                  child: _buildItemImage(
                    item: topItem!,
                    category: WardrobeCategory.tops,
                    width: width * 0.78 * itemScale,
                    height: height * 0.32 * itemScale,
                  ),
                ),

              // 4. Outerwear (Áo khoác / Blazer ngoài)
              if (outerwearItem != null)
                Positioned(
                  top: height * 0.18 + topOffset,
                  child: _buildItemImage(
                    item: outerwearItem!,
                    category: WardrobeCategory.outerwear,
                    width: width * 0.88 * itemScale,
                    height: height * 0.38 * itemScale,
                  ),
                ),

              // 5. Shoes (Giày)
              if (shoesItem != null)
                Positioned(
                  bottom: height * 0.05,
                  child: _buildItemImage(
                    item: shoesItem!,
                    category: WardrobeCategory.shoes,
                    width: width * 0.55 * itemScale,
                    height: height * 0.14 * itemScale,
                  ),
                ),

              // 6. Accessories (Mũ hoặc túi xách)
              if (accessoriesItem != null)
                Positioned(
                  top: height * 0.06,
                  right: width * 0.12,
                  child: _buildItemImage(
                    item: accessoriesItem!,
                    category: WardrobeCategory.accessories,
                    width: width * 0.35 * itemScale,
                    height: height * 0.16 * itemScale,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemImage({
    required WardrobeItemModel item,
    required WardrobeCategory category,
    required double width,
    required double height,
  }) {
    return GestureDetector(
      onTap: () => onSlotTapped?.call(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: width,
        height: height,
        child: CachedNetworkImage(
          imageUrl: item.imageUrl,
          fit: BoxFit.contain,
          placeholder: (_, __) => const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (_, __, ___) => const Icon(
            Icons.checkroom_rounded,
            size: 32,
            color: Colors.black26,
          ),
        ),
      ),
    );
  }
}

class _MannequinPainter extends CustomPainter {
  final MannequinGender gender;
  final Color primaryColor;
  final Color surfaceColor;

  _MannequinPainter({
    required this.gender,
    required this.primaryColor,
    required this.surfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerX = w / 2;

    // Gradient bóng mờ cho ma-nơ-canh chuẩn thời trang cao cấp
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          primaryColor.withOpacity(0.18),
          primaryColor.withOpacity(0.08),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = primaryColor.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 1. Đế đứng Ma-nơ-canh (Podium Stand)
    final podiumPaint = Paint()
      ..color = primaryColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, h * 0.94),
        width: w * 0.55,
        height: 18,
      ),
      podiumPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, h * 0.94),
        width: w * 0.55,
        height: 18,
      ),
      outlinePaint..strokeWidth = 1.0,
    );

    // Trục đỡ kim loại
    canvas.drawLine(
      Offset(centerX, h * 0.88),
      Offset(centerX, h * 0.94),
      Paint()
        ..color = primaryColor.withOpacity(0.4)
        ..strokeWidth = 3,
    );

    // 2. Đầu Ma-nơ-canh (Minimalist Oval Head)
    final headRect = Rect.fromCenter(
      center: Offset(centerX, h * 0.10),
      width: w * 0.18,
      height: h * 0.11,
    );
    canvas.drawOval(headRect, bodyPaint);
    canvas.drawOval(headRect, outlinePaint);

    // Cổ
    final neckPath = Path();
    neckPath.moveTo(centerX - w * 0.04, h * 0.15);
    neckPath.lineTo(centerX + w * 0.04, h * 0.15);
    neckPath.lineTo(centerX + w * 0.05, h * 0.19);
    neckPath.lineTo(centerX - w * 0.05, h * 0.19);
    neckPath.close();
    canvas.drawPath(neckPath, bodyPaint);
    canvas.drawPath(neckPath, outlinePaint);

    // 3. Thân người (Torso & Hips)
    final bodyPath = Path();
    if (gender == MannequinGender.female) {
      // Dáng Nữ (vai mềm, eo thon, hông nở)
      bodyPath.moveTo(centerX - w * 0.22, h * 0.21); // Vai trái
      bodyPath.quadraticBezierTo(centerX, h * 0.19, centerX + w * 0.22, h * 0.21); // Vai phải
      bodyPath.quadraticBezierTo(centerX + w * 0.23, h * 0.28, centerX + w * 0.19, h * 0.32); // Ngực phải
      bodyPath.quadraticBezierTo(centerX + w * 0.14, h * 0.38, centerX + w * 0.13, h * 0.42); // Eo phải
      bodyPath.quadraticBezierTo(centerX + w * 0.21, h * 0.48, centerX + w * 0.20, h * 0.55); // Hông phải
      // Đùi & Chân phải
      bodyPath.lineTo(centerX + w * 0.10, h * 0.88);
      bodyPath.lineTo(centerX + w * 0.03, h * 0.88);
      // Giữa hai chân
      bodyPath.lineTo(centerX, h * 0.58);
      // Đùi & Chân trái
      bodyPath.lineTo(centerX - w * 0.03, h * 0.88);
      bodyPath.lineTo(centerX - w * 0.10, h * 0.88);
      bodyPath.lineTo(centerX - w * 0.20, h * 0.55); // Hông trái
      bodyPath.quadraticBezierTo(centerX - w * 0.14, h * 0.38, centerX - w * 0.13, h * 0.42); // Eo trái
      bodyPath.quadraticBezierTo(centerX - w * 0.23, h * 0.28, centerX - w * 0.22, h * 0.21); // Vai trái
    } else {
      // Dáng Nam (vai rộng, ngực vạm vỡ, thân chữ V)
      bodyPath.moveTo(centerX - w * 0.28, h * 0.21); // Vai trái rộng
      bodyPath.quadraticBezierTo(centerX, h * 0.19, centerX + w * 0.28, h * 0.21); // Vai phải rộng
      bodyPath.lineTo(centerX + w * 0.23, h * 0.35); // Ngực phải
      bodyPath.lineTo(centerX + w * 0.18, h * 0.46); // Eo phải
      bodyPath.lineTo(centerX + w * 0.19, h * 0.55); // Hông phải
      // Đùi & Chân phải
      bodyPath.lineTo(centerX + w * 0.12, h * 0.88);
      bodyPath.lineTo(centerX + w * 0.04, h * 0.88);
      // Giữa hai chân
      bodyPath.lineTo(centerX, h * 0.58);
      // Đùi & Chân trái
      bodyPath.lineTo(centerX - w * 0.04, h * 0.88);
      bodyPath.lineTo(centerX - w * 0.12, h * 0.88);
      bodyPath.lineTo(centerX - w * 0.19, h * 0.55); // Hông trái
      bodyPath.lineTo(centerX - w * 0.18, h * 0.46); // Eo trái
      bodyPath.lineTo(centerX - w * 0.23, h * 0.35); // Ngực trái
      bodyPath.close();
    }

    bodyPath.close();
    canvas.drawPath(bodyPath, bodyPaint);
    canvas.drawPath(bodyPath, outlinePaint);

    // Cánh tay thời trang buông nhẹ
    final armPaint = Paint()
      ..color = primaryColor.withOpacity(0.12)
      ..style = PaintingStyle.fill;
    // Tay trái
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - w * 0.32, h * 0.24, w * 0.07, h * 0.30),
        const Radius.circular(10),
      ),
      armPaint,
    );
    // Tay phải
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + w * 0.25, h * 0.24, w * 0.07, h * 0.30),
        const Radius.circular(10),
      ),
      armPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MannequinPainter oldDelegate) {
    return oldDelegate.gender != gender ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.surfaceColor != surfaceColor;
  }
}
