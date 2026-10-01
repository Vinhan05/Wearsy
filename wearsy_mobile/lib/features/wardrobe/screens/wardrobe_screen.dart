import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/wardrobe_item_model.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/wardrobe_provider.dart';
import 'add_item_screen.dart';
import 'item_detail_screen.dart';
import '../../shopping/screens/smart_shopping_screen.dart';

class WardrobeScreen extends StatelessWidget {
  const WardrobeScreen({super.key});

  static void showAddOptionsModal(BuildContext context, {VoidCallback? onSelect}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chọn Phương Thức Nhập Đồ',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Option 1: Chụp ảnh từ Camera
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    onSelect?.call();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddItemScreen(initialMode: 'camera'),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.25),
                          const Color(0xFF8B5CF6).withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryLight.withOpacity(0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chụp ảnh từ Camera',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Chụp trực tiếp trang phục thật của bạn, AI sẽ tự động phân tích.',
                                style: GoogleFonts.inter(
                                  color: AppTheme.darkTextSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: Colors.white54),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Option 2: Chọn từ Thư viện
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    onSelect?.call();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddItemScreen(initialMode: 'gallery'),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.photo_library_rounded,
                              color: AppTheme.primaryLight, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chọn ảnh từ Thư viện',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tải ảnh quần áo có sẵn từ bộ sưu tập điện thoại của bạn.',
                                style: GoogleFonts.inter(
                                  color: AppTheme.darkTextSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: Colors.white54),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Option 3: Dán link mua sắm (Smart Shopping)
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    onSelect?.call();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SmartShoppingScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B6B).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.shopping_bag_rounded,
                              color: Color(0xFFFF6B6B), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dán link mua sắm (Smart Shopping)',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Dán link Shopee, TikTok, Zara... để AI kiểm tra tương thích trước khi mua.',
                                style: GoogleFonts.inter(
                                  color: AppTheme.darkTextSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: Colors.white54),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const _WardrobeBody();
  }
}

class _WardrobeBody extends StatelessWidget {
  const _WardrobeBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildCategoryFilter(context),
            Expanded(child: _buildGrid(context)),
          ],
        ),
      ),
      floatingActionButton: _buildAddFAB(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final provider = Provider.of<WardrobeProvider>(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tủ Đồ Kỹ Thuật Số',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${provider.allItems.length} món đồ • Được quản lý bởi AI',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.darkTextSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          InkWell(
            onTap: () => WardrobeScreen.showAddOptionsModal(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    Color(0xFF8B5CF6),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Thêm Đồ',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context) {
    final provider = Provider.of<WardrobeProvider>(context);
    final categories = [null, ...WardrobeCategory.values];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = provider.selectedCategory == cat;
          final label = cat == null ? 'Tất cả' : cat.displayName;
          final icon = cat == null ? '✨' : cat.icon;
          final count = cat == null
              ? provider.allItems.length
              : (provider.itemCountByCategory[cat] ?? 0);

          return GestureDetector(
            onTap: () => provider.setCategory(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : AppTheme.darkCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    '$label ($count)',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : AppTheme.darkTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final provider = Provider.of<WardrobeProvider>(context);

    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryLight),
      );
    }

    final items = provider.filteredItems;
    if (items.isEmpty) {
      final isTotallyEmpty = provider.allItems.isEmpty;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.25)),
                ),
                child: const Icon(
                  Icons.checkroom_outlined,
                  color: AppTheme.primaryLight,
                  size: 46,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isTotallyEmpty
                    ? 'Tủ đồ của bạn đang trống'
                    : 'Chưa có đồ trong danh mục này',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isTotallyEmpty
                    ? 'Tài khoản mới bắt đầu với tủ đồ trống. Hãy thêm món đồ đầu tiên bằng cách chụp ảnh hoặc tải ảnh lên để AI bắt đầu phối đồ cho bạn!'
                    : 'Thử chuyển sang danh mục khác hoặc thêm đồ mới vào danh mục này.',
                style: GoogleFonts.inter(
                  color: AppTheme.darkTextSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (isTotallyEmpty) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.add_a_photo_rounded, size: 20),
                  label: Text('Thêm trang phục ngay',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddItemScreen(),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _WardrobeCard(item: items[index]),
    );
  }

  Widget _buildAddFAB(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'wardrobe_add_item_fab',
      onPressed: () => WardrobeScreen.showAddOptionsModal(context),
      backgroundColor: AppTheme.primaryColor,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: Text(
        'Thêm Đồ',
        style: GoogleFonts.outfit(
            color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _WardrobeCard extends StatelessWidget {
  final WardrobeItemModel item;
  const _WardrobeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ItemDetailScreen(item: item),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    item.imageUrl.startsWith('http')
                        ? Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppTheme.darkSurface,
                              child: const Icon(Icons.checkroom_rounded,
                                  color: AppTheme.primaryLight, size: 40),
                            ),
                          )
                        : Image.file(
                            File(item.imageUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppTheme.darkSurface,
                              child: const Icon(Icons.checkroom_rounded,
                                  color: AppTheme.primaryLight, size: 40),
                            ),
                          ),
                    // AI Score badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome,
                                color: Colors.amber, size: 12),
                            const SizedBox(width: 3),
                            Text(
                              item.aiMatchScore.toStringAsFixed(1),
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Category badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.category.icon,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        item.brand,
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppTheme.primaryLight),
                      ),
                      const Spacer(),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _colorFromName(item.color),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3), width: 1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFromName(String colorName) {
    final lower = colorName.toLowerCase();
    if (lower.contains('trắng') || lower.contains('white')) return Colors.white;
    if (lower.contains('đen') || lower.contains('black')) return Colors.black;
    if (lower.contains('navy') || lower.contains('xanh'))
      return const Color(0xFF1A237E);
    if (lower.contains('be') || lower.contains('kem'))
      return const Color(0xFFF5F0E8);
    if (lower.contains('xám') || lower.contains('gray')) return Colors.grey;
    if (lower.contains('nâu') || lower.contains('brown'))
      return const Color(0xFF795548);
    if (lower.contains('đỏ') || lower.contains('red')) return Colors.red;
    if (lower.contains('vàng') || lower.contains('gold')) return Colors.amber;
    return AppTheme.primaryColor;
  }
}
