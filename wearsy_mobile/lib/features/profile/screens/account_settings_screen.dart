import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class AccountSettingsScreen extends StatefulWidget {
  final int initialIndex;
  const AccountSettingsScreen({super.key, this.initialIndex = 0});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form Thông tin cá nhân
  final _profileFormKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  DateTime? _selectedBirthDate;
  String _selectedGender = 'Nam';
  bool _isSavingProfile = false;

  // Form Đổi mật khẩu
  final _passwordFormKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isChangingPassword = false;

  // Trạng thái liên kết & Nâng cấp VIP
  bool _isGoogleLinked = true;
  final _couponController = TextEditingController();
  bool _isUpgradingVip = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialIndex.clamp(0, 2),
    );

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _selectedBirthDate = DateTime(2002, 5, 20);
    _loadExtraProfileData(user?.email);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _loadExtraProfileData(String? email) async {
    if (email == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cleanEmail = email.trim().toLowerCase();
      final savedGender = prefs.getString('user_gender_$cleanEmail');
      final savedDateStr = prefs.getString('user_birthdate_$cleanEmail');
      if (mounted) {
        setState(() {
          if (savedGender != null && savedGender.isNotEmpty) {
            _selectedGender = savedGender;
          }
          if (savedDateStr != null) {
            final parsed = DateTime.tryParse(savedDateStr);
            if (parsed != null) _selectedBirthDate = parsed;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() => _isSavingProfile = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.updateUserInfo(
      fullName: _nameController.text.trim(),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = authProvider.user?.email.trim().toLowerCase();
      if (email != null) {
        await prefs.setString('user_gender_$email', _selectedGender);
        if (_selectedBirthDate != null) {
          await prefs.setString('user_birthdate_$email', _selectedBirthDate!.toIso8601String());
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isSavingProfile = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✨ Cập nhật thông tin cá nhân thành công!',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isChangingPassword = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.changePassword(
      oldPassword: _oldPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (mounted) {
      setState(() => _isChangingPassword = false);

      if (success) {
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🔒 Đổi mật khẩu thành công! Hãy dùng mật khẩu mới cho lần đăng nhập tới.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Đổi mật khẩu thất bại. Vui lòng kiểm tra lại.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cài Đặt Tài Khoản',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryLight,
          indicatorWeight: 3,
          labelColor: AppTheme.primaryLight,
          unselectedLabelColor: AppTheme.darkTextSecondary,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.person_rounded, size: 20), text: 'Thông Tin'),
            Tab(icon: Icon(Icons.lock_rounded, size: 20), text: 'Mật Khẩu'),
            Tab(icon: Icon(Icons.link_rounded, size: 20), text: 'Liên Kết'),
          ],
        ),
      ),
      body: Container(
        color: AppTheme.darkBackground,
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Thông tin cá nhân
            _buildProfileTab(user),

            // Tab 2: Đổi mật khẩu
            _buildPasswordTab(),

            // Tab 3: Liên kết tài khoản
            _buildLinkedAccountsTab(user),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _profileFormKey,
        child: Column(
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                    child: Text(
                      (user?.fullName.isNotEmpty == true)
                          ? user!.fullName[0].toUpperCase()
                          : 'W',
                      style: GoogleFonts.outfit(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Họ và tên
            _buildInputField(
              controller: _nameController,
              label: 'Họ và Tên',
              icon: Icons.badge_rounded,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
            ),
            const SizedBox(height: 16),

            // Email (ReadOnly with Verified Badge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email_rounded, color: AppTheme.primaryLight, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Địa chỉ Email',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.darkTextSecondary,
                          ),
                        ),
                        Text(
                          user?.email ?? 'demo@wearsy.app',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Đã xác thực',
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.greenAccent, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Giới tính
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Giới tính',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.darkTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Nam', 'Nữ', 'Khác'].map((g) {
                      final isSelected = _selectedGender == g;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(g),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryColor,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.darkTextSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _selectedGender = g);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ngày sinh
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedBirthDate ?? DateTime(2000),
                  firstDate: DateTime(1960),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _selectedBirthDate = date);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cake_rounded, color: AppTheme.primaryLight, size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ngày sinh',
                            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.darkTextSecondary),
                          ),
                          Text(
                            _selectedBirthDate != null
                                ? DateFormat('dd/MM/yyyy').format(_selectedBirthDate!)
                                : 'Chưa thiết lập',
                            style: GoogleFonts.inter(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.calendar_today_rounded, color: Colors.white54, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Nút Lưu
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: _isSavingProfile
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded, color: Colors.white),
                label: Text(
                  'Lưu Thay Đổi',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                onPressed: _isSavingProfile ? null : _saveProfile,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bảo Mật & Mật Khẩu 🔒',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              'Mật khẩu mới phải có tối thiểu 6 ký tự để bảo vệ tủ đồ và dữ liệu thời trang của bạn.',
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.darkTextSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),

            // Mật khẩu hiện tại
            _buildPasswordField(
              controller: _oldPasswordController,
              label: 'Mật khẩu hiện tại',
              obscureText: _obscureOldPassword,
              onToggleVisibility: () => setState(() => _obscureOldPassword = !_obscureOldPassword),
              validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu cũ' : null,
            ),
            const SizedBox(height: 16),

            // Mật khẩu mới
            _buildPasswordField(
              controller: _newPasswordController,
              label: 'Mật khẩu mới',
              obscureText: _obscureNewPassword,
              onToggleVisibility: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
              validator: (v) {
                if (v == null || v.length < 6) return 'Mật khẩu mới tối thiểu 6 ký tự';
                if (v == _oldPasswordController.text) return 'Mật khẩu mới không được trùng mật khẩu cũ';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Xác nhận mật khẩu mới
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'Xác nhận mật khẩu mới',
              obscureText: _obscureConfirmPassword,
              onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              validator: (v) {
                if (v != _newPasswordController.text) return 'Mật khẩu xác nhận không khớp';
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Nút Đổi mật khẩu
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: _isChangingPassword
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_rounded, color: Colors.white),
                label: Text(
                  'Cập Nhật Mật Khẩu',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                onPressed: _isChangingPassword ? null : _changePassword,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedAccountsTab(dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tài Khoản Liên Kết 🌐',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Liên kết tài khoản mạng xã hội để đăng nhập nhanh chóng bằng 1 cú chạm và đồng bộ an toàn.',
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.darkTextSecondary, height: 1.4),
          ),
          const SizedBox(height: 24),

          // Google
          _buildLinkedCard(
            title: 'Tài khoản Google',
            subtitle: _isGoogleLinked ? (user?.email ?? 'demo@wearsy.app') : 'Chưa liên kết',
            icon: Icons.g_mobiledata_rounded,
            iconColor: Colors.redAccent,
            isLinked: _isGoogleLinked,
            onToggle: () {
              setState(() => _isGoogleLinked = !_isGoogleLinked);
              _showLinkToast('Google', _isGoogleLinked);
            },
          ),

          const SizedBox(height: 32),
          const Divider(color: Colors.white12),
          const SizedBox(height: 24),

          // Nâng cấp gói VIP & Nhập Coupon
          _buildVipUpgradeSection(user),

          const SizedBox(height: 32),
          const Divider(color: Colors.white12),
          const SizedBox(height: 20),

          // Vùng Nguy Hiểm: Xóa tài khoản vĩnh viễn
          Text(
            'Vùng Nguy Hiểm ⚠️',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Khi xóa tài khoản, toàn bộ dữ liệu gồm tủ đồ số, các outfit AI đã phối, sở thích phong cách và thông tin tài khoản của bạn sẽ bị xóa vĩnh viễn và không thể khôi phục.',
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.darkTextSecondary, height: 1.4),
          ),
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentColor,
                side: const BorderSide(color: AppTheme.accentColor, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.delete_forever_rounded, size: 22),
              label: Text(
                'XÓA TÀI KHOẢN VĨNH VIỄN',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              onPressed: () => _confirmDeleteAccount(context),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.accentColor, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Xác nhận xóa tài khoản?',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Hành động này KHÔNG THỂ hoàn tác! Toàn bộ tủ đồ thông minh, outfits, lịch sử phong cách và dữ liệu tài khoản của bạn sẽ bị xóa vĩnh viễn khỏi hệ thống.',
          style: GoogleFonts.inter(color: AppTheme.darkTextSecondary, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('HỦY BỎ', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final success = await authProvider.deleteAccount();
              if (context.mounted) {
                if (success) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🗑️ Tài khoản của bạn đã được xóa vĩnh viễn khỏi hệ thống.'),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(authProvider.errorMessage ?? 'Xóa tài khoản thất bại.'),
                      backgroundColor: AppTheme.accentColor,
                    ),
                  );
                }
              }
            },
            child: Text('XÓA VĨNH VIỄN', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isLinked,
    required VoidCallback onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.darkTextSecondary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isLinked ? Colors.white.withValues(alpha: 0.1) : AppTheme.primaryColor,
              foregroundColor: isLinked ? Colors.white70 : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onToggle,
            child: Text(
              isLinked ? 'Hủy liên kết' : 'Liên kết',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showLinkToast(String provider, bool linked) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(linked ? '✅ Đã liên kết tài khoản $provider' : 'Đã hủy liên kết $provider'),
        backgroundColor: linked ? AppTheme.primaryColor : Colors.grey[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppTheme.darkTextSecondary),
        prefixIcon: Icon(icon, color: AppTheme.primaryLight, size: 22),
        filled: true,
        fillColor: AppTheme.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primaryLight),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: GoogleFonts.inter(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppTheme.darkTextSecondary),
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryLight, size: 22),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: Colors.white54,
            size: 20,
          ),
          onPressed: onToggleVisibility,
        ),
        filled: true,
        fillColor: AppTheme.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primaryLight),
        ),
      ),
    );
  }

  Widget _buildVipUpgradeSection(dynamic user) {
    final isVip = user != null && (user.hasActiveVip == true);
    final daysRemaining = user != null ? user.vipDaysRemaining : 0;
    final expiresAt = user?.vipExpiresAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFF1E1435),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nâng Cấp Gói VIP ✨',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Mở khóa toàn bộ đặc quyền AI Stylist và tủ đồ thời trang',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.darkTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // VIP Card Container
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isVip
                  ? [
                      const Color(0xFF2C194D),
                      const Color(0xFF1C1333),
                      const Color(0xFF281542),
                    ]
                  : [
                      const Color(0xFF1E1A33),
                      const Color(0xFF151324),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isVip
                  ? const Color(0xFFFFD700).withValues(alpha: 0.6)
                  : AppTheme.primaryLight.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isVip
                    ? const Color(0xFFFFD700).withValues(alpha: 0.15)
                    : AppTheme.primaryColor.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card: Tier badge + Expiry
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isVip
                              ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isVip ? Icons.stars_rounded : Icons.star_border_rounded,
                          color: isVip ? const Color(0xFFFFD700) : Colors.white70,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VIP Fashionista',
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            isVip
                                ? 'Còn $daysRemaining ngày sử dụng'
                                : 'Tài khoản Tiêu chuẩn',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isVip ? const Color(0xFFFFD700) : AppTheme.darkTextSecondary,
                              fontWeight: isVip ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isVip
                          ? Colors.greenAccent.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isVip
                            ? Colors.greenAccent.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      isVip ? 'ĐANG KÍCH HOẠT' : 'CHƯA KÍCH HOẠT',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isVip ? Colors.greenAccent : Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              if (isVip && expiresAt != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule_rounded, color: Color(0xFFFFD700), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Thời hạn VIP đến: ${DateFormat('dd/MM/yyyy - HH:mm').format(expiresAt)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),
              const Divider(color: Colors.white12),
              const SizedBox(height: 14),

              // Đặc quyền VIP
              Text(
                'Đặc quyền gói VIP:',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 10),
              _buildVipPerkItem('Không giới hạn số lượng món đồ trong tủ đồ số'),
              const SizedBox(height: 8),
              _buildVipPerkItem('AI Stylist gợi ý phối đồ thông minh không giới hạn'),
              const SizedBox(height: 8),
              _buildVipPerkItem('Phân tích bảng màu cá nhân & vóc dáng chuyên sâu'),
              const SizedBox(height: 8),
              _buildVipPerkItem('Ưu tiên xử lý AI tốc độ cao & mẫu phối độc quyền'),

              const SizedBox(height: 20),
              const Divider(color: Colors.white12),
              const SizedBox(height: 16),

              // Ô nhập Coupon
              Text(
                'Nhập mã Coupon ưu đãi:',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _couponController,
                textCapitalization: TextCapitalization.characters,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                decoration: InputDecoration(
                  hintText: 'Nhập mã (VD: WEARSY)',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 13,
                    letterSpacing: 0,
                  ),
                  prefixIcon: const Icon(
                    Icons.confirmation_number_outlined,
                    color: AppTheme.primaryLight,
                    size: 20,
                  ),
                  suffixIcon: _couponController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Colors.white38, size: 18),
                          onPressed: () {
                            setState(() {
                              _couponController.clear();
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.primaryLight, width: 1.5),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),

              // Nút Nâng cấp VIP
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isUpgradingVip ? null : _handleUpgradeVip,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFFF59E0B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: _isUpgradingVip
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.stars_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  isVip ? 'GIA HẠN THÊM VIP 7 NGÀY' : 'KÍCH HOẠT VIP 7 NGÀY',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Tip coupon text
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.card_giftcard_rounded, color: AppTheme.primaryLight, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                          children: [
                            const TextSpan(text: 'Nhập mã '),
                            TextSpan(
                              text: 'WEARSY',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFFD700),
                              ),
                            ),
                            const TextSpan(text: ' để nhận ngay 7 ngày VIP miễn phí!'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVipPerkItem(String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Color(0xFF10B981),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 12),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleUpgradeVip() async {
    final coupon = _couponController.text.trim().toUpperCase();
    if (coupon.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng nhập mã Coupon.', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.accentColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (coupon != 'WEARSY') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mã Coupon không hợp lệ. Vui lòng nhập đúng mã "WEARSY"!',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppTheme.accentColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isUpgradingVip = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.upgradeVip(coupon);
    setState(() => _isUpgradingVip = false);

    if (!mounted) return;

    if (success) {
      _couponController.clear();
      _showVipSuccessDialog(context, authProvider.user);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Nâng cấp VIP thất bại. Vui lòng thử lại.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppTheme.accentColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showVipSuccessDialog(BuildContext context, dynamic user) {
    final expiryDateStr = user?.vipExpiresAt != null
        ? DateFormat('dd/MM/yyyy - HH:mm').format(user!.vipExpiresAt!)
        : '7 ngày tới';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1435),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFF1E1435),
                size: 46,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '🎉 NÂNG CẤP VIP THÀNH CÔNG!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Chúc mừng bạn đã kích hoạt gói VIP Fashionista trong 7 ngày bằng mã Coupon WEARSY!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Gói hội viên:',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
                      ),
                      Text(
                        'VIP Fashionista 👑',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hạn sử dụng:',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
                      ),
                      Text(
                        expiryDateStr,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: const Color(0xFF1E1435),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(
                  'TRẢI NGHIỆM NGAY',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
