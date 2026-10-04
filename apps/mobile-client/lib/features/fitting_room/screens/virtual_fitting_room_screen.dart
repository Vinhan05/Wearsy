import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../wardrobe/models/wardrobe_item_model.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../../outfits/providers/outfit_provider.dart';
import '../../outfits/models/outfit_model.dart';
import '../widgets/mannequin_2d_widget.dart';

class VirtualFittingRoomScreen extends StatefulWidget {
  final WardrobeItemModel? initialProduct;
  final List<WardrobeItemModel>? initialItems;

  const VirtualFittingRoomScreen({
    super.key,
    this.initialProduct,
    this.initialItems,
  });

  @override
  State<VirtualFittingRoomScreen> createState() =>
      _VirtualFittingRoomScreenState();
}

class _VirtualFittingRoomScreenState extends State<VirtualFittingRoomScreen> {
  MannequinGender _gender = MannequinGender.female;

  WardrobeItemModel? _selectedTop;
  WardrobeItemModel? _selectedBottom;
  WardrobeItemModel? _selectedOuterwear;
  WardrobeItemModel? _selectedShoes;
  WardrobeItemModel? _selectedAccessories;

  WardrobeCategory _activeCategory = WardrobeCategory.tops;
  double _itemScale = 1.0;
  double _topOffset = 0.0;
  double _bottomOffset = 0.0;
  bool _showFineTune = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialItems != null && widget.initialItems!.isNotEmpty) {
      for (final item in widget.initialItems!) {
        _equipItem(item);
      }
    } else if (widget.initialProduct != null) {
      _equipItem(widget.initialProduct!);
    }
  }

  void _equipItem(WardrobeItemModel item) {
    setState(() {
      switch (item.category) {
        case WardrobeCategory.tops:
          _selectedTop = _selectedTop?.id == item.id ? null : item;
          break;
        case WardrobeCategory.bottoms:
          _selectedBottom = _selectedBottom?.id == item.id ? null : item;
          break;
        case WardrobeCategory.outerwear:
          _selectedOuterwear = _selectedOuterwear?.id == item.id ? null : item;
          break;
        case WardrobeCategory.shoes:
          _selectedShoes = _selectedShoes?.id == item.id ? null : item;
          break;
        case WardrobeCategory.dresses:
          _selectedTop = _selectedTop?.id == item.id ? null : item;
          _selectedBottom = null; // Váy liền thay thế cả áo và quần
          break;
        case WardrobeCategory.accessories:
          _selectedAccessories =
              _selectedAccessories?.id == item.id ? null : item;
          break;
      }
    });
  }

  void _resetMannequin() {
    setState(() {
      _selectedTop = null;
      _selectedBottom = null;
      _selectedOuterwear = null;
      _selectedShoes = null;
      _selectedAccessories = null;
    });
  }

  void _randomMix(List<WardrobeItemModel> items) {
    if (items.isEmpty) return;
    final tops = items.where((i) => i.category == WardrobeCategory.tops).toList();
    final bottoms =
        items.where((i) => i.category == WardrobeCategory.bottoms).toList();
    final outers =
        items.where((i) => i.category == WardrobeCategory.outerwear).toList();
    final shoes =
        items.where((i) => i.category == WardrobeCategory.shoes).toList();

    setState(() {
      if (tops.isNotEmpty) {
        tops.shuffle();
        _selectedTop = tops.first;
      }
      if (bottoms.isNotEmpty) {
        bottoms.shuffle();
        _selectedBottom = bottoms.first;
      }
      if (outers.isNotEmpty && outers.length > 1) {
        outers.shuffle();
        _selectedOuterwear = outers.first;
      } else {
        _selectedOuterwear = null;
      }
      if (shoes.isNotEmpty) {
        shoes.shuffle();
        _selectedShoes = shoes.first;
      }
    });
  }

  double _calculateHarmonyScore() {
    int count = 0;
    double score = 8.5;
    if (_selectedTop != null) count++;
    if (_selectedBottom != null) count++;
    if (_selectedOuterwear != null) count++;
    if (_selectedShoes != null) count++;

    if (count == 0) return 0.0;
    if (count == 1) return 8.0;
    if (count == 2) score = 9.2;
    if (count >= 3) score = 9.6;

    // Bonus nếu có màu tương phản hoặc tương đồng hài hòa
    final topColor = _selectedTop?.color.toLowerCase() ?? '';
    final bottomColor = _selectedBottom?.color.toLowerCase() ?? '';
    if ((topColor.contains('trắng') && bottomColor.contains('đen')) ||
        (topColor.contains('be') && bottomColor.contains('nâu')) ||
        (topColor.contains('xanh') && bottomColor.contains('trắng'))) {
      score = 9.8;
    }
    return score;
  }

  Future<void> _saveAsOutfit() async {
    final equipped = [
      if (_selectedTop != null) _selectedTop!,
      if (_selectedBottom != null) _selectedBottom!,
      if (_selectedOuterwear != null) _selectedOuterwear!,
      if (_selectedShoes != null) _selectedShoes!,
      if (_selectedAccessories != null) _selectedAccessories!,
    ];

    if (equipped.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng chọn ít nhất 1 món đồ lên ma-nơ-canh!'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      return;
    }

    final outfitProvider = Provider.of<OutfitProvider>(context, listen: false);
    final newOutfit = OutfitModel(
      id: 'outfit_fitting_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Set Đồ Ma-Nơ-Canh #${DateTime.now().minute}',
      occasion: OutfitOccasion.casual,
      weatherSuitable: ['Mát mẻ', 'Nắng nhẹ'],
      aiScore: _calculateHarmonyScore(),
      colorScore: _calculateHarmonyScore(),
      aiReason: 'Phối đồ hài hòa trực tiếp từ phòng thử đồ ảo 2D Mannequin.',
      itemIds: equipped.map((i) => i.id).toList(),
      coverImageUrl: _selectedTop?.imageUrl ?? equipped.first.imageUrl,
    );

    outfitProvider.addCustomOutfit(newOutfit);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '🎉 Đã lưu bộ trang phục vào mục Outfits!',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wardrobeProvider = Provider.of<WardrobeProvider>(context);
    final allItems = wardrobeProvider.allItemsAcrossAllWardrobes;
    final filteredItems = allItems.where((i) {
      if (_activeCategory == WardrobeCategory.tops) {
        return i.category == WardrobeCategory.tops ||
            i.category == WardrobeCategory.dresses;
      }
      return i.category == _activeCategory;
    }).toList();

    final harmonyScore = _calculateHarmonyScore();

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.lightBackground,
        elevation: 0,
        title: Text(
          'Phòng Thử Đồ Ảo 👗',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppTheme.darkTextPrimary,
            fontSize: 20,
          ),
        ),
        actions: [
          // Switch gender mannequin toggle
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGenderToggle(
                  gender: MannequinGender.female,
                  label: 'Nữ',
                  icon: Icons.female_rounded,
                ),
                _buildGenderToggle(
                  gender: MannequinGender.male,
                  label: 'Nam',
                  icon: Icons.male_rounded,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.restart_alt_rounded,
                color: AppTheme.darkTextSecondary),
            tooltip: 'Xóa hết',
            onPressed: _resetMannequin,
          ),
        ],
      ),
      body: Column(
        children: [
          // Upper Section: Mannequin Interactive Stage
          Expanded(
            flex: 11,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Center Mannequin
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Mannequin2DWidget(
                      gender: _gender,
                      topItem: _selectedTop,
                      bottomItem: _selectedBottom,
                      outerwearItem: _selectedOuterwear,
                      shoesItem: _selectedShoes,
                      accessoriesItem: _selectedAccessories,
                      itemScale: _itemScale,
                      topOffset: _topOffset,
                      bottomOffset: _bottomOffset,
                      onSlotTapped: (cat) {
                        setState(() {
                          _activeCategory = cat;
                        });
                      },
                    ),
                  ),

                  // Top Left: Score Badge
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: Color(0xFFF59E0B), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            harmonyScore > 0
                                ? '$harmonyScore/10 Hài Hòa'
                                : 'Ướm Đồ Ngay',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppTheme.darkTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Top Right: Fine-tune toggle button
                  Positioned(
                    top: 14,
                    right: 14,
                    child: IconButton(
                      icon: Icon(
                        _showFineTune
                            ? Icons.tune_rounded
                            : Icons.tune_outlined,
                        color: _showFineTune
                            ? AppTheme.primaryColor
                            : AppTheme.darkTextSecondary,
                        size: 22,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 2,
                      ),
                      onPressed: () {
                        setState(() => _showFineTune = !_showFineTune);
                      },
                      tooltip: 'Tinh chỉnh độ vừa vặn',
                    ),
                  ),

                  // Fine-tune sliders overlay
                  if (_showFineTune)
                    Positioned(
                      bottom: 12,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Text('Tỷ lệ đồ:',
                                    style: TextStyle(fontSize: 11)),
                                Expanded(
                                  child: Slider(
                                    value: _itemScale,
                                    min: 0.8,
                                    max: 1.25,
                                    activeColor: AppTheme.primaryColor,
                                    onChanged: (v) =>
                                        setState(() => _itemScale = v),
                                  ),
                                ),
                                Text('${(_itemScale * 100).toInt()}%',
                                    style: const TextStyle(fontSize: 11)),
                              ],
                            ),
                            Row(
                              children: [
                                const Text('Vị trí áo:',
                                    style: TextStyle(fontSize: 11)),
                                Expanded(
                                  child: Slider(
                                    value: _topOffset,
                                    min: -30.0,
                                    max: 30.0,
                                    activeColor: AppTheme.secondaryColor,
                                    onChanged: (v) =>
                                        setState(() => _topOffset = v),
                                  ),
                                ),
                                Text('${_topOffset.toInt()}px',
                                    style: const TextStyle(fontSize: 11)),
                              ],
                            ),
                            Row(
                              children: [
                                const Text('Vị trí quần:',
                                    style: TextStyle(fontSize: 11)),
                                Expanded(
                                  child: Slider(
                                    value: _bottomOffset,
                                    min: -30.0,
                                    max: 30.0,
                                    activeColor: AppTheme.accentColor,
                                    onChanged: (v) =>
                                        setState(() => _bottomOffset = v),
                                  ),
                                ),
                                Text('${_bottomOffset.toInt()}px',
                                    style: const TextStyle(fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Lower Section: Wardrobe Items Drawer
          Expanded(
            flex: 8,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Tabs Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildCategoryTab(
                            WardrobeCategory.tops, 'Áo (Tops)', Icons.checkroom),
                        _buildCategoryTab(WardrobeCategory.bottoms,
                            'Quần/Váy', Icons.straighten),
                        _buildCategoryTab(WardrobeCategory.outerwear,
                            'Khoác', Icons.dry_cleaning),
                        _buildCategoryTab(
                            WardrobeCategory.shoes, 'Giày', Icons.skateboarding),
                        _buildCategoryTab(WardrobeCategory.accessories,
                            'Phụ Kiện', Icons.shopping_bag_outlined),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Horizontal Items Slider
                  Expanded(
                    child: filteredItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_outlined,
                                    size: 32,
                                    color: AppTheme.darkTextSecondary),
                                const SizedBox(height: 6),
                                Text(
                                  'Chưa có món đồ nào trong danh mục này',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppTheme.darkTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredItems.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              final isEquipped = _isItemEquipped(item);
                              return _buildWardrobeThumbCard(item, isEquipped);
                            },
                          ),
                  ),
                  const SizedBox(height: 8),

                  // Bottom Action Buttons
                  Row(
                    children: [
                      // Random mix button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: BorderSide(
                              color: AppTheme.primaryColor.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                        icon: const Icon(Icons.shuffle_rounded, size: 18),
                        label: Text(
                          'Xáo Trộn',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: () => _randomMix(allItems),
                      ),
                      const SizedBox(width: 10),

                      // Save Outfit button
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.bookmark_add_rounded,
                              color: Colors.white, size: 18),
                          label: Text(
                            'Lưu Bộ Này Thành Outfit',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          onPressed: _saveAsOutfit,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isItemEquipped(WardrobeItemModel item) {
    return _selectedTop?.id == item.id ||
        _selectedBottom?.id == item.id ||
        _selectedOuterwear?.id == item.id ||
        _selectedShoes?.id == item.id ||
        _selectedAccessories?.id == item.id;
  }

  Widget _buildGenderToggle({
    required MannequinGender gender,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _gender == gender;
    return GestureDetector(
      onTap: () => setState(() => _gender = gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 15,
                color: isSelected ? Colors.white : AppTheme.darkTextSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppTheme.darkTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTab(
      WardrobeCategory cat, String title, IconData icon) {
    final isSelected = _activeCategory == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(icon,
            size: 15,
            color: isSelected ? Colors.white : AppTheme.primaryColor),
        label: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.darkTextPrimary,
          ),
        ),
        selected: isSelected,
        selectedColor: AppTheme.primaryColor,
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        side: BorderSide.none,
        onSelected: (_) => setState(() => _activeCategory = cat),
      ),
    );
  }

  Widget _buildWardrobeThumbCard(WardrobeItemModel item, bool isEquipped) {
    return GestureDetector(
      onTap: () => _equipItem(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 85,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEquipped
                ? AppTheme.primaryColor
                : Colors.black.withOpacity(0.06),
            width: isEquipped ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      color: Colors.white,
                      child: Image.network(
                        item.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.checkroom_rounded,
                          color: Colors.black26,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight:
                        isEquipped ? FontWeight.bold : FontWeight.w500,
                    color: AppTheme.darkTextPrimary,
                  ),
                ),
                Text(
                  item.color,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: AppTheme.darkTextSecondary,
                  ),
                ),
              ],
            ),
            if (isEquipped)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check,
                      color: Colors.white, size: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
