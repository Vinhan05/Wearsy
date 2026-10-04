import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/screens/welcome_screen.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import '../../outfits/providers/outfit_provider.dart';
import 'edit_style_profile_screen.dart';
import 'account_settings_screen.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/language_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final isEn = langProvider.isEnglish;
    final authProvider = Provider.of<AuthProvider>(context);
    final wardrobeProvider = Provider.of<WardrobeProvider>(context);
    final outfitProvider = Provider.of<OutfitProvider>(context);
    final user = authProvider.user;

    final name = (user?.fullName != null && user!.fullName.trim().isNotEmpty)
        ? user.fullName
        : 'Nguyễn Văn A';

    final totalItems = wardrobeProvider.allItemsAcrossAllWardrobes.length;
    final totalOutfits = outfitProvider.outfits.length;

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
                          style: GoogleFonts.outfit(
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
                          style: GoogleFonts.inter(
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
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: AppTheme.primaryLight,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Smart casual',
                            style: GoogleFonts.outfit(
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
                            style: GoogleFonts.inter(
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
                              style: GoogleFonts.inter(
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

              // 3. Wardrobe Stats Card (Tủ đồ của bạn)
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
                      style: GoogleFonts.inter(
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
                        _buildStatItem('👕', totalItems > 0 ? '$totalItems' : '128', isEn ? 'Items' : 'Món đồ'),
                        Container(width: 1, height: 32, color: const Color(0xFFE5E7EB)),
                        _buildStatItem('👔', totalOutfits > 0 ? '$totalOutfits' : '32', isEn ? 'Outfits' : 'Set đồ'),
                        Container(width: 1, height: 32, color: const Color(0xFFE5E7EB)),
                        _buildStatItem('🤍', '18', isEn ? 'Favorites' : 'Yêu thích'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 4. Account Settings & System Menus
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
                            builder: (_) => const AccountSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(color: Color(0xFFF3F4F6), height: 1),
                    _buildMenuItem(
                      icon: Icons.logout_rounded,
                      title: isEn ? 'Log Out' : 'Đăng xuất',
                      textColor: const Color(0xFFEF4444),
                      iconColor: const Color(0xFFEF4444),
                      onTap: () async {
                        await authProvider.logout();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const WelcomeScreen()),
                            (route) => false,
                          );
                        }
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

  Widget _buildStatItem(String icon, String count, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              count,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
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
        style: GoogleFonts.inter(
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
