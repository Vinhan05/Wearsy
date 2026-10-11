import 'package:flutter/material.dart';
import 'package:wearsy_mobile/core/theme/app_fonts.dart';
import 'package:provider/provider.dart';
import '../models/outfit_model.dart';
import '../providers/outfit_provider.dart';
import '../../fitting_room/screens/virtual_fitting_room_screen.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/utils/tag_localization.dart';
import '../../../shared/widgets/wearsy_bottom_nav_bar.dart';

class OutfitDetailScreen extends StatefulWidget {
  final OutfitModel outfit;
  const OutfitDetailScreen({super.key, required this.outfit});

  @override
  State<OutfitDetailScreen> createState() => _OutfitDetailScreenState();
}

class _OutfitDetailScreenState extends State<OutfitDetailScreen> {
  late List<Map<String, String>> _items;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _items = [
      {'name': 'Áo overshirt', 'thumb': 'assets/images/thumb_overshirt.png'},
      {'name': 'Áo thun trắng', 'thumb': 'assets/images/thumb_tshirt.png'},
      {'name': 'Qquân chino navy', 'thumb': 'assets/images/thumb_chino.png'},
      {'name': 'Sneaker trắng', 'thumb': 'assets/images/thumb_sneaker.png'},
      {'name': 'Túi đeo chéo', 'thumb': 'assets/images/thumb_bag.png'},
    ];
  }

  void _replaceItem(int index) {
    final isEn = Provider.of<LanguageProvider>(context, listen: false).isEnglish;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEn
                  ? 'Choose replacement for "${TagLocalization.getLocalizedName(_items[index]['name']!, isEn)}"'
                  : 'Chọn món đồ thay thế cho "${_items[index]['name']}"',
              style: AppFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: const Text('👕', style: TextStyle(fontSize: 24)),
              title: Text(isEn ? 'Minimalist Plain Polo Shirt' : 'Áo Polo trơn tối giản'),
              subtitle: Text(isEn ? 'Torano • Off-White' : 'Torano • Trắng ngà'),
              trailing: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF2563EB)),
              onTap: () {
                setState(() {
                  _items[index] = {
                    'name': 'Áo Polo trơn',
                    'thumb': 'assets/images/thumb_tshirt.png',
                  };
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text('👖', style: TextStyle(fontSize: 24)),
              title: Text(isEn ? 'Relaxed Pleated Trousers' : 'Quần tây xếp ly relaxed'),
              subtitle: Text(isEn ? 'Zara • Charcoal Grey' : 'Zara • Đen xám'),
              trailing: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF2563EB)),
              onTap: () {
                setState(() {
                  _items[index] = {
                    'name': 'Quần tây xếp ly',
                    'thumb': 'assets/images/thumb_chino.png',
                  };
                });
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveOutfit() {
    setState(() => _isSaved = true);
    final provider = Provider.of<OutfitProvider>(context, listen: false);
    final isEn = Provider.of<LanguageProvider>(context, listen: false).isEnglish;
    provider.addOutfit(widget.outfit);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isEn
                    ? '✨ Saved outfit "${widget.outfit.name}" to Favorites!'
                    : '✨ Đã lưu outfit "${widget.outfit.name}" vào Bộ sưu tập yêu thích!',
                style: AppFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF7A5420),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);
    final isEn = Provider.of<LanguageProvider>(context).isEnglish;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Back Button & Weather Badge (Image 5)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          size: 20, color: Color(0xFF111827)),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        const Text('⛅', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 4),
                        Text(
                          '29°C • ${TagLocalization.getLocalizedCityName("Đà Nẵng", isEn)}',
                          style: AppFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Title: "Outfit dành cho bạn"
              Text(
                isEn ? 'Outfit For You' : 'Outfit dành cho bạn',
                style: AppFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 6),

              // Subtitle & "Đổi outfit" Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.outfit.name.isNotEmpty
                              ? TagLocalization.getLocalizedTag(widget.outfit.name, isEn)
                              : 'Smart casual',
                          style: AppFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.outfit.aiReason.isNotEmpty
                              ? TagLocalization.getLocalizedAiReason(widget.outfit.aiReason, isEn)
                              : (isEn
                                  ? 'Neat, modern, and suitable for various occasions during the day.'
                                  : 'Gọn gàng, hiện đại và phù hợp cho nhiều hoàn cảnh trong ngày.'),
                          style: AppFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _items.shuffle();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEn
                              ? '✨ Outfit suggestions refreshed!'
                              : '✨ Đã làm mới gợi ý phối đồ!'),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sync_rounded,
                              size: 14, color: Color(0xFF374151)),
                          const SizedBox(width: 4),
                          Text(
                            isEn ? 'Change outfit' : 'Đổi outfit',
                            style: AppFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Full-Body 3D Mannequin Preview Container
              Container(
                width: double.infinity,
                height: 380,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/outfit_detail_mannequin.jpg',
                          height: 360,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    // Expand/Fitting Room Button (Bottom Right)
                    Positioned(
                      bottom: 14,
                      right: 14,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const VirtualFittingRoomScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.open_in_full_rounded,
                              size: 18, color: Color(0xFF111827)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section: "Chi tiết outfit"
              Text(
                isEn ? 'Outfit details' : 'Chi tiết outfit',
                style: AppFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),

              // List of 5 outfit items (Clean rows on pure white canvas matching Image 5)
              Column(
                children: List.generate(_items.length, (idx) {
                  final itm = _items[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        // Thumbnail
                        Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          alignment: Alignment.center,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.asset(
                              itm['thumb']!,
                              width: 38,
                              height: 38,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.checkroom_outlined,
                                size: 20,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Item Name
                        Expanded(
                          child: Text(
                            TagLocalization.getLocalizedName(itm['name']!, isEn),
                            style: AppFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111827),
                            ),
                          ),
                        ),

                        // [ Thay ] Action Button with light blue border
                        GestureDetector(
                          onTap: () => _replaceItem(idx),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF93C5FD),
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              isEn ? 'Replace' : 'Thay',
                              style: AppFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              // Bottom Button: "Lưu outfit" (Warm Bronze / Gold pill button)
              GestureDetector(
                onTap: _isSaved ? null : _saveOutfit,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _isSaved
                        ? const Color(0xFF634114)
                        : const Color(0xFF7A5420),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7A5420).withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isSaved
                            ? Icons.bookmark_added_rounded
                            : Icons.bookmark_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isSaved
                            ? (isEn ? 'Saved outfit' : 'Đã lưu outfit')
                            : (isEn ? 'Save outfit' : 'Lưu outfit'),
                        style: AppFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: WearsyBottomNavBar(
        currentIndex: 2,
        onTabSelected: (index) {
          Navigator.pop(context);
        },
      ),
    );
  }
}
