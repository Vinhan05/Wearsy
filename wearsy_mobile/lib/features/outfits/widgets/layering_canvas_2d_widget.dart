import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/smart_fit_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../wardrobe/models/wardrobe_item_model.dart';

class LayeringCanvas2DWidget extends StatefulWidget {
  final List<WardrobeItemModel> items;
  final double heightCm;
  final double weightKg;
  final String gender;
  final ValueChanged<WardrobeItemModel>? onItemTap;

  const LayeringCanvas2DWidget({
    super.key,
    required this.items,
    this.heightCm = 165.0,
    this.weightKg = 55.0,
    this.gender = 'Nữ',
    this.onItemTap,
  });

  @override
  State<LayeringCanvas2DWidget> createState() => _LayeringCanvas2DWidgetState();
}

class _LayeringCanvas2DWidgetState extends State<LayeringCanvas2DWidget> {
  // Set chứa các ID món đồ đang được hiển thị (cho phép người dùng bấm ẩn/hiện từng lớp)
  final Set<String> _visibleItemIds = {};
  String? _selectedItemId;

  @override
  void initState() {
    super.initState();
    _resetVisibleItems();
  }

  @override
  void didUpdateWidget(covariant LayeringCanvas2DWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _resetVisibleItems();
    }
  }

  void _resetVisibleItems() {
    _visibleItemIds.clear();
    for (final item in widget.items) {
      _visibleItemIds.add(item.id);
    }
  }

  void _toggleItemVisibility(String id) {
    setState(() {
      if (_visibleItemIds.contains(id)) {
        if (_visibleItemIds.length > 1) {
          _visibleItemIds.remove(id);
        }
      } else {
        _visibleItemIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Tính Scale Ratio theo chiều cao người dùng (Chuẩn tham chiếu 165cm)
    final scaleRatio = SmartFitEngine.calculateScaleRatio(widget.heightCm);

    // 2. Phân loại các món đồ theo Layer Order
    final activeItems = widget.items.where((i) => _visibleItemIds.contains(i.id)).toList();

    // Sắp xếp items theo layerOrder tăng dần: 1 (Base) -> 2 (Outer) -> 3 (Shoes) -> 4 (Accessories)
    activeItems.sort((a, b) => a.layerOrder.compareTo(b.layerOrder));

    final baseItems = activeItems.where((i) => i.layerOrder == 1).toList();
    final outerItems = activeItems.where((i) => i.layerOrder == 2).toList();
    final shoeItems = activeItems.where((i) => i.layerOrder == 3).toList();
    final accItems = activeItems.where((i) => i.layerOrder == 4).toList();

    final tops = baseItems.where((i) => i.category == WardrobeCategory.tops).toList();
    final bottoms = baseItems.where((i) => i.category == WardrobeCategory.bottoms).toList();
    final dresses = baseItems.where((i) => i.category == WardrobeCategory.dresses).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Khung Canvas 2D chính ──────────────────────────────────────────
        Container(
          height: 380 * scaleRatio,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const RadialGradient(
              center: Alignment(0, -0.2),
              radius: 1.1,
              colors: [
                Color(0xFF23253B),
                Color(0xFF141522),
                Color(0xFF0C0D15),
              ],
            ),
            border: Border.all(
              color: AppTheme.primaryLight.withOpacity(0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.18),
                blurRadius: 28,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: Stack(
              children: [
                // 1. Background Grid & Stylized Silhouette
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CanvasGridPainter(scaleRatio: scaleRatio),
                  ),
                ),

                // 2. Thước đo chiều cao động bên trái (Height Scale Indicator)
                Positioned(
                  left: 12,
                  top: 16,
                  bottom: 16,
                  child: _buildHeightRuler(scaleRatio),
                ),

                // 3. Huy hiệu Canvas 2D Smart Fit
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.layers_rounded, color: AppTheme.primaryLight, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          'Layering 2D • Scale ${scaleRatio.toStringAsFixed(2)}x',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Các tầng trang phục được sắp xếp theo tỷ lệ cơ thể (Top -> Center -> Bottom)
                Positioned.fill(
                  left: 50,
                  right: 20,
                  top: 20,
                  bottom: 15,
                  child: _buildLayeringMannequinLayout(
                    tops: tops,
                    bottoms: bottoms,
                    dresses: dresses,
                    outerwear: outerItems,
                    shoes: shoeItems,
                    accessories: accItems,
                    scaleRatio: scaleRatio,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ─── Thanh điều khiển bật/tắt từng lớp trang phục (Layer Toggles) ─────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.touch_app_rounded, color: AppTheme.primaryLight, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Tương tác lớp phối đồ (Chạm để bật/tắt lớp):',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: widget.items.map((item) {
                    final isVisible = _visibleItemIds.contains(item.id);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isVisible,
                        showCheckmark: false,
                        avatar: Text(
                          item.category.icon,
                          style: const TextStyle(fontSize: 13),
                        ),
                        label: Text(
                          '${item.name} (${item.category.displayName})',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isVisible ? FontWeight.bold : FontWeight.normal,
                            color: isVisible ? Colors.white : Colors.white54,
                          ),
                        ),
                        backgroundColor: AppTheme.darkCard,
                        selectedColor: AppTheme.primaryColor.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isVisible ? AppTheme.primaryLight : Colors.white12,
                            width: isVisible ? 1.2 : 0.8,
                          ),
                        ),
                        onSelected: (_) => _toggleItemVisibility(item.id),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Thước đo chiều cao động hiển thị trên khung vẽ
  Widget _buildHeightRuler(double scaleRatio) {
    return Container(
      width: 38,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${widget.heightCm.toInt()}\ncm',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: AppTheme.primaryLight,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                final isMajor = index % 2 == 0;
                return Container(
                  height: 1.5,
                  width: isMajor ? 18 : 10,
                  color: isMajor ? Colors.white38 : Colors.white12,
                );
              }),
            ),
          ),
          Text(
            '0',
            style: GoogleFonts.inter(color: Colors.white30, fontSize: 9),
          ),
        ],
      ),
    );
  }

  /// Bố trí các lớp trang phục theo tỷ lệ cơ thể thực tế (Layering 2D Mannequin)
  Widget _buildLayeringMannequinLayout({
    required List<WardrobeItemModel> tops,
    required List<WardrobeItemModel> bottoms,
    required List<WardrobeItemModel> dresses,
    required List<WardrobeItemModel> outerwear,
    required List<WardrobeItemModel> shoes,
    required List<WardrobeItemModel> accessories,
    required double scaleRatio,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // ─── TẦNG 1: LỚP NỀN (ÁO & QUẦN HOẶC ĐẦM) ───────────────────────────
        Positioned(
          top: 15,
          left: 10,
          right: 10,
          bottom: 75,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (dresses.isNotEmpty)
                Expanded(
                  flex: 3,
                  child: _buildItemCard(
                    dresses.first,
                    badgeText: 'Lớp 1: Đầm liền',
                  ),
                )
              else ...[
                if (tops.isNotEmpty)
                  Expanded(
                    flex: 2,
                    child: _buildItemCard(
                      tops.first,
                      badgeText: 'Lớp 1: Áo trong',
                    ),
                  ),
                const SizedBox(height: 6),
                if (bottoms.isNotEmpty)
                  Expanded(
                    flex: 2,
                    child: _buildItemCard(
                      bottoms.first,
                      badgeText: 'Lớp 1: Quần / Chân váy',
                    ),
                  ),
              ],
            ],
          ),
        ),

        // ─── TẦNG 2: ÁO KHOÁC NGOÀI (OUTERWEAR - LAYER ORDER 2) ─────────────
        if (outerwear.isNotEmpty)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            height: 155 * scaleRatio,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: _buildItemCard(
                outerwear.first,
                badgeText: 'Lớp 2: Áo khoác ngoài (Outer)',
                isLayer2Outer: true,
              ),
            ),
          ),

        // ─── TẦNG 3: GIÀY DÉP (SHOES - LAYER ORDER 3) ───────────────────────
        if (shoes.isNotEmpty)
          Positioned(
            bottom: 0,
            child: SizedBox(
              width: 140,
              height: 68,
              child: _buildItemCard(
                shoes.first,
                badgeText: 'Lớp 3: Giày',
                isFootwear: true,
              ),
            ),
          ),

        // ─── TẦNG 4: PHỤ KIỆN (ACCESSORIES - LAYER ORDER 4) ──────────────────
        if (accessories.isNotEmpty)
          Positioned(
            right: 5,
            top: 30,
            width: 85,
            height: 85,
            child: _buildItemCard(
              accessories.first,
              badgeText: 'Phụ kiện',
              isCompact: true,
            ),
          ),
      ],
    );
  }

  Widget _buildItemCard(
    WardrobeItemModel item, {
    required String badgeText,
    bool isLayer2Outer = false,
    bool isFootwear = false,
    bool isCompact = false,
  }) {
    final isSelected = _selectedItemId == item.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedItemId = isSelected ? null : item.id;
        });
        widget.onItemTap?.call(item);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isLayer2Outer
              ? AppTheme.darkCard.withOpacity(0.85)
              : AppTheme.darkSurface.withOpacity(0.75),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryLight
                : isLayer2Outer
                    ? AppTheme.accentColor.withOpacity(0.55)
                    : Colors.white.withOpacity(0.12),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryLight.withOpacity(0.3),
                    blurRadius: 14,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Ảnh item thời trang
              CachedNetworkImage(
                imageUrl: item.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppTheme.darkSurface,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 1.8),
                    ),
                  ),
                ),
                errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.darkSurface,
                  child: Center(
                    child: Text(
                      item.category.icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              ),

              // Gradient che nhẹ để chữ đọc rõ
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.65),
                      ],
                    ),
                  ),
                ),
              ),

              // Badge lớp và tên trang phục
              Positioned(
                left: 6,
                right: 6,
                bottom: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: isLayer2Outer
                            ? AppTheme.accentColor.withOpacity(0.85)
                            : AppTheme.primaryColor.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: isCompact ? 8 : 9,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.name,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: isCompact ? 9.5 : 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Painter vẽ lưới studio nghệ thuật nền Canvas 2D
class _CanvasGridPainter extends CustomPainter {
  final double scaleRatio;
  _CanvasGridPainter({required this.scaleRatio});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.035)
      ..strokeWidth = 1.0;

    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Đường tâm đối xứng thẳng đứng
    final centerPaint = Paint()
      ..color = AppTheme.primaryLight.withOpacity(0.08)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width / 2 + 15, 10),
      Offset(size.width / 2 + 15, size.height - 10),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CanvasGridPainter oldDelegate) =>
      oldDelegate.scaleRatio != scaleRatio;
}
