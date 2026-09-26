import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/wardrobe_item_model.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/wardrobe_provider.dart';

class ItemDetailScreen extends StatefulWidget {
  final WardrobeItemModel item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  bool _isFavorited = false;
  late List<String> _tags;
  TextEditingController _customTagController = TextEditingController();

  final List<String> _popularTags = [
    'Smart Casual', 'Công sở', 'Streetwear', 'Tối giản', 'Năng động', 'Dự tiệc', 'Vintage'
  ];

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.item.tags);
    _customTagController = TextEditingController();
  }

  @override
  void dispose() {
    _customTagController.dispose();
    super.dispose();
  }

  void _syncTagsToProvider() {
    final updatedItem = widget.item.copyWith(tags: _tags);
    Provider.of<WardrobeProvider>(context, listen: false).updateItem(updatedItem);
  }

  void _addCustomTag([String? value]) {
    final tagText = (value ?? _customTagController.text).trim();
    if (tagText.isEmpty) return;

    final existingIndex = _tags.indexWhere(
      (t) => t.toLowerCase() == tagText.toLowerCase(),
    );

    if (existingIndex == -1) {
      final popularMatch = _popularTags.firstWhere(
        (p) => p.toLowerCase() == tagText.toLowerCase(),
        orElse: () => '',
      );
      final tagToAdd = popularMatch.isNotEmpty ? popularMatch : tagText;
      setState(() {
        _tags.add(tagToAdd);
      });
      _syncTagsToProvider();
    }
    _customTagController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: CustomScrollView(
        slivers: [
          // Hero Image App Bar
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: AppTheme.darkBackground,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isFavorited
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: _isFavorited ? AppTheme.accentColor : Colors.white,
                  ),
                ),
                onPressed: () => setState(() => _isFavorited = !_isFavorited),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: item.imageUrl.startsWith('http')
                  ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.darkSurface,
                        child: const Icon(Icons.checkroom_rounded,
                            color: AppTheme.primaryLight, size: 80),
                      ),
                    )
                  : Image.file(
                      File(item.imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.darkSurface,
                        child: const Icon(Icons.checkroom_rounded,
                            color: AppTheme.primaryLight, size: 80),
                      ),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Category row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '${item.category.icon} ${item.category.displayName}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppTheme.primaryLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // AI Score
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.auto_awesome_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(height: 2),
                            Text(
                              item.aiMatchScore.toStringAsFixed(1),
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'AI Score',
                              style: GoogleFonts.inter(
                                  color: Colors.white70, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Color & Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Row(
                      children: [
                        _InfoChip(
                          icon: Icons.palette_rounded,
                          label: 'Màu sắc',
                          value: item.color,
                          color: AppTheme.secondaryColor,
                        ),
                        const SizedBox(width: 12),
                        _InfoChip(
                          icon: Icons.category_rounded,
                          label: 'Loại',
                          value: item.category.icon,
                          color: AppTheme.primaryLight,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tags section (Phong cách / Thẻ gợi ý)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Phong cách / Thẻ gợi ý',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.darkTextSecondary,
                              ),
                            ),
                            if (_tags.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.primaryLight.withOpacity(0.4)),
                                ),
                                child: Text(
                                  '${_tags.length} đã chọn',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryLight,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 1. Danh sách các Chip chọn nhanh
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _popularTags.map((tag) {
                            final isSelected = _tags.contains(tag);
                            return FilterChip(
                              label: Text(tag),
                              selected: isSelected,
                              showCheckmark: isSelected,
                              checkmarkColor: Colors.white,
                              selectedColor: AppTheme.primaryColor,
                              backgroundColor: Colors.white.withOpacity(0.05),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.12),
                                ),
                              ),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.darkTextSecondary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    if (!_tags.contains(tag)) _tags.add(tag);
                                  } else {
                                    _tags.remove(tag);
                                  }
                                });
                                _syncTagsToProvider();
                              },
                            );
                          }).toList(),
                        ),

                        // 2. Các thẻ tự nhập (có nút 'X' để xóa)
                        Builder(
                          builder: (_) {
                            final customTags = _tags.where((t) => !_popularTags.contains(t)).toList();
                            if (customTags.isEmpty) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: customTags.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.45),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppTheme.primaryLight.withOpacity(0.7),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.tag_rounded,
                                          size: 14,
                                          color: Colors.white70,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          tag,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () {
                                            setState(() {
                                              _tags.remove(tag);
                                            });
                                            _syncTagsToProvider();
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close_rounded,
                                              size: 13,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 14),

                        // 3. Ô TextField nhập phong cách khác
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 12, right: 8),
                                child: Icon(
                                  Icons.local_offer_outlined,
                                  size: 18,
                                  color: AppTheme.primaryLight,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _customTagController,
                                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (val) => _addCustomTag(val),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: 'Thêm phong cách khác (ví dụ: Đi học, Y2K, Gym...)',
                                    hintStyle: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppTheme.darkTextSecondary.withOpacity(0.6),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                                ),
                                tooltip: 'Thêm phong cách',
                                onPressed: () => _addCustomTag(_customTagController.text),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // AI Outfit Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.auto_fix_high_rounded,
                            color: Colors.white),
                        label: Text(
                          'Phối Outfit Với AI',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '✨ AI đang tìm outfit phù hợp với ${item.name}...',
                                style: GoogleFonts.inter(),
                              ),
                              backgroundColor: AppTheme.primaryColor,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Delete button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentColor,
                        side: BorderSide(
                            color: AppTheme.accentColor.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(
                        'Xóa khỏi tủ đồ',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                      onPressed: () {
                        Provider.of<WardrobeProvider>(context, listen: false).removeItem(item.id);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '🗑️ Đã xóa ${item.name} khỏi tủ đồ',
                              style: GoogleFonts.inter(),
                            ),
                            backgroundColor: AppTheme.accentColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                    color: AppTheme.darkTextSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
