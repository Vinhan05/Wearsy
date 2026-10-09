import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/wardrobe_collection_model.dart';
import '../models/wardrobe_item_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../providers/wardrobe_provider.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/utils/tag_localization.dart';
import 'add_item_screen.dart';
import 'item_detail_screen.dart';
import '../../shopping/screens/smart_shopping_screen.dart';

class WardrobeScreen extends StatelessWidget {
  const WardrobeScreen({super.key});

  /// Modal chọn phương thức thêm đồ (Camera, Thư viện, Smart Shopping)
  static void showAddOptionsModal(BuildContext context,
      {VoidCallback? onSelect}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final isEn = Provider.of<LanguageProvider>(ctx).isEnglish;
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
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isEn ? 'Choose Entry Method' : 'Chọn Phương Thức Nhập Đồ',
                  style: GoogleFonts.outfit(
                    color: AppTheme.darkTextPrimary,
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
                        builder: (_) =>
                            const AddItemScreen(initialMode: 'camera'),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.lavenderCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryLight.withOpacity(0.25),
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
                                isEn ? 'Take Photo from Camera' : 'Chụp ảnh từ Camera',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2849),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isEn
                                    ? 'Take real photos of your clothes, AI will automatically analyze.'
                                    : 'Chụp trực tiếp trang phục thật của bạn, AI sẽ tự động phân tích.',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF5F597C),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFF8174DB)),
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
                        builder: (_) =>
                            const AddItemScreen(initialMode: 'gallery'),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF8174DB).withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8174DB).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.photo_library_rounded,
                              color: AppTheme.primaryColor, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEn ? 'Choose Photo from Gallery' : 'Chọn ảnh từ Thư viện',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2849),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isEn
                                    ? 'Upload available clothing photos from your phone gallery.'
                                    : 'Tải ảnh quần áo có sẵn từ bộ sưu tập điện thoại của bạn.',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF5F597C),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFF8174DB)),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF8174DB).withOpacity(0.15)),
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
                                isEn ? 'Paste Shopping Link (Smart Shopping)' : 'Dán link mua sắm (Smart Shopping)',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2849),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isEn
                                    ? 'Paste link from Shopee, TikTok, Zara... to check AI compatibility before buying.'
                                    : 'Dán link Shopee, TikTok, Zara... để AI kiểm tra tương thích trước khi mua.',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF5F597C),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFF8174DB)),
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

  /// Hiển thị danh sách tất cả các tủ đồ để chuyển đổi hoặc tạo mới
  static void showWardrobeSwitcherModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalCtx) {
        final isEn = Provider.of<LanguageProvider>(modalCtx).isEnglish;
        return Consumer<WardrobeProvider>(
          builder: (context, provider, _) {
            final collections = provider.collections;
            final activeId = provider.activeWardrobeId;

            return SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8174DB).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              isEn ? 'Wardrobe Collections' : 'Bộ Sưu Tập Tủ Đồ',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2849),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                '${collections.length}',
                                style: GoogleFonts.outfit(
                                  color: AppTheme.primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Color(0xFF5F597C)),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    Text(
                      isEn
                          ? 'Create separate wardrobes for Work, Travel, Winter...'
                          : 'Tạo các tủ đồ riêng biệt cho Công sở, Du lịch, Mùa đông...',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF5F597C),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nút Tạo Tủ Đồ Mới
                    InkWell(
                      onTap: () {
                        Navigator.pop(modalCtx);
                        showCreateOrEditWardrobeDialog(context);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_rounded,
                                  color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isEn ? '+ Create New Wardrobe' : '+ Tạo Tủ Đồ Mới',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Danh sách tủ đồ
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: collections.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final col = collections[index];
                          final isSelected = col.id == activeId;
                          final itemCount =
                              provider.getItemCountForWardrobe(col.id);

                          return Material(
                            color: Colors.transparent,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor.withOpacity(0.12)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : AppTheme.primaryColor.withOpacity(0.12),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 4),
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primaryColor.withOpacity(0.2)
                                        : AppTheme.lightBackground,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    col.icon,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        TagLocalization.getLocalizedWardrobeName(col.name, isEn),
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF2C2849),
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    if (col.isDefault)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isEn ? 'Default' : 'Mặc định',
                                          style: GoogleFonts.inter(
                                            color: AppTheme.primaryColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    col.description.isNotEmpty
                                        ? '$itemCount món đồ • ${col.description}'
                                        : '$itemCount món đồ',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF5F597C),
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected)
                                      Icon(Icons.check_circle_rounded,
                                          color: AppTheme.primaryLight,
                                          size: 22)
                                    else
                                      const Icon(Icons.radio_button_unchecked,
                                          color: Colors.white24, size: 20),
                                    if (!col.isDefault) ...[
                                      const SizedBox(width: 4),
                                      PopupMenuButton<String>(
                                        icon: const Icon(
                                            Icons.more_vert_rounded,
                                            color: Colors.white54,
                                            size: 20),
                                        color: AppTheme.darkCard,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          side: BorderSide(
                                              color: Colors.white
                                                  .withOpacity(0.1)),
                                        ),
                                        onSelected: (action) {
                                          if (action == 'edit') {
                                            Navigator.pop(modalCtx);
                                            showCreateOrEditWardrobeDialog(
                                                context,
                                                existing: col);
                                          } else if (action == 'delete') {
                                            _confirmDeleteWardrobe(
                                                context, provider, col);
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.edit_outlined,
                                                    color: Colors.white70,
                                                    size: 18),
                                                const SizedBox(width: 10),
                                                Text('Đổi tên & Icon',
                                                    style: GoogleFonts.inter(
                                                        color: Colors.white)),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_outline,
                                                    color: AppTheme.accentColor,
                                                    size: 18),
                                                const SizedBox(width: 10),
                                                Text('Xóa tủ đồ này',
                                                    style: GoogleFonts.inter(
                                                        color: AppTheme
                                                            .accentColor)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                onTap: () {
                                  provider.switchWardrobe(col.id);
                                  Navigator.pop(modalCtx);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Nút Reset tất cả quần áo
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.accentColor,
                          side: BorderSide(
                              color: AppTheme.accentColor.withOpacity(0.4)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                        label: Text(
                          'Reset Tất Cả Quần Áo (Tài khoản trắng)',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: () {
                          Navigator.pop(modalCtx);
                          _confirmResetWardrobe(context, provider);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Hộp thoại xác nhận reset tủ đồ
  static void _confirmResetWardrobe(
    BuildContext context,
    WardrobeProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.lightBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppTheme.accentColor, size: 24),
            const SizedBox(width: 10),
            Text(
              'Reset Tủ Đồ Trắng?',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: const Color(0xFF2C2849),
              ),
            ),
          ],
        ),
        content: Text(
          'Thao tác này sẽ xóa toàn bộ quần áo trong tủ đồ và chuyển tài khoản về trạng thái tủ đồ trắng (0 món đồ).\n\nBạn có chắc chắn muốn thực hiện?',
          style: GoogleFonts.inter(
              fontSize: 14, color: const Color(0xFF5F597C), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Hủy',
              style: GoogleFonts.inter(
                  color: const Color(0xFF5F597C), fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await provider.clearAllItems();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '✨ Đã reset tủ đồ thành công! Tài khoản của bạn hiện là tủ đồ trắng (0 quần áo).',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: AppTheme.primaryColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                );
              }
            },
            child: Text(
              'Xác Nhận Reset',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Hộp thoại xác nhận xóa tủ đồ
  static void _confirmDeleteWardrobe(
    BuildContext context,
    WardrobeProvider provider,
    WardrobeCollectionModel col,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFFF3F1FA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppTheme.accentColor, size: 26),
            const SizedBox(width: 10),
            Text(
              'Xóa Tủ Đồ?',
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2849),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa "${col.icon} ${col.name}"? Tất cả món đồ trong tủ này sẽ được tự động chuyển về "Tủ Đồ Mặc Định" để bảo vệ dữ liệu.',
          style: GoogleFonts.inter(
            color: const Color(0xFF5F597C),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Hủy',
              style: GoogleFonts.inter(color: const Color(0xFF5F597C)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              provider.deleteWardrobe(col.id);
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🗑️ Đã xóa tủ đồ "${col.name}"'),
                  backgroundColor: AppTheme.accentColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              'Xóa Tủ Đồ',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Hộp thoại Tạo mới hoặc Sửa Tủ Đồ
  static void showCreateOrEditWardrobeDialog(
    BuildContext context, {
    WardrobeCollectionModel? existing,
  }) {
    final isEditing = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    String selectedIcon = existing?.icon ?? '💼';

    final presetSuggestions = [
      {
        'name': 'Tủ Đồ Đi Làm / Công Sở',
        'icon': '💼',
        'desc': 'Vest, sơ mi, quần âu & chân váy'
      },
      {
        'name': 'Tủ Đồ Du Lịch & Nghỉ Dưỡng',
        'icon': '🏖️',
        'desc': 'Đầm maxi, đồ bơi & phong cách nhiệt đới'
      },
      {
        'name': 'Tủ Đồ Thu Đông Ấm Áp',
        'icon': '❄️',
        'desc': 'Áo len, áo dạ & áo phao giữ ấm'
      },
      {
        'name': 'Tủ Đồ Tiệc & Sự Kiện',
        'icon': '💃',
        'desc': 'Đầm dạ hội, trang phục sang trọng'
      },
      {
        'name': 'Tủ Đồ Gym & Thể Thao',
        'icon': '🏋️',
        'desc': 'Đồ tập, thể thao năng động & sneaker'
      },
      {
        'name': 'Tủ Đồ Đi Học & Campus',
        'icon': '🎓',
        'desc': 'Polo, jean, hoodie trẻ trung'
      },
    ];

    final availableIcons = [
      '🏠',
      '💼',
      '🏖️',
      '❄️',
      '💃',
      '🏋️',
      '🎓',
      '👗',
      '👔',
      '👟',
      '🎒',
      '✨',
      '🔥',
      '🌸',
      '🕶️'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8174DB).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isEditing ? 'Chỉnh Sửa Tủ Đồ' : 'Tạo Tủ Đồ Mới 🚪',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2849),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Phân chia quần áo theo mục đích sử dụng để AI dễ dàng phối đồ.',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF5F597C),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Gợi ý nhanh (chỉ khi tạo mới)
                      if (!isEditing) ...[
                        Text(
                          'Mẫu Tủ Đồ Phổ Biến:',
                          style: GoogleFonts.inter(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: presetSuggestions.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (ctx, i) {
                              final p = presetSuggestions[i];
                              return ActionChip(
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.2)),
                                label: Text(
                                  '${p['icon']} ${p['name']!.split('/')[0].replaceAll('Tủ Đồ ', '')}',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.darkTextPrimary,
                                    fontSize: 12,
                                  ),
                                ),
                                onPressed: () {
                                  setModalState(() {
                                    nameCtrl.text = p['name']!;
                                    selectedIcon = p['icon']!;
                                    descCtrl.text = p['desc']!;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Chọn Biểu tượng / Emoji
                      Text(
                        'Chọn Biểu Tượng:',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF5F597C),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableIcons.map((icon) {
                          final isSelected = selectedIcon == icon;
                          return GestureDetector(
                            onTap: () =>
                                setModalState(() => selectedIcon = icon),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor.withOpacity(0.2)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : const Color(0xFF8174DB)
                                          .withOpacity(0.15),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(icon,
                                  style: const TextStyle(fontSize: 20)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // Nhập Tên Tủ Đồ
                      TextField(
                        controller: nameCtrl,
                        style:
                            GoogleFonts.inter(color: const Color(0xFF2C2849)),
                        decoration: InputDecoration(
                          labelText: 'Tên Tủ Đồ',
                          hintText: 'Ví dụ: Tủ Đồ Đi Làm, Tủ Đồ Mùa Hè...',
                          labelStyle:
                              GoogleFonts.inter(color: const Color(0xFF5F597C)),
                          hintStyle:
                              GoogleFonts.inter(color: const Color(0xFF9E99B8)),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Text(selectedIcon,
                                style: const TextStyle(fontSize: 20)),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: AppTheme.primaryColor.withOpacity(0.15)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: AppTheme.primaryColor.withOpacity(0.15)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: AppTheme.primaryColor, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Nhập Mô tả Tủ Đồ
                      TextField(
                        controller: descCtrl,
                        style:
                            GoogleFonts.inter(color: AppTheme.darkTextPrimary),
                        decoration: InputDecoration(
                          labelText: 'Mô tả ngắn (tùy chọn)',
                          hintText:
                              'Ví dụ: Quần áo thanh lịch cho ngày làm việc...',
                          labelStyle: GoogleFonts.inter(
                              color: AppTheme.darkTextSecondary),
                          hintStyle: GoogleFonts.inter(
                              color:
                                  AppTheme.darkTextSecondary.withOpacity(0.7)),
                          prefixIcon: Icon(Icons.notes_rounded,
                              color: AppTheme.primaryColor, size: 20),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: AppTheme.primaryColor.withOpacity(0.15)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: AppTheme.primaryColor.withOpacity(0.15)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: AppTheme.primaryColor, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Nút Lưu / Tạo
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          onPressed: () async {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      const Text('Vui lòng nhập tên tủ đồ'),
                                  backgroundColor: AppTheme.accentColor,
                                ),
                              );
                              return;
                            }

                            final provider = Provider.of<WardrobeProvider>(
                                context,
                                listen: false);

                            if (isEditing) {
                              await provider.updateWardrobe(
                                id: existing.id,
                                name: name,
                                icon: selectedIcon,
                                description: descCtrl.text.trim(),
                              );
                            } else {
                              await provider.createWardrobe(
                                name: name,
                                icon: selectedIcon,
                                description: descCtrl.text.trim(),
                              );
                            }

                            if (context.mounted) {
                              Navigator.pop(sheetCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded,
                                          color: Colors.greenAccent),
                                      const SizedBox(width: 10),
                                      Text(
                                        isEditing
                                            ? '✨ Đã cập nhật tủ đồ "$name"'
                                            : '🎉 Đã tạo tủ đồ mới "$name"',
                                        style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: AppTheme.primaryColor,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: Text(
                            isEditing ? 'CẬP NHẬT TỦ ĐỒ' : 'TẠO TỦ ĐỒ MỚI',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
    Provider.of<ThemeProvider>(context); // Listen to Theme changes
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 8),
            _buildCategoryFilter(context),
            const SizedBox(height: 12),
            Expanded(child: _buildGrid(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final provider = Provider.of<WardrobeProvider>(context);
    final isEn = Provider.of<LanguageProvider>(context).isEnglish;
    final totalItems = provider.allItems.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => WardrobeScreen.showWardrobeSwitcherModal(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isEn ? 'Wardrobe' : 'Tủ đồ',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.primaryLight,
                        size: 26,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEn ? 'Your wardrobe' : 'Tủ đồ của bạn',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEn
                      ? '$totalItems items • 2 outfits paired • Updated today'
                      : '$totalItems món đồ  •  2 set đã phối  •  Cập nhật hôm nay',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          // Dark Search Circle Button
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isEn
                      ? '🔍 Type to search your wardrobe items'
                      : '🔍 Nhập từ khóa để tìm kiếm trang phục'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFF18181B),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context) {
    final provider = Provider.of<WardrobeProvider>(context);
    final isEn = Provider.of<LanguageProvider>(context).isEnglish;

    final filterOptions = [
      {'key': null, 'label': isEn ? 'All' : 'Tất cả'},
      {'key': WardrobeCategory.tops, 'label': isEn ? 'Shirts' : 'Áo sơ mi'},
      {'key': WardrobeCategory.outerwear, 'label': isEn ? 'Jackets' : 'Áo khoác'},
      {'key': WardrobeCategory.dresses, 'label': isEn ? 'T-Shirts' : 'Áo thun'},
      {'key': WardrobeCategory.bottoms, 'label': isEn ? 'Pants' : 'Quần'},
      {'key': WardrobeCategory.shoes, 'label': isEn ? 'Shoes' : 'Giày'},
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filterOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final opt = filterOptions[index];
          final cat = opt['key'] as WardrobeCategory?;
          final isSelected = provider.selectedCategory == cat;
          final label = opt['label'] as String;

          return GestureDetector(
            onTap: () => provider.setCategory(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF27272A)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF27272A)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF374151),
                ),
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
      return Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    final items = provider.filteredItems;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index < items.length) {
          final item = items[index];
          return _WardrobeCard(
            item: item,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ItemDetailScreen(item: item),
                ),
              );
            },
          );
        } else {
          return _buildAddCard(context);
        }
      },
    );
  }

  Widget _buildAddCard(BuildContext context) {
    return GestureDetector(
      onTap: () => WardrobeScreen.showAddOptionsModal(context),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(85),
            bottom: Radius.circular(16),
          ),
          border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
        ),
        child: Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9CA3AF), Color(0xFF6B7280)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
        ),
      ),
    );
  }
}

class _WardrobeCard extends StatefulWidget {
  final WardrobeItemModel item;
  final VoidCallback onTap;

  const _WardrobeCard({
    required this.item,
    required this.onTap,
  });

  @override
  State<_WardrobeCard> createState() => _WardrobeCardState();
}

class _WardrobeCardState extends State<_WardrobeCard> {
  bool _isLiked = false;

  @override
  Widget build(BuildContext context) {
    final isEn = Provider.of<LanguageProvider>(context).isEnglish;
    final item = widget.item;
    final isNetworkImage = item.imageUrl.startsWith('http://') ||
        item.imageUrl.startsWith('https://');

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(85),
            bottom: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // Top Arch Image Container
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 18, 12, 4),
                    child: _buildItemImage(context, item, isNetworkImage),
                  ),
                ),
                // Bottom Text Container (Title + Category • Material)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
                  child: Column(
                    children: [
                      Text(
                        TagLocalization.getLocalizedName(item.name, isEn),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${TagLocalization.getLocalizedTag(item.category.displayName, isEn)} • Cotton',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Top Right Floating Heart Button
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isLiked = !_isLiked;
                  });
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 15,
                    color: _isLiked ? Colors.redAccent : const Color(0xFF4B5563),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemImage(
      BuildContext context, WardrobeItemModel item, bool isNetworkImage) {
    return isNetworkImage
        ? Image.network(
            item.imageUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _buildFallbackCard(item),
          )
        : Image.file(
            File(item.imageUrl),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _buildFallbackCard(item),
          );
  }

  Widget _buildFallbackCard(WardrobeItemModel item) {
    final fallbackUrl = WardrobeItemModel.sanitizeImageUrl(
      '',
      name: item.name,
      category: item.category,
    );
    return Image.network(
      fallbackUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _buildCategoryPlaceholder(item),
    );
  }

  Widget _buildCategoryPlaceholder(WardrobeItemModel item) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(item.category.icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 6),
          Text(
            item.category.displayName,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
