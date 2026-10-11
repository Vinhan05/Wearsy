import 'package:flutter/material.dart';
import 'package:wearsy_mobile/core/theme/app_fonts.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../../outfits/providers/outfit_provider.dart';
import '../../outfits/models/outfit_model.dart';
import '../../outfits/screens/outfit_screen.dart';
import '../../outfits/screens/outfit_detail_screen.dart';
import '../../wardrobe/screens/wardrobe_screen.dart';
import 'edit_style_profile_screen.dart';
import 'account_settings_screen.dart';
import 'app_settings_screen.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/language_provider.dart';

class ProfileScreen extends StatelessWidget {
  final Function(int)? onSwitchTab;

  const ProfileScreen({super.key, this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final isEn = langProvider.isEnglish;
    final authProvider = Provider.of<AuthProvider>(context);
    final wardrobeProvider = Provider.of<WardrobeProvider>(context);
    final outfitProvider = Provider.of<OutfitProvider>(context);
    final user = authProvider.user;
    final isPremium = user != null && (user.hasActiveVip || user.isVip);

    final name = (user?.fullName != null && user!.fullName.trim().isNotEmpty)
        ? user.fullName
        : 'Nguyễn Văn A';

    final totalItems = wardrobeProvider.allItemsAcrossAllWardrobes.length;
    final totalOutfits = outfitProvider.outfits.length;
    final totalFavorites = outfitProvider.favoriteOutfits.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Row: Avatar + Name + Edit Profile + Bell Icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Synchronized Dynamic User Avatar
                  const UserAvatar(
                    radius: 38,
                  ),
                  const SizedBox(width: 14),
                  // Name and Edit Button
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEn
                              ? 'Fashion lover, your own way.'
                              : 'Yêu thời trang, theo cách riêng.',
                          style: AppFonts.inter(
                            fontSize: 12.5,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Edit Profile Pill Button
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const EditStyleProfileScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit_outlined,
                                    size: 13, color: Color(0xFF374151)),
                                const SizedBox(width: 6),
                                Text(
                                  isEn ? 'Edit Profile' : 'Chỉnh sửa hồ sơ',
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
                  ),
                  // Bell Icon
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                    ),
                    child: const Icon(Icons.notifications_none_rounded,
                        size: 20, color: Color(0xFF111827)),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // 2. Personal Style Card (Phong cách cá nhân)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFC),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEn ? 'PERSONAL STYLE' : 'PHONG CÁCH CÁ NHÂN',
                            style: AppFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: AppTheme.primaryLight,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Smart casual',
                            style: AppFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isEn
                                ? 'Elegant, minimal\nand versatile.'
                                : 'Thanh lịch, tối giản\nvà linh hoạt.',
                            style: AppFonts.inter(
                              fontSize: 12.5,
                              height: 1.35,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const EditStyleProfileScreen(),
                                ),
                              );
                            },
                            child: Text(
                              isEn ? 'View Details' : 'Xem chi tiết',
                              style: AppFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Image of Mannequin next to plant
                    Expanded(
                      flex: 5,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/profile_style_card.jpg',
                          height: 130,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 3. Wardrobe Stats Card (TỦ ĐỒ CỦA BẠN)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEn ? 'YOUR WARDROBE' : 'TỦ ĐỒ CỦA BẠN',
                      style: AppFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          icon: Icons.checkroom_outlined,
                          count: '$totalItems',
                          label: isEn ? 'Items' : 'Món đồ',
                          onTap: () {
                            if (onSwitchTab != null) {
                              onSwitchTab!(1);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WardrobeScreen(),
                                ),
                              );
                            }
                          },
                        ),
                        Container(width: 1, height: 32, color: const Color(0xFFE5E7EB)),
                        _buildStatItem(
                          icon: Icons.dry_cleaning_outlined,
                          count: '$totalOutfits',
                          label: isEn ? 'Outfits' : 'Set đồ',
                          onTap: () {
                            if (onSwitchTab != null) {
                              onSwitchTab!(2);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const OutfitScreen(),
                                ),
                              );
                            }
                          },
                        ),
                        Container(width: 1, height: 32, color: const Color(0xFFE5E7EB)),
                        _buildStatItem(
                          icon: Icons.favorite_border_rounded,
                          count: '$totalFavorites',
                          label: isEn ? 'Favorites' : 'Yêu thích',
                          onTap: () => _showFavoritesModal(
                              context, outfitProvider.favoriteOutfits, isEn),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 4. WEARSY PREMIUM Gold/Bronze Banner Card (Ẩn nếu đã nâng cấp Premium)
              if (!isPremium) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AccountSettingsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF86591D), Color(0xFF6B4515)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF86591D).withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.diamond_outlined,
                            color: Colors.white, size: 36),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEn ? 'UPGRADE' : 'NÂNG CẤP',
                                style: AppFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: const Color(0xFFFFD700),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'WEARSY PREMIUM',
                                style: AppFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isEn
                                    ? 'Unlock advanced personalized features.'
                                    : 'Mở khóa trải nghiệm cá nhân hóa nâng cao.',
                                style: AppFonts.inter(
                                  fontSize: 11.5,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: Colors.white, size: 24),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // 5. Account Settings & System Menus
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.person_outline_rounded,
                        title: isEn ? 'Account & Security' : 'Tài khoản & bảo mật',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AccountSettingsScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(color: Color(0xFFF3F4F6), height: 1),
                      _buildMenuItem(
                        icon: Icons.settings_outlined,
                        title: isEn ? 'Settings' : 'Cài đặt',
                        onTap: () {
                          Navigator.push(
                            context,
                              MaterialPageRoute(
                              builder: (_) => const AppSettingsScreen(),
                            ),
                          );
                        },
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

  Widget _buildStatItem({
    required IconData icon,
    required String count,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: const Color(0xFF374151)),
                const SizedBox(width: 8),
                Text(
                  count,
                  style: AppFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppFonts.inter(
                fontSize: 11.5,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFavoritesModal(
      BuildContext context, List<OutfitModel> favoriteOutfits, bool isEn) {
    if (favoriteOutfits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEn
                ? 'No favorite outfits yet. Tap the ❤️ icon on any outfit to save!'
                : 'Chưa có set đồ yêu thích nào. Hãy nhấn biểu tượng ❤️ trên set đồ để lưu!',
            style: AppFonts.inter(),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.favorite_rounded,
                      color: Color(0xFFEF4444), size: 24),
                  const SizedBox(width: 10),
                  Text(
                    isEn
                        ? 'Favorite Outfits (${favoriteOutfits.length})'
                        : 'Set Đồ Yêu Thích (${favoriteOutfits.length})',
                    style: AppFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: favoriteOutfits.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final outfit = favoriteOutfits[index];
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    tileColor: const Color(0xFFF8FAFC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        outfit.coverImageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 50,
                          height: 50,
                          color: const Color(0xFFE2E8F0),
                          child: const Icon(Icons.checkroom_rounded,
                              color: Color(0xFF64748B)),
                        ),
                      ),
                    ),
                    title: Text(
                      outfit.name,
                      style: AppFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: Text(
                      outfit.aiReason,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.inter(
                          fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: Color(0xFF94A3B8)),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OutfitDetailScreen(outfit: outfit),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      leading: Icon(icon, color: iconColor ?? const Color(0xFF374151), size: 22),
      title: Text(
        title,
        style: AppFonts.inter(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: textColor ?? const Color(0xFF111827),
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 14, color: Color(0xFF9CA3AF)),
      onTap: onTap,
    );
  }
}
