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
  late String _outfitName;
  int _userReaction = 0; // 0: none, 1: liked, -1: disliked

  @override
  void initState() {
    super.initState();
    _outfitName =
        widget.outfit.name.isNotEmpty ? widget.outfit.name : 'Smart casual';
    _items = [
      {'name': 'Áo overshirt', 'thumb': 'assets/images/thumb_overshirt.png'},
      {'name': 'Áo thun trắng', 'thumb': 'assets/images/thumb_tshirt.png'},
      {'name': 'Qquân chino navy', 'thumb': 'assets/images/thumb_chino.png'},
      {'name': 'Sneaker trắng', 'thumb': 'assets/images/thumb_sneaker.png'},
      {'name': 'Túi đeo chéo', 'thumb': 'assets/images/thumb_bag.png'},
    ];
  }

  void _showRenameOutfitDialog() {
    final isEn =
        Provider.of<LanguageProvider>(context, listen: false).isEnglish;
    final controller = TextEditingController(text: _outfitName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.drive_file_rename_outline_rounded,
                color: Color(0xFF7A5420), size: 24),
            const SizedBox(width: 8),
            Text(
              isEn ? 'Rename Outfit' : 'Đặt / Đổi tên outfit',
              style: AppFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: const Color(0xFF111827),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEn
                  ? 'Give this outfit a custom name to easily remember:'
                  : 'Đặt tên riêng cho bộ trang phục để dễ nhớ:',
              style:
                  AppFonts.inter(fontSize: 13, color: const Color(0xFF4B5563)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: AppFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
              decoration: InputDecoration(
                hintText: isEn
                    ? 'e.g. Work Monday, Weekend Vibe'
                    : 'VD: Đi làm thứ Hai, Cafe cuối tuần...',
                hintStyle: AppFonts.inter(
                    fontSize: 13, color: const Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF7A5420), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isEn ? 'Cancel' : 'Hủy',
              style: AppFonts.inter(
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7A5420),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  _outfitName = newName;
                });
                final outfitProvider =
                    Provider.of<OutfitProvider>(context, listen: false);
                outfitProvider.updateOutfitName(widget.outfit.id, newName);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEn
                        ? '✏️ Outfit renamed to "$newName"'
                        : '✏️ Đã đổi tên outfit thành "$newName"'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text(
              isEn ? 'Save' : 'Lưu',
              style: AppFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleReaction(bool isLike) {
    final isEn =
        Provider.of<LanguageProvider>(context, listen: false).isEnglish;
    final outfitProvider = Provider.of<OutfitProvider>(context, listen: false);

    setState(() {
      if (isLike) {
        if (_userReaction == 1) {
          _userReaction = 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(isEn ? 'Removed like reaction' : 'Đã bỏ thích outfit'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        } else {
          _userReaction = 1;
          outfitProvider.recordOutfitReaction(widget.outfit.id, 1);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.thumb_up_rounded,
                      color: Colors.greenAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEn
                          ? '👍 Liked! WEARSY AI will suggest more styles like this.'
                          : '👍 Đã thích! WEARSY AI sẽ gợi ý thêm các phong cách tương tự.',
                      style: AppFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1E293B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (_userReaction == -1) {
          _userReaction = 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEn
                  ? 'Removed dislike reaction'
                  : 'Đã hủy phản hồi không thích'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        } else {
          _userReaction = -1;
          outfitProvider.recordOutfitReaction(widget.outfit.id, -1);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.thumb_down_rounded,
                      color: Colors.orangeAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEn
                          ? '👎 Noted! WEARSY AI will reduce recommendations like this.'
                          : '👎 Đã ghi nhận! WEARSY AI sẽ hạn chế gợi ý phong cách này.',
                      style: AppFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1E293B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  void _replaceItem(int index) {
    final isEn =
        Provider.of<LanguageProvider>(context, listen: false).isEnglish;
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
              title: Text(isEn
                  ? 'Minimalist Plain Polo Shirt'
                  : 'Áo Polo trơn tối giản'),
              subtitle:
                  Text(isEn ? 'Torano • Off-White' : 'Torano • Trắng ngà'),
              trailing: const Icon(Icons.swap_horiz_rounded,
                  color: Color(0xFF2563EB)),
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
              title: Text(isEn
                  ? 'Relaxed Pleated Trousers'
                  : 'Quần tây xếp ly relaxed'),
              subtitle: Text(isEn ? 'Zara • Charcoal Grey' : 'Zara • Đen xám'),
              trailing: const Icon(Icons.swap_horiz_rounded,
                  color: Color(0xFF2563EB)),
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
    final isEn =
        Provider.of<LanguageProvider>(context, listen: false).isEnglish;
    final outfitToSave = widget.outfit.copyWith(name: _outfitName);
    provider.addOutfit(outfitToSave);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isEn
                    ? '✨ Saved outfit "$_outfitName" to Favorites!'
                    : '✨ Đã lưu outfit "$_outfitName" vào Bộ sưu tập yêu thích!',
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                TagLocalization.getLocalizedTag(
                                    _outfitName, isEn),
                                style: AppFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Nút đặt / sửa tên outfit
                            GestureDetector(
                              onTap: _showRenameOutfitDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFE5E7EB)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.edit_outlined,
                                      size: 13,
                                      color: Color(0xFF4B5563),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isEn ? 'Edit name' : 'Sửa tên',
                                      style: AppFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF4B5563),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.outfit.aiReason.isNotEmpty
                              ? TagLocalization.getLocalizedAiReason(
                                  widget.outfit.aiReason, isEn)
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
                              builder: (_) => const VirtualFittingRoomScreen(),
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
                            TagLocalization.getLocalizedName(
                                itm['name']!, isEn),
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

              // Bottom Action Row: Dislike + Like + Save Outfit (Image 3)
              Row(
                children: [
                  // Nút Dislike (Không thích)
                  GestureDetector(
                    onTap: () => _handleReaction(false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _userReaction == -1
                            ? const Color(0xFFFEE2E2)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: _userReaction == -1
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _userReaction == -1
                            ? Icons.thumb_down_rounded
                            : Icons.thumb_down_outlined,
                        color: _userReaction == -1
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF4B5563),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Nút Like (Thích)
                  GestureDetector(
                    onTap: () => _handleReaction(true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _userReaction == 1
                            ? const Color(0xFFDCFCE7)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: _userReaction == 1
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _userReaction == 1
                            ? Icons.thumb_up_rounded
                            : Icons.thumb_up_outlined,
                        color: _userReaction == 1
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF4B5563),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Nút Lưu outfit (Warm Bronze / Gold pill button)
                  Expanded(
                    child: GestureDetector(
                      onTap: _isSaved ? null : _saveOutfit,
                      child: Container(
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
                                  ? (isEn ? 'Saved' : 'Đã lưu')
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
                  ),
                ],
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
