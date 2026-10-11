import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/localization/language_toggle_button.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_picker_sheet.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/providers/auth_provider.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  // Notification preferences
  bool _dailyOutfitReminder = true;
  bool _weatherSmartAlerts = true;
  bool _promotionUpdates = false;

  // Privacy preferences
  bool _analyticsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadLocalSettings();
  }

  Future<void> _loadLocalSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _dailyOutfitReminder =
              prefs.getBool('pref_daily_outfit_reminder') ?? true;
          _weatherSmartAlerts =
              prefs.getBool('pref_weather_smart_alerts') ?? true;
          _promotionUpdates = prefs.getBool('pref_promotion_updates') ?? false;
          _analyticsEnabled = prefs.getBool('pref_analytics_enabled') ?? true;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveNotificationPref(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isEn = langProvider.isEnglish;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF111827), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEn ? 'Settings' : 'Cài Đặt Ứng Dụng',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF111827),
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14.0),
            child: Center(
              child: LanguageToggleButton(style: LanguageToggleStyle.compact),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E7EB), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tùy Chọn Chung (Preferences)
            _buildSectionHeader(
              title: isEn ? 'GENERAL PREFERENCES' : 'TÙY CHỌN CHUNG',
              icon: Icons.tune_rounded,
            ),
            _buildSettingsCard(
              children: [
                _buildNavigationTile(
                  icon: Icons.language_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  title: isEn ? 'Language' : 'Ngôn ngữ',
                  subtitle: langProvider.currentLanguageName,
                  trailingText: '${langProvider.currentFlag} ${langProvider.currentShortCode}',
                  onTap: () => _showLanguageModal(context),
                ),
                _buildDivider(),
                _buildNavigationTile(
                  icon: Icons.palette_outlined,
                  iconColor: const Color(0xFF8B5CF6),
                  title: isEn ? 'Theme & Appearance' : 'Giao diện & Chủ đề',
                  subtitle: themeProvider.currentPalette.name,
                  onTap: () => ThemePickerSheet.show(context),
                ),
                _buildDivider(),
                _buildNavigationTile(
                  icon: Icons.notifications_none_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: isEn ? 'Notifications' : 'Thông báo ứng dụng',
                  subtitle: isEn
                      ? 'Daily reminders, weather styling'
                      : 'Nhắc nhở outfit, cập nhật thời tiết',
                  onTap: () => _showNotificationsModal(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 2. Quyền Riêng Tư & Bảo Mật (Privacy & Security)
            _buildSectionHeader(
              title: isEn ? 'PRIVACY & SECURITY' : 'QUYỀN RIÊNG TƯ & BẢO MẬT',
              icon: Icons.shield_outlined,
            ),
            _buildSettingsCard(
              children: [
                _buildNavigationTile(
                  icon: Icons.lock_outline_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: isEn ? 'Security & Permissions' : 'Quyền truy cập & Bảo mật',
                  subtitle: isEn
                      ? 'Camera, photo library, storage'
                      : 'Camera, thư viện ảnh, lưu trữ',
                  onTap: () => _showPermissionsDialog(context),
                ),
                _buildDivider(),
                _buildSwitchTile(
                  icon: Icons.analytics_outlined,
                  iconColor: const Color(0xFF6366F1),
                  title: isEn ? 'Usage Data Sharing' : 'Chia sẻ dữ liệu trải nghiệm',
                  subtitle: isEn
                      ? 'Helps improve AI styling suggestions'
                      : 'Hỗ trợ tối ưu hóa gợi ý AI Stylist',
                  value: _analyticsEnabled,
                  onChanged: (val) {
                    setState(() => _analyticsEnabled = val);
                    _saveNotificationPref('pref_analytics_enabled', val);
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 3. Trợ Giúp & Hỗ Trợ (Help & Support)
            _buildSectionHeader(
              title: isEn ? 'HELP & SUPPORT' : 'TRỢ GIÚP & HỖ TRỢ',
              icon: Icons.help_outline_rounded,
            ),
            _buildSettingsCard(
              children: [
                _buildNavigationTile(
                  icon: Icons.quiz_outlined,
                  iconColor: const Color(0xFF06B6D4),
                  title: isEn ? 'Frequently Asked Questions (FAQ)' : 'Câu hỏi thường gặp (FAQ)',
                  subtitle: isEn
                      ? 'Tips, styling guides, wardrobe setup'
                      : 'Mẹo sử dụng, hướng dẫn số hóa tủ đồ',
                  onTap: () => _showFaqModal(context),
                ),
                _buildDivider(),
                _buildNavigationTile(
                  icon: Icons.headset_mic_outlined,
                  iconColor: const Color(0xFFEC4899),
                  title: isEn ? 'Contact Support' : 'Liên hệ hỗ trợ',
                  subtitle: 'support@wearsy.app • 1900 6868',
                  onTap: () => _showContactModal(context),
                ),
                _buildDivider(),
                _buildNavigationTile(
                  icon: Icons.bug_report_outlined,
                  iconColor: const Color(0xFFEF4444),
                  title: isEn ? 'Report Bug & Feedback' : 'Báo lỗi & Góp ý cải tiến',
                  subtitle: isEn
                      ? 'Help make WEARSY better'
                      : 'Cùng chung tay hoàn thiện WEARSY',
                  onTap: () => _showFeedbackModal(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 4. Điều Khoản & Pháp Lý (Terms & Legal)
            _buildSectionHeader(
              title: isEn ? 'TERMS & LEGAL' : 'ĐIỀU KHOẢN & PHÁP LÝ',
              icon: Icons.description_outlined,
            ),
            _buildSettingsCard(
              children: [
                _buildNavigationTile(
                  icon: Icons.article_outlined,
                  iconColor: const Color(0xFF64748B),
                  title: isEn ? 'Terms of Service' : 'Điều khoản sử dụng',
                  subtitle: isEn ? 'User agreements & terms' : 'Quy định và thỏa thuận sử dụng',
                  onTap: () => _showTermsModal(context),
                ),
                _buildDivider(),
                _buildNavigationTile(
                  icon: Icons.verified_user_outlined,
                  iconColor: const Color(0xFF64748B),
                  title: isEn ? 'Privacy Policy' : 'Chính sách bảo mật',
                  subtitle: isEn
                      ? 'How WEARSY protects your information'
                      : 'Cách WEARSY bảo vệ dữ liệu của bạn',
                  onTap: () => _showPrivacyPolicyModal(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 5. Thông Tin Ứng Dụng (App Information)
            _buildSectionHeader(
              title: isEn ? 'APP INFORMATION' : 'THÔNG TIN ỨNG DỤNG',
              icon: Icons.info_outline_rounded,
            ),
            _buildSettingsCard(
              children: [
                _buildNavigationTile(
                  icon: Icons.star_rate_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: isEn ? 'Rate WEARSY on App Store' : 'Đánh giá ứng dụng WEARSY',
                  subtitle: isEn
                      ? 'Share your experience with others'
                      : 'Đánh giá 5 sao tiếp sức đội ngũ phát triển',
                  onTap: () => _showRateDialog(context),
                ),
                _buildDivider(),
                _buildInfoTile(
                  icon: Icons.code_rounded,
                  iconColor: const Color(0xFF6B7280),
                  title: isEn ? 'App Version' : 'Phiên bản ứng dụng',
                  subtitle: 'v1.2.0 (Build 2026.10 - Latest)',
                ),
                _buildDivider(),
                _buildNavigationTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: AppTheme.primaryColor,
                  title: isEn ? 'About WEARSY' : 'Về WEARSY Studio',
                  subtitle: isEn
                      ? 'Smart digital wardrobe & AI fashion assistant'
                      : 'Tủ đồ số & Trợ lý phong cách thông minh',
                  onTap: () => _showAboutModal(context),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 6. Nút Đăng Xuất (Log Out)
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFEF4444),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded,
                    color: Color(0xFFEF4444), size: 20),
                label: Text(
                  isEn ? 'Log Out' : 'Đăng Xuất Khỏi Tài Khoản',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFEF4444),
                  ),
                ),
                onPressed: () => _confirmLogout(context),
              ),
            ),

            const SizedBox(height: 28),

            // Footer branding
            Center(
              child: Column(
                children: [
                  Text(
                    'WEARSY 2026 • Your Wardrobe, Smarter',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Crafted with ❤️ by WEARSY Team',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFFD1D5DB),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildSectionHeader({required String title, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF3F4F6),
      indent: 60,
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: iconColor.withOpacity(0.08),
      highlightColor: iconColor.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            if (trailingText != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trailingText,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9CA3AF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: AppTheme.primaryColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Modals & Dialogs ---

  void _showLanguageModal(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isEn = langProvider.isEnglish;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isEn ? 'Choose Language' : 'Chọn Ngôn Ngữ',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 16),
              _buildLanguageOption(
                context: sheetCtx,
                flag: '🇻🇳',
                name: 'Tiếng Việt',
                shortCode: 'vi',
                isSelected: langProvider.isVietnamese,
                onTap: () {
                  langProvider.setLanguage('vi');
                  Navigator.pop(sheetCtx);
                },
              ),
              const SizedBox(height: 10),
              _buildLanguageOption(
                context: sheetCtx,
                flag: '🇬🇧',
                name: 'English',
                shortCode: 'en',
                isSelected: langProvider.isEnglish,
                onTap: () {
                  langProvider.setLanguage('en');
                  Navigator.pop(sheetCtx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String flag,
    required String name,
    required String shortCode,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.08)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : const Color(0xFF111827),
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded,
                  color: AppTheme.primaryColor, size: 22),
          ],
        ),
      ),
    );
  }

  void _showNotificationsModal(BuildContext context) {
    final isEn = Provider.of<LanguageProvider>(context, listen: false).isEnglish;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isEn ? 'Notification Settings 🔔' : 'Cài Đặt Thông Báo 🔔',
                  style: GoogleFonts.outfit(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isEn
                      ? 'Customize alerts and reminders for your wardrobe'
                      : 'Tùy chỉnh các thông báo và nhắc nhở thời trang',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 18),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppTheme.primaryColor,
                  title: Text(
                    isEn ? 'Daily Outfit Suggestions' : 'Gợi ý outfit mỗi sáng',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 14.5),
                  ),
                  subtitle: Text(
                    isEn
                        ? 'Receive smart combination picks at 07:00 AM'
                        : 'Nhận gợi ý phối đồ thông minh lúc 7:00 sáng',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: const Color(0xFF6B7280)),
                  ),
                  value: _dailyOutfitReminder,
                  onChanged: (val) {
                    setModalState(() => _dailyOutfitReminder = val);
                    setState(() => _dailyOutfitReminder = val);
                    _saveNotificationPref('pref_daily_outfit_reminder', val);
                  },
                ),
                const Divider(),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppTheme.primaryColor,
                  title: Text(
                    isEn ? 'Smart Weather Styling' : 'Cập nhật thời tiết thông minh',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 14.5),
                  ),
                  subtitle: Text(
                    isEn
                        ? 'Alert when rain or temperature shifts suddenly'
                        : 'Nhắc nhở khi trời mưa, nhiệt độ thay đổi đột ngột',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: const Color(0xFF6B7280)),
                  ),
                  value: _weatherSmartAlerts,
                  onChanged: (val) {
                    setModalState(() => _weatherSmartAlerts = val);
                    setState(() => _weatherSmartAlerts = val);
                    _saveNotificationPref('pref_weather_smart_alerts', val);
                  },
                ),
                const Divider(),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppTheme.primaryColor,
                  title: Text(
                    isEn ? 'Fashion Tips & Deals' : 'Mẹo thời trang & Ưu đãi',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 14.5),
                  ),
                  subtitle: Text(
                    isEn
                        ? 'New trends and WEARSY PREMIUM promotions'
                        : 'Xu hướng mới và ưu đãi WEARSY PREMIUM',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: const Color(0xFF6B7280)),
                  ),
                  value: _promotionUpdates,
                  onChanged: (val) {
                    setModalState(() => _promotionUpdates = val);
                    setState(() => _promotionUpdates = val);
                    _saveNotificationPref('pref_promotion_updates', val);
                  },
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(modalCtx),
                    child: Text(
                      isEn ? 'Done' : 'Hoàn Tất',
                      style: GoogleFonts.outfit(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPermissionsDialog(BuildContext context) {
    final isEn = Provider.of<LanguageProvider>(context, listen: false).isEnglish;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.security_rounded,
                  color: Color(0xFF10B981), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isEn ? 'Device Permissions' : 'Quyền Truy Cập Thiết Bị',
                style: GoogleFonts.outfit(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPermissionItem(
              icon: Icons.camera_alt_outlined,
              title: isEn ? 'Camera' : 'Máy ảnh',
              description: isEn
                  ? 'Used to snap photos of your clothes for digital wardrobe scanning.'
                  : 'Dùng để chụp ảnh quần áo thực tế để AI tách nền và đưa vào tủ đồ số.',
            ),
            const SizedBox(height: 12),
            _buildPermissionItem(
              icon: Icons.photo_library_outlined,
              title: isEn ? 'Photo Library' : 'Thư viện hình ảnh',
              description: isEn
                  ? 'Used to import clothing images and profile avatars.'
                  : 'Dùng để chọn ảnh trang phục sẵn có hoặc đổi avatar cá nhân.',
            ),
            const SizedBox(height: 12),
            _buildPermissionItem(
              icon: Icons.notifications_active_outlined,
              title: isEn ? 'Notifications' : 'Thông báo hệ thống',
              description: isEn
                  ? 'Sends styling reminders and daily weather outfit tips.'
                  : 'Nhận thông báo nhắc nhở phối đồ thông minh mỗi ngày.',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              isEn ? 'Close' : 'Đã Hiểu',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF4B5563)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: const Color(0xFF111827)),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                    height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFaqModal(BuildContext context) {
    final isEn = Provider.of<LanguageProvider>(context, listen: false).isEnglish;

    final List<Map<String, String>> faqs = isEn
        ? [
            {
              'q': 'How do I add clothes to my digital wardrobe?',
              'a':
                  'Go to Wardrobe tab, tap "+" button, choose Camera or Gallery. WEARSY AI will automatically detect category, colors, and isolate the background for you.'
            },
            {
              'q': 'How does the AI Stylist generate outfit recommendations?',
              'a':
                  'AI Stylist uses deep color harmony matching, your current local weather (temperature & humidity), and your personal style preferences.'
            },
            {
              'q': 'What benefits are included in WEARSY PREMIUM?',
              'a':
                  'Unlimited wardrobe items, unlimited smart AI Stylist combinations, deep body shape & skin-tone color analysis, and prioritized AI processing speed.'
            },
            {
              'q': 'How can I change my password or profile info?',
              'a':
                  'Go to Profile > Account & Security to update your name, email, password, and manage linked social accounts.'
            },
          ]
        : [
            {
              'q': 'Làm thế nào để thêm quần áo vào tủ đồ số?',
              'a':
                  'Vào mục Tủ Đồ, nhấn biểu tượng dấu "+" ở giữa, chọn chụp ảnh hoặc tải từ thư viện. AI của WEARSY sẽ tự động nhận diện danh mục, màu sắc và tách nền studio cho bạn.'
            },
            {
              'q': 'AI Stylist phối đồ dựa trên những tiêu chí nào?',
              'a':
                  'AI Stylist kết hợp bảng màu cá nhân của bạn, điều kiện thời tiết thực tế tại vị trí hiện tại (nhiệt độ, nắng/mưa) và sở thích phong cách (Smart Casual, Minimalist,...).'
            },
            {
              'q': 'Gói WEARSY PREMIUM có những quyền lợi gì?',
              'a':
                  'Không giới hạn số món đồ trong tủ, gợi ý phối đồ AI không giới hạn, phân tích vóc dáng & sắc tố da chuyên sâu cùng tốc độ AI ưu tiên cao nhất.'
            },
            {
              'q': 'Làm sao để đổi mật khẩu và cập nhật thông tin cá nhân?',
              'a':
                  'Bạn vào mục Cá nhân > Tài khoản & bảo mật để chỉnh sửa họ tên, ngày sinh, đổi mật khẩu và liên kết tài khoản Google/Facebook.'
            },
          ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEn ? 'Frequently Asked Questions (FAQ)' : 'Câu Hỏi Thường Gặp (FAQ)',
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: faqs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: ExpansionTile(
                      shape: const Border(),
                      title: Text(
                        faqs[i]['q']!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, bottom: 14),
                          child: Text(
                            faqs[i]['a']!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF4B5563),
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactModal(BuildContext context) {
    final isEn = Provider.of<LanguageProvider>(context, listen: false).isEnglish;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEn ? 'Contact & Support 💬' : 'Liên Hệ & Hỗ Trợ 💬',
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isEn
                    ? 'Our team is available 24/7 to assist you'
                    : 'Đội ngũ hỗ trợ WEARSY luôn sẵn sàng giải đáp thắc mắc',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 18),
              _buildContactTile(
                icon: Icons.email_outlined,
                iconColor: const Color(0xFF3B82F6),
                title: 'Email',
                value: 'support@wearsy.app',
              ),
              const SizedBox(height: 10),
              _buildContactTile(
                icon: Icons.phone_in_talk_outlined,
                iconColor: const Color(0xFF10B981),
                title: isEn ? 'Hotline' : 'Đường dây nóng',
                value: '1900 6868 (8:00 - 21:00)',
              ),
              const SizedBox(height: 10),
              _buildContactTile(
                icon: Icons.public_rounded,
                iconColor: const Color(0xFF8B5CF6),
                title: 'Website',
                value: 'https://wearsy.app',
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(sheetCtx),
                  child: Text(
                    isEn ? 'Close' : 'Đóng',
                    style: GoogleFonts.outfit(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFF6B7280)),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFeedbackModal(BuildContext context) {
    final isEn = Provider.of<LanguageProvider>(context, listen: false).isEnglish;
    final feedbackController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEn ? 'Feedback & Bug Report 💡' : 'Báo Lỗi & Góp Ý Cải Tiến 💡',
              style: GoogleFonts.outfit(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isEn
                  ? 'Tell us what you encountered or suggestions to improve WEARSY'
                  : 'Hãy chia sẻ lỗi bạn gặp phải hoặc ý tưởng giúp WEARSY hoàn thiện hơn',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              style: GoogleFonts.inter(color: const Color(0xFF111827)),
              decoration: InputDecoration(
                hintText: isEn
                    ? 'Write your feedback or bug details here...'
                    : 'Nhập nội dung góp ý hoặc mô tả lỗi chi tiết...',
                hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF), fontSize: 13.5),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEn
                            ? '💌 Thank you for your feedback! Our team will review it promptly.'
                            : '💌 Cảm ơn bạn đã gửi phản hồi! Đội ngũ WEARSY sẽ ghi nhận và cải thiện.',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      ),
                      backgroundColor: AppTheme.primaryColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                child: Text(
                  isEn ? 'Send Feedback' : 'Gửi Phản Hồi',
                  style: GoogleFonts.outfit(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsModal(BuildContext context) {
    final isEn = Provider.of<LanguageProvider>(context, listen: false).isEnglish;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEn ? 'Terms of Service' : 'Điều Khoản Sử Dụng WEARSY',
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(
                    isEn
                        ? '1. Acceptance of Terms\nBy creating an account or using WEARSY, you agree to these Terms of Service. If you disagree, please do not use the application.\n\n'
                            '2. Digital Wardrobe & AI Stylist\nAll clothing images uploaded are stored securely for personal wardrobe digitization. AI Stylist recommendations are suggestive and tailored to enhance your daily personal style.\n\n'
                            '3. Account Security\nYou are responsible for safeguarding your credentials and any activity conducted under your account.\n\n'
                            '4. Modifications\nWEARSY reserves the right to update or modify these terms at any time with prior notice through in-app alerts.'
                        : '1. Chấp thuận điều khoản\nKhi tạo tài khoản hoặc sử dụng ứng dụng WEARSY, bạn đồng ý tuân thủ toàn bộ các điều khoản dịch vụ này.\n\n'
                            '2. Quyền sở hữu tủ đồ & AI Stylist\nToàn bộ hình ảnh quần áo tải lên được mã hóa bảo mật phục vụ tủ đồ số cá nhân của bạn. Gợi ý từ AI Stylist mang tính chất tư vấn thẩm mỹ cá nhân hóa.\n\n'
                            '3. Bảo mật tài khoản\nNgười dùng có trách nhiệm bảo mật mật khẩu và thông tin đăng nhập của mình.\n\n'
                            '4. Cập nhật điều khoản\nWEARSY có quyền cập nhật các điều khoản dịch vụ để phù hợp với pháp luật và nâng cao chất lượng trải nghiệm.',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: const Color(0xFF4B5563),
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicyModal(BuildContext context) {
    final isEn = Provider.of<LanguageProvider>(context, listen: false).isEnglish;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEn ? 'Privacy Policy' : 'Chính Sách Bảo Mật Dữ Liệu',
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(
                    isEn
                        ? '1. Information We Collect\nWe collect profile details (name, email, birthdate), wardrobe images, and style preferences to generate personalized fashion recommendations.\n\n'
                            '2. How We Protect Your Images\nImages of your clothing are stored with secure SSL/TLS encryption. We never sell or share your private clothing photos with third parties for marketing purposes.\n\n'
                            '3. Data Retention & Deletion\nYou have complete control over your data. You may delete individual clothing items or permanently erase your entire account via Settings at any time.\n\n'
                            '4. Contact Us\nIf you have any questions regarding data protection, please email us at privacy@wearsy.app.'
                        : '1. Dữ liệu thu thập\nWEARSY thu thập thông tin tài khoản cơ bản (tên, email), hình ảnh trang phục và sở thích phong cách để phục vụ tính năng tủ đồ số và gợi ý phối đồ AI.\n\n'
                            '2. Cam kết bảo mật hình ảnh\nHình ảnh quần áo của bạn được mã hóa an toàn qua giao thức SSL/TLS tiêu chuẩn. Chúng tôi tuyệt đối không chia sẻ hình ảnh cá nhân cho bên thứ ba vì mục đích quảng cáo.\n\n'
                            '3. Quyền xóa dữ liệu\nBạn có toàn quyền xóa từng món đồ hoặc xóa vĩnh viễn tài khoản cùng toàn bộ dữ liệu bất kỳ lúc nào.\n\n'
                            '4. Liên hệ bảo mật\nMọi thắc mắc về quyền riêng tư, vui lòng gửi email về privacy@wearsy.app.',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: const Color(0xFF4B5563),
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRateDialog(BuildContext context) {
    final isEn = Provider.of<LanguageProvider>(context, listen: false).isEnglish;
    int selectedRating = 5;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isEn ? 'Rate WEARSY ⭐' : 'Đánh Giá WEARSY ⭐',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
                fontSize: 19, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEn
                    ? 'How has your experience with WEARSY been so far?'
                    : 'Trải nghiệm quản lý tủ đồ & AI Stylist của bạn như thế nào?',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13.5, color: const Color(0xFF6B7280)),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  return IconButton(
                    iconSize: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    icon: Icon(
                      starNum <= selectedRating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                    onPressed: () {
                      setDialogState(() => selectedRating = starNum);
                    },
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                isEn ? 'Later' : 'Để Sau',
                style: GoogleFonts.inter(color: const Color(0xFF6B7280)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEn
                          ? '🌟 Thank you for your $selectedRating-star review!'
                          : '🌟 Cảm ơn bạn đã đánh giá $selectedRating sao cho WEARSY!',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: AppTheme.primaryColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              child: Text(
                isEn ? 'Submit' : 'Gửi Đánh Giá',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutModal(BuildContext context) {
    final isEn = Provider.of<LanguageProvider>(context, listen: false).isEnglish;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.checkroom_rounded,
                    color: Colors.white, size: 34),
              ),
              const SizedBox(height: 14),
              Text(
                'WEARSY Fashion AI',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Version 1.2.0 • Build 2026.10',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isEn
                    ? 'WEARSY is your personalized digital wardrobe and smart AI fashion stylist. Effortlessly organize clothing, discover color palettes, and dress with confidence every single day.'
                    : 'WEARSY là nền tảng quản lý tủ đồ số hóa và trợ lý thời trang AI thông minh. Giúp bạn phân loại trang phục, khám phá bảng màu cá nhân và luôn tự tin với outfit mỗi ngày.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(sheetCtx),
                  child: Text(
                    isEn ? 'Close' : 'Đóng',
                    style: GoogleFonts.outfit(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final isEn = Provider.of<LanguageProvider>(context, listen: false).isEnglish;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded,
                  color: Color(0xFFEF4444), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isEn ? 'Log Out?' : 'Đăng Xuất Tài Khoản?',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          isEn
              ? 'Are you sure you want to log out of WEARSY? You can always log back in anytime.'
              : 'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng WEARSY không? Bạn có thể đăng nhập lại bất cứ lúc nào.',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: const Color(0xFF4B5563),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              isEn ? 'Cancel' : 'Hủy',
              style: GoogleFonts.inter(
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: Text(
              isEn ? 'Log Out' : 'Đăng Xuất',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
