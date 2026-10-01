import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../wardrobe/models/wardrobe_item_model.dart';
import '../models/outfit_model.dart';
import '../providers/outfit_provider.dart';
import '../widgets/layering_canvas_2d_widget.dart';
import '../widgets/smart_fit_card.dart';

class OutfitDetailScreen extends StatefulWidget {
  final OutfitModel outfit;
  const OutfitDetailScreen({super.key, required this.outfit});

  @override
  State<OutfitDetailScreen> createState() => _OutfitDetailScreenState();
}

class _OutfitDetailScreenState extends State<OutfitDetailScreen> {
  // 0: Khung phối đồ 2D (Layering Canvas), 1: Ảnh Lookbook phong cách
  int _viewMode = 0;

  late double _heightCm;
  late double _weightKg;
  late String _gender;
  WardrobeItemModel? _highlightedItem;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final bm = user?.bodyMeasurements;

    final rawH = (bm?['height'] as num?)?.toDouble() ?? 172.0;
    final rawW = (bm?['weight'] as num?)?.toDouble() ?? 65.0;

    _heightCm = rawH > 50 ? rawH : 165.0;
    _weightKg = rawW > 20 ? rawW : 55.0;

    final fullName = user?.fullName.toLowerCase() ?? '';
    final email = user?.email.toLowerCase() ?? '';
    if (fullName.contains('ngọc') ||
        fullName.contains('thảo') ||
        fullName.contains('lan') ||
        email.contains('female')) {
      _gender = 'Nữ';
    } else {
      _gender = 'Nam';
    }
  }

  void _onMeasurementsChanged(double newH, double newW) {
    setState(() {
      _heightCm = newH;
      _weightKg = newW;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✨ Đã cập nhật thể trạng: ${_heightCm.toInt()}cm, ${_weightKg.toInt()}kg! Layering Canvas & Smart Fit đã tự động thích ứng.',
          style: GoogleFonts.inter(fontSize: 12),
        ),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OutfitProvider>(context);
    final items = provider.getItemsForOutfit(widget.outfit);

    // Lấy trạng thái yêu thích mới nhất
    final currentOutfit = provider.outfits.firstWhere(
      (o) => o.id == widget.outfit.id,
      orElse: () => widget.outfit,
    );

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        title: Text(
          'Chi Tiết Outfit & Smart Fit',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              currentOutfit.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: currentOutfit.isFavorite
                  ? AppTheme.accentColor
                  : Colors.white,
            ),
            onPressed: () => provider.toggleFavorite(currentOutfit.id),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Thanh chuyển chế độ: 2D Canvas vs Lookbook Photo ─────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModeTab(
                      index: 0,
                      label: '🎨 2D Layering Canvas',
                      isActive: _viewMode == 0,
                    ),
                  ),
                  Expanded(
                    child: _buildModeTab(
                      index: 1,
                      label: '📸 Ảnh Lookbook',
                      isActive: _viewMode == 1,
                    ),
                  ),
                ],
              ),
            ),

            // ─── Phần hiển thị chính: 2D Canvas hoặc Lookbook Image ───────────
            if (_viewMode == 0) ...[
              LayeringCanvas2DWidget(
                items: items,
                heightCm: _heightCm,
                weightKg: _weightKg,
                gender: _gender,
                onItemTap: (item) {
                  setState(() => _highlightedItem = item);
                },
              ),
            ] else ...[
              Container(
                height: 320,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        currentOutfit.coverImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppTheme.darkSurface,
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppTheme.primaryLight,
                            size: 80,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        bottom: 16,
                        right: 16,
                        child: Text(
                          currentOutfit.name,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ─── THẺ TƯ VẤN SMART FIT (DƯỚI KHUNG CANVAS) ─────────────────────
            SmartFitCard(
              outfit: currentOutfit,
              currentHeightCm: _heightCm,
              currentWeightKg: _weightKg,
              gender: _gender,
              onMeasurementsChanged: _onMeasurementsChanged,
            ),

            // ─── Thông tin Outfit & Lý do Stylist ────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology_rounded,
                            color: AppTheme.primaryLight, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Lý Do Phối Đồ Của Stylist AI',
                          style: GoogleFonts.outfit(
                            color: AppTheme.primaryLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentOutfit.aiReason,
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.wb_sunny_outlined,
                            color: AppTheme.warningColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Thời tiết phù hợp: ',
                          style: GoogleFonts.inter(
                              color: Colors.white60, fontSize: 12),
                        ),
                        Text(
                          currentOutfit.weatherSuitable.join(' · '),
                          style: GoogleFonts.inter(
                            color: AppTheme.warningColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ─── Danh sách các món đồ chi tiết theo từng tầng Layer ───────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Các Món Đồ Phối Lớp (${items.length} món)',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Z-Index 1 ➔ 4',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.primaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    _buildItemsFromIds(currentOutfit.itemIds)
                  else
                    ...items.map(
                      (item) => _DetailedItemRow(
                        item: item,
                        isHighlighted: _highlightedItem?.id == item.id,
                        onTap: () {
                          setState(() {
                            _highlightedItem =
                                _highlightedItem?.id == item.id ? null : item;
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),

            // ─── Nút hành động chính ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                    shadowColor: AppTheme.primaryColor.withOpacity(0.5),
                  ),
                  icon: const Icon(Icons.check_circle_rounded,
                      color: Colors.white),
                  label: Text(
                    'Mặc Outfit Này Hôm Nay',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.auto_awesome,
                                color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '✨ Tuyệt vời! Bạn đã chọn mặc "${currentOutfit.name}" cho hôm nay!',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: AppTheme.darkCard,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppTheme.primaryLight),
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withOpacity(0.15)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: Text(
                  'Chia Sẻ Phong Cách Này',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('🔗 Đã sao chép liên kết chia sẻ bộ phối đồ!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required int index,
    required String label,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _viewMode = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: isActive ? Colors.white : Colors.white60,
              fontSize: 12.5,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemsFromIds(List<String> itemIds) {
    return Column(
      children: itemIds
          .map((id) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.checkroom_rounded,
                        color: AppTheme.primaryLight, size: 20),
                    const SizedBox(width: 12),
                    Text('Món đồ #$id',
                        style: GoogleFonts.inter(color: Colors.white)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _DetailedItemRow extends StatelessWidget {
  final WardrobeItemModel item;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _DetailedItemRow({
    required this.item,
    required this.isHighlighted,
    required this.onTap,
  });

  String _getLayerBadge(int layerOrder) {
    switch (layerOrder) {
      case 1:
        return 'Lớp 1: Nền (Base)';
      case 2:
        return 'Lớp 2: Khoác ngoài (Outer)';
      case 3:
        return 'Lớp 3: Giày (Shoes)';
      case 4:
        return 'Lớp 4: Phụ kiện (Acc)';
      default:
        return 'Layer $layerOrder';
    }
  }

  Color _getLayerColor(int layerOrder) {
    switch (layerOrder) {
      case 1:
        return AppTheme.primaryLight;
      case 2:
        return AppTheme.accentColor;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.tealAccent;
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    final layerColor = _getLayerColor(item.layerOrder);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted
                ? AppTheme.primaryLight
                : Colors.white.withOpacity(0.06),
            width: isHighlighted ? 1.8 : 1.0,
          ),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: AppTheme.primaryLight.withOpacity(0.2),
                    blurRadius: 10,
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 60,
                  height: 60,
                  color: AppTheme.darkSurface,
                  child: Center(
                    child: Text(item.category.icon,
                        style: const TextStyle(fontSize: 24)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: layerColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: layerColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          _getLayerBadge(item.layerOrder),
                          style: GoogleFonts.inter(
                            color: layerColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• ${item.color}',
                        style: GoogleFonts.inter(
                            color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.name,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.brand} • ${item.category.displayName}',
                    style:
                        GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }
}
