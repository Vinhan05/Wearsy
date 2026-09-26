import 'dart:math' as math;
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

class _LayeringCanvas2DWidgetState extends State<LayeringCanvas2DWidget>
    with SingleTickerProviderStateMixin {
  // Set chứa các ID món đồ đang được hiển thị
  final Set<String> _visibleItemIds = {};
  String? _selectedItemId;

  // Animation controller cho vòng xoay quỹ đạo Neon 60 FPS
  late AnimationController _orbitController;
  bool _showOrbitRings = true;
  bool _showHudCallouts = true;

  @override
  void initState() {
    super.initState();
    _resetVisibleItems();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _orbitController.dispose();
    super.dispose();
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
          height: 390 * scaleRatio,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const RadialGradient(
              center: Alignment(0, -0.2),
              radius: 1.15,
              colors: [
                Color(0xFF23253B),
                Color(0xFF141522),
                Color(0xFF0C0D15),
              ],
            ),
            border: Border.all(
              color: AppTheme.primaryLight.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.22),
                blurRadius: 30,
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

                // 2. Vòng tròn quỹ đạo Neon xoay quanh 60 FPS (Orbit Rings)
                if (_showOrbitRings)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _orbitController,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _NeonOrbitPainter(
                            progress: _orbitController.value,
                            scaleRatio: scaleRatio,
                          ),
                        );
                      },
                    ),
                  ),

                // 3. Thước đo chiều cao động bên trái
                Positioned(
                  left: 10,
                  top: 14,
                  bottom: 14,
                  child: _buildHeightRuler(scaleRatio),
                ),

                // 4. Huy hiệu Canvas 2D Smart Fit
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.layers_rounded, color: AppTheme.primaryLight, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          'Layering 2D • Scale ${scaleRatio.toStringAsFixed(2)}x',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 5. Các tầng trang phục (Top -> Center -> Bottom)
                Positioned.fill(
                  left: 46,
                  right: 14,
                  top: 14,
                  bottom: 12,
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

                // 6. Đường chỉ dẫn Callouts thông số cơ thể (Vai, Eo, Dài)
                if (_showHudCallouts)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _buildHudCallouts(scaleRatio),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ─── Thanh điều khiển Orbit 360° & Chỉ dẫn HUD Callouts ──────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            children: [
              // Toggle Vòng Xoay Neon
              InkWell(
                onTap: () => setState(() => _showOrbitRings = !_showOrbitRings),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _showOrbitRings
                        ? AppTheme.primaryColor.withOpacity(0.35)
                        : AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _showOrbitRings ? AppTheme.primaryLight : Colors.white12,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.rotate_right_rounded,
                        size: 14,
                        color: _showOrbitRings ? AppTheme.primaryLight : Colors.white54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Quỹ đạo 360°',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: _showOrbitRings ? FontWeight.bold : FontWeight.normal,
                          color: _showOrbitRings ? Colors.white : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Toggle Chỉ Dẫn Fit Dáng
              InkWell(
                onTap: () => setState(() => _showHudCallouts = !_showHudCallouts),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _showHudCallouts
                        ? AppTheme.accentColor.withOpacity(0.35)
                        : AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _showHudCallouts ? AppTheme.accentColor : Colors.white12,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.straighten_rounded,
                        size: 14,
                        color: _showHudCallouts ? AppTheme.accentColor : Colors.white54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Chỉ dẫn Fit Dáng',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: _showHudCallouts ? FontWeight.bold : FontWeight.normal,
                          color: _showHudCallouts ? Colors.white : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
    final hasOuter = outerwear.isNotEmpty;
    final hasTop = tops.isNotEmpty;
    final hasDress = dresses.isNotEmpty;
    final hasBottom = bottoms.isNotEmpty;
    final hasShoe = shoes.isNotEmpty;

    return Stack(
      alignment: Alignment.center,
      children: [
        // ─── PHẦN THÂN TRÊN & DƯỚI (Upper Body & Lower Body) ─────────────────
        Positioned(
          top: 10,
          left: 6,
          right: 6,
          bottom: hasShoe ? 72 : 12,
          child: Column(
            children: [
              // 1. Thân trên: Đầm liền HOẶC (Áo trong & Áo khoác ngoài)
              if (hasDress)
                Expanded(
                  flex: 5,
                  child: _buildItemCard(
                    dresses.first,
                    badgeText: 'Đầm liền (Dress)',
                  ),
                )
              else ...[
                // Nửa trên: Áo trong & Áo khoác
                Expanded(
                  flex: 3,
                  child: (hasTop && hasOuter)
                      ? Row(
                          children: [
                            // Áo trong (Base Layer)
                            Expanded(
                              flex: 1,
                              child: _buildItemCard(
                                tops.first,
                                badgeText: 'Lớp 1: Áo trong',
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Áo khoác ngoài (Outer Layer)
                            Expanded(
                              flex: 1,
                              child: _buildItemCard(
                                outerwear.first,
                                badgeText: 'Lớp 2: Khoác ngoài',
                                isLayer2Outer: true,
                              ),
                            ),
                          ],
                        )
                      : (hasOuter
                          ? _buildItemCard(
                              outerwear.first,
                              badgeText: 'Lớp 2: Khoác ngoài',
                              isLayer2Outer: true,
                            )
                          : (hasTop
                              ? _buildItemCard(
                                  tops.first,
                                  badgeText: 'Lớp 1: Áo trong',
                                )
                              : const SizedBox.shrink())),
                ),
                const SizedBox(height: 6),
                // Nửa dưới: Quần / Chân váy
                if (hasBottom)
                  Expanded(
                    flex: 3,
                    child: _buildItemCard(
                      bottoms.first,
                      badgeText: 'Lớp dưới: Quần / Váy',
                    ),
                  ),
              ],
            ],
          ),
        ),

        // ─── TẦNG 3: GIÀY DÉP (SHOES) ────────────────────────────────────────
        if (hasShoe)
          Positioned(
            bottom: 0,
            child: SizedBox(
              width: 145,
              height: 66,
              child: _buildItemCard(
                shoes.first,
                badgeText: 'Lớp 3: Giày',
                isFootwear: true,
              ),
            ),
          ),

        // ─── TẦNG 4: PHỤ KIỆN (ACCESSORIES) ──────────────────────────────────
        if (accessories.isNotEmpty)
          Positioned(
            right: 0,
            top: 15,
            width: 80,
            height: 80,
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
                errorWidget: (_, __, ___) => Container(
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

  /// HUD Callouts hiển thị các điểm đo & thông số vóc dáng gợi ý (Vai, Eo, Chiều dài)
  Widget _buildHudCallouts(double scaleRatio) {
    // Ước tính thông số theo Chiều cao, Cân nặng và Giới tính
    final isMale = widget.gender.toLowerCase().contains('nam') || widget.gender.toLowerCase().contains('male');
    final shoulderEstimate = (widget.heightCm * (isMale ? 0.255 : 0.232)).round();
    final waistEstimate = (widget.weightKg * 1.08 + (isMale ? 16 : 10)).round();
    final topLengthEstimate = (widget.heightCm * 0.385).round();
    final bodyAnalysis = SmartFitEngine.analyzeBody(
      heightCm: widget.heightCm,
      weightKg: widget.weightKg,
      gender: isMale ? 'Nam' : 'Nữ',
    );
    final fitSize = bodyAnalysis.estimatedSize;

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;

        return Stack(
          children: [
            // 1. Callout VAI (Shoulders) - Góc trên bên trái
            Positioned(
              left: 50,
              top: h * 0.16,
              child: _buildCalloutBadge(
                label: 'VAI',
                value: '$shoulderEstimate cm',
                subValue: 'Khuyên dùng $fitSize',
                color: const Color(0xFF00E5FF),
                icon: Icons.accessibility_new_rounded,
                isLeft: true,
              ),
            ),

            // 2. Callout EO (Waist) - Góc giữa bên phải
            Positioned(
              right: 14,
              top: h * 0.44,
              child: _buildCalloutBadge(
                label: 'EO',
                value: '$waistEstimate cm',
                subValue: 'Vừa vặn chuẩn',
                color: const Color(0xFFFF4081),
                icon: Icons.all_inclusive_rounded,
                isLeft: false,
              ),
            ),

            // 3. Callout CHIỀU DÀI ÁO (Length) - Góc dưới bên trái
            Positioned(
              left: 50,
              top: h * 0.65,
              child: _buildCalloutBadge(
                label: 'DÀI ÁO',
                value: '$topLengthEstimate cm',
                subValue: 'Tỷ lệ Scale ${scaleRatio.toStringAsFixed(2)}x',
                color: const Color(0xFFB388FF),
                icon: Icons.straighten_rounded,
                isLeft: true,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCalloutBadge({
    required String label,
    required String value,
    required String subValue,
    required Color color,
    required IconData icon,
    required bool isLeft,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xDD0F101A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.6),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 12),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$label: ',
                    style: GoogleFonts.inter(
                      color: color,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                subValue,
                style: GoogleFonts.inter(
                  color: Colors.white60,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
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

/// Painter vẽ vòng tròn quỹ đạo Neon 3D xoay quanh ma-nơ-canh mượt mà 60 FPS
class _NeonOrbitPainter extends CustomPainter {
  final double progress; // 0.0 -> 1.0
  final double scaleRatio;

  _NeonOrbitPainter({
    required this.progress,
    required this.scaleRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2 + 15;
    final upperCenterY = size.height * 0.28;
    final lowerCenterY = size.height * 0.62;

    // ─── 1. Quỹ đạo Vòng Trên (Upper Neon Orbit Ring - Ngực/Vai) ─────────────
    _drawOrbitRing(
      canvas: canvas,
      center: Offset(centerX, upperCenterY),
      radiusX: size.width * 0.36,
      radiusY: 26 * scaleRatio,
      tiltAngle: -math.pi / 14,
      rotationPhase: progress * 2 * math.pi,
      primaryColor: const Color(0xFF00E5FF),
      secondaryColor: const Color(0xFFB388FF),
      particleRadius: 3.5,
    );

    // ─── 2. Quỹ đạo Vòng Dưới (Lower Neon Orbit Ring - Hông/Đùi) ──────────────
    _drawOrbitRing(
      canvas: canvas,
      center: Offset(centerX, lowerCenterY),
      radiusX: size.width * 0.33,
      radiusY: 22 * scaleRatio,
      tiltAngle: math.pi / 16,
      rotationPhase: (progress + 0.5) * 2 * math.pi,
      primaryColor: const Color(0xFFFF4081),
      secondaryColor: const Color(0xFF00E5FF),
      particleRadius: 3.0,
    );
  }

  void _drawOrbitRing({
    required Canvas canvas,
    required Offset center,
    required double radiusX,
    required double radiusY,
    required double tiltAngle,
    required double rotationPhase,
    required Color primaryColor,
    required Color secondaryColor,
    required double particleRadius,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tiltAngle);

    final rect = Rect.fromCenter(center: Offset.zero, width: radiusX * 2, height: radiusY * 2);

    // Vòng mờ ảo nền (Aura Glow)
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = primaryColor.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawOval(rect, glowPaint);

    // Đường vành elip nét đứt công nghệ (Cyber Dotted Ring)
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        colors: [
          primaryColor.withOpacity(0.1),
          primaryColor.withOpacity(0.85),
          secondaryColor.withOpacity(0.85),
          primaryColor.withOpacity(0.1),
        ],
        transform: GradientRotation(rotationPhase),
      ).createShader(rect);

    canvas.drawOval(rect, ringPaint);

    // Vẽ hạt Photon năng lượng quay quanh quỹ đạo
    final particleAngle = rotationPhase;
    final px = radiusX * math.cos(particleAngle);
    final py = radiusY * math.sin(particleAngle);

    // Quầng sáng photon
    final photonGlowPaint = Paint()
      ..color = primaryColor.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    canvas.drawCircle(Offset(px, py), particleRadius * 2.2, photonGlowPaint);

    // Nhân photon
    final photonCorePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(px, py), particleRadius, photonCorePaint);

    // Hạt đối xứng thứ 2 (Anti-photon)
    final antiAngle = rotationPhase + math.pi;
    final apx = radiusX * math.cos(antiAngle);
    final apy = radiusY * math.sin(antiAngle);

    final antiCorePaint = Paint()..color = secondaryColor;
    canvas.drawCircle(Offset(apx, apy), particleRadius * 0.8, antiCorePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NeonOrbitPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.scaleRatio != scaleRatio;
}
