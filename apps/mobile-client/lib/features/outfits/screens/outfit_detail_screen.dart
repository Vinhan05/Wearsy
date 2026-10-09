import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/outfit_model.dart';
import '../providers/outfit_provider.dart';
import '../../fitting_room/screens/virtual_fitting_room_screen.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/localization/language_toggle_button.dart';
import '../../../core/utils/tag_localization.dart';

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
      {'name': 'Áo overshirt', 'icon': '🧥', 'color': 'Be sữa'},
      {'name': 'Áo thun trắng', 'icon': '👕', 'color': 'Trắng trơn'},
      {'name': 'Quần chino navy', 'icon': '👖', 'color': 'Xanh navy'},
      {'name': 'Sneaker trắng', 'icon': '👟', 'color': 'Trắng da'},
      {'name': 'Túi đeo chéo', 'icon': '👜', 'color': 'Đen da'},
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
              style: GoogleFonts.outfit(
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
              trailing: Icon(Icons.swap_horiz_rounded, color: AppTheme.primaryLight),
              onTap: () {
                setState(() {
                  _items[index] = {
                    'name': 'Áo Polo trơn tối giản',
                    'icon': '👕',
                    'color': 'Trắng ngà'
                  };
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text('👖', style: TextStyle(fontSize: 24)),
              title: Text(isEn ? 'Relaxed Pleated Trousers' : 'Quần tây xếp ly relaxed'),
              subtitle: Text(isEn ? 'Zara • Charcoal Grey' : 'Zara • Đen xám'),
              trailing: Icon(Icons.swap_horiz_rounded, color: AppTheme.primaryLight),
              onTap: () {
                setState(() {
                  _items[index] = {
                    'name': 'Quần tây xếp ly relaxed',
                    'icon': '👖',
                    'color': 'Đen xám'
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
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF8A6728),
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
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Back Button & Language Toggle & Weather Badge
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
                  Row(
                    children: [
                      const LanguageToggleButton(style: LanguageToggleStyle.compact),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
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
                              style: GoogleFonts.inter(
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
                ],
              ),

              const SizedBox(height: 18),

              // Title: "Outfit dành cho bạn"
              Text(
                isEn ? 'Outfit For You' : 'Outfit dành cho bạn',
                style: GoogleFonts.outfit(
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
                          style: GoogleFonts.inter(
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
                          style: GoogleFonts.inter(
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
                            style: GoogleFonts.inter(
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
                    // Expand/Fitting Room Button
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
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 10),

              // List of 5 outfit items
              Column(
                children: List.generate(_items.length, (idx) {
                  final itm = _items[idx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        // Thumbnail Icon Container
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          alignment: Alignment.center,
                          child: Text(itm['icon']!,
                              style: const TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 12),
                        // Item Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                TagLocalization.getLocalizedName(itm['name']!, isEn),
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                TagLocalization.getColorName(itm['color']!, isEn),
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // [Thay] Action Button
                        GestureDetector(
                          onTap: () => _replaceItem(idx),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: AppTheme.primaryLight),
                            ),
                            child: Text(
                              isEn ? 'Replace' : 'Thay',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryLight,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Bottom Button: "Lưu outfit"
              GestureDetector(
                onTap: _isSaved ? null : _saveOutfit,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _isSaved
                        ? const Color(0xFF6E521C)
                        : const Color(0xFF8A6728),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8A6728).withOpacity(0.3),
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
                        style: GoogleFonts.inter(
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
    );
  }
}
