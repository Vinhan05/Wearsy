import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/localization/localization.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';

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

  void _showVipModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.diamond_rounded,
                    color: Color(0xFF8A6728), size: 28),
                const SizedBox(width: 10),
                Text(
                  'WEARSY VIP PASS',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Mở khóa trọn bộ tính năng AI Stylist không giới hạn, phối đồ đa bối cảnh thời gian thực và tự động quản lý tủ đồ chuẩn studio.',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: const Color(0xFF4B5563),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8A6728),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kích hoạt VIP ngay (Trải nghiệm)',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
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
        await prefs.setString(
            'user_custom_name_$email', _nameController.text.trim());
        await prefs.setString('user_gender_$email', _selectedGender);
        if (_selectedBirthDate != null) {
          await prefs.setString(
              'user_birthdate_$email', _selectedBirthDate!.toIso8601String());
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ??
                  'Đổi mật khẩu thất bại. Vui lòng kiểm tra lại.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context); // Listen to Theme changes
    final langProvider = Provider.of<LanguageProvider>(context);
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          langProvider.isVietnamese ? 'Cài Đặt Tài Khoản' : 'Account Settings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: Center(
              child: LanguageToggleButton(style: LanguageToggleStyle.compact),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryLight,
          indicatorWeight: 3,
          labelColor: AppTheme.primaryLight,
          unselectedLabelColor: AppTheme.darkTextSecondary,
          labelStyle:
              GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              icon: const Icon(Icons.person_rounded, size: 20),
              text: langProvider.isVietnamese ? 'Thông Tin' : 'Profile',
            ),
            Tab(
              icon: const Icon(Icons.lock_rounded, size: 20),
              text: langProvider.isVietnamese ? 'Mật Khẩu' : 'Password',
            ),
            Tab(
              icon: const Icon(Icons.link_rounded, size: 20),
              text: langProvider.isVietnamese ? 'Liên Kết' : 'Linked',
            ),
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

  Future<void> _pickAvatarImage() async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isEn = langProvider.isEnglish;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEn ? 'Update Profile Picture 📸' : 'Cập nhật Ảnh đại diện 📸',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkTextPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F5FC),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt_rounded,
                      color: AppTheme.primaryColor),
                ),
                title: Text(
                    isEn ? 'Take Photo from Camera' : 'Chụp ảnh từ Máy ảnh',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkTextPrimary)),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final picker = ImagePicker();
                  final XFile? image = await picker.pickImage(
                      source: ImageSource.camera, imageQuality: 85);
                  if (!mounted) return;
                  if (image != null) {
                    await Provider.of<AuthProvider>(context, listen: false)
                        .updateAvatar(image.path);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            isEn
                                ? '📸 Profile picture updated successfully!'
                                : '📸 Cập nhật ảnh đại diện thành công!',
                            style: GoogleFonts.inter()),
                        backgroundColor: AppTheme.primaryColor,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F5FC),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_library_rounded,
                      color: AppTheme.primaryColor),
                ),
                title: Text(
                    isEn ? 'Choose from Photo Library' : 'Chọn từ Thư viện ảnh',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkTextPrimary)),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final picker = ImagePicker();
                  final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery, imageQuality: 85);
                  if (!mounted) return;
                  if (image != null) {
                    await Provider.of<AuthProvider>(context, listen: false)
                        .updateAvatar(image.path);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            isEn
                                ? '🖼️ Profile picture updated successfully!'
                                : '🖼️ Cập nhật ảnh đại diện thành công!',
                            style: GoogleFonts.inter()),
                        backgroundColor: AppTheme.primaryColor,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab(dynamic user) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final isEn = langProvider.isEnglish;
    final wardrobeProvider = Provider.of<WardrobeProvider>(context);
    final totalItems = wardrobeProvider.allItemsAcrossAllWardrobes.length;

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
                  const UserAvatar(
                    radius: 46,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickAvatarImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
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
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Họ và tên
            _buildInputField(
              controller: _nameController,
              label: isEn ? 'Full Name' : 'Họ và Tên',
              icon: Icons.badge_rounded,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? (isEn ? 'Please enter full name' : 'Vui lòng nhập họ tên')
                  : null,
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
                  Icon(Icons.email_rounded,
                      color: AppTheme.primaryLight, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn ? 'Email Address' : 'Địa chỉ Email',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.darkTextSecondary,
                          ),
                        ),
                        Text(
                          user?.email ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.greenAccent.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded,
                            color: Colors.greenAccent, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          isEn ? 'Verified' : 'Đã xác thực',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold),
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
                border: Border.all(
                    color: AppTheme.darkTextSecondary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEn ? 'Gender' : 'Giới tính',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.darkTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      {'key': 'Nam', 'label': isEn ? 'Male' : 'Nam'},
                      {'key': 'Nữ', 'label': isEn ? 'Female' : 'Nữ'},
                      {'key': 'Khác', 'label': isEn ? 'Other' : 'Khác'},
                    ].map((g) {
                      final key = g['key']!;
                      final label = g['label']!;
                      final isSelected = _selectedGender == key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryColor,
                          backgroundColor: AppTheme.darkTextSecondary
                              .withValues(alpha: 0.05),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.darkTextPrimary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _selectedGender = key);
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.darkTextSecondary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cake_rounded,
                        color: AppTheme.primaryLight, size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEn ? 'Date of Birth' : 'Ngày sinh',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.darkTextSecondary),
                          ),
                          Text(
                            _selectedBirthDate != null
                                ? DateFormat('dd/MM/yyyy')
                                    .format(_selectedBirthDate!)
                                : (isEn ? 'Not set' : 'Chưa thiết lập'),
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppTheme.darkTextPrimary,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.calendar_today_rounded,
                        color: AppTheme.darkTextSecondary, size: 18),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: _isSavingProfile
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded, color: Colors.white),
                label: Text(
                  isEn ? 'Save Changes' : 'Lưu Thay Đổi',
                  style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                onPressed: _isSavingProfile ? null : _saveProfile,
              ),
            ),
            const SizedBox(height: 20),

            // Wearsy VIP Upgrade Banner (Chuyển vào Cài đặt)
            GestureDetector(
              onTap: () => _showVipModal(context),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8A6728), Color(0xFF6E521C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8A6728).withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 16),
                child: Row(
                  children: [
                    const Icon(Icons.diamond_rounded,
                        size: 34, color: Colors.white),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEn ? 'UPGRADE' : 'NÂNG CẤP',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            'Wearsy VIP',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isEn
                                ? 'Unlock advanced personalized experience.'
                                : 'Mở khóa trải nghiệm cá nhân hóa nâng cao.',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 16, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Section Reset Tủ Đồ
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.delete_sweep_rounded,
                            color: AppTheme.accentColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEn
                                  ? 'Reset Wardrobe (Empty Account)'
                                  : 'Reset Tủ Đồ (Tài Khoản Trắng)',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkTextPrimary,
                              ),
                            ),
                            Text(
                              isEn
                                  ? 'Delete all clothing items to start fresh with an empty wardrobe.'
                                  : 'Xóa tất cả trang phục để bắt đầu lại với tủ đồ trống hoàn toàn.',
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
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentColor,
                        side: BorderSide(
                            color: AppTheme.accentColor.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.delete_forever_rounded, size: 18),
                      label: Text(
                        isEn
                            ? 'Reset All Clothes ($totalItems items)'
                            : 'Reset Tất Cả Quần Áo ($totalItems món đồ)',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      onPressed: () => _confirmResetWardrobe(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmResetWardrobe(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isEn = langProvider.isEnglish;
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
              isEn ? 'Reset Empty Wardrobe?' : 'Reset Tủ Đồ Trắng?',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: const Color(0xFF2C2849),
              ),
            ),
          ],
        ),
        content: Text(
          isEn
              ? 'This action will delete all clothes in your wardrobe and reset your account to an empty wardrobe (0 items).\n\nAre you sure you want to reset?'
              : 'Thao tác này sẽ xóa sạch tất cả quần áo trong tủ đồ của bạn và chuyển tài khoản về trạng thái tủ đồ trắng (0 món đồ).\n\nBạn có chắc chắn muốn reset không?',
          style: GoogleFonts.inter(
              fontSize: 14, color: const Color(0xFF5F597C), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              isEn ? 'Cancel' : 'Hủy',
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
              await Provider.of<WardrobeProvider>(context, listen: false)
                  .clearAllItems();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEn
                          ? '✨ Wardrobe reset successfully! Your account now has an empty wardrobe (0 clothes).'
                          : '✨ Đã reset tủ đồ thành công! Tài khoản của bạn hiện là tủ đồ trắng (0 quần áo).',
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
              isEn ? 'Confirm Reset' : 'Xác Nhận Reset',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordTab() {
    final langProvider = Provider.of<LanguageProvider>(context);
    final isEn = langProvider.isEnglish;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEn ? 'Security & Password 🔒' : 'Bảo Mật & Mật Khẩu 🔒',
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkTextPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              isEn
                  ? 'New password must be at least 6 characters long to protect your wardrobe and style data.'
                  : 'Mật khẩu mới phải có tối thiểu 6 ký tự để bảo vệ tủ đồ và dữ liệu thời trang của bạn.',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppTheme.darkTextSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),

            // Mật khẩu hiện tại
            _buildPasswordField(
              controller: _oldPasswordController,
              label: isEn ? 'Current Password' : 'Mật khẩu hiện tại',
              obscureText: _obscureOldPassword,
              onToggleVisibility: () =>
                  setState(() => _obscureOldPassword = !_obscureOldPassword),
              validator: (v) =>
                  (v == null || v.isEmpty) ? (isEn ? 'Please enter current password' : 'Vui lòng nhập mật khẩu cũ') : null,
            ),
            const SizedBox(height: 16),

            // Mật khẩu mới
            _buildPasswordField(
              controller: _newPasswordController,
              label: isEn ? 'New Password' : 'Mật khẩu mới',
              obscureText: _obscureNewPassword,
              onToggleVisibility: () =>
                  setState(() => _obscureNewPassword = !_obscureNewPassword),
              validator: (v) {
                if (v == null || v.length < 6) {
                  return isEn ? 'New password must be at least 6 characters' : 'Mật khẩu mới tối thiểu 6 ký tự';
                }
                if (v == _oldPasswordController.text) {
                  return isEn ? 'New password cannot match old password' : 'Mật khẩu mới không được trùng mật khẩu cũ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Xác nhận mật khẩu mới
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: isEn ? 'Confirm New Password' : 'Xác nhận mật khẩu mới',
              obscureText: _obscureConfirmPassword,
              onToggleVisibility: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
              validator: (v) {
                if (v != _newPasswordController.text) {
                  return isEn ? 'Password confirmation does not match' : 'Mật khẩu xác nhận không khớp';
                }
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: _isChangingPassword
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_rounded,
                        color: Colors.white),
                label: Text(
                  isEn ? 'Update Password' : 'Cập Nhật Mật Khẩu',
                  style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
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
    final langProvider = Provider.of<LanguageProvider>(context);
    final isEn = langProvider.isEnglish;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEn ? 'Linked Accounts 🌐' : 'Tài Khoản Liên Kết 🌐',
            style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkTextPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            isEn
                ? 'Link your social accounts for quick 1-tap sign in and secure syncing.'
                : 'Liên kết tài khoản mạng xã hội để đăng nhập nhanh chóng bằng 1 cú chạm và đồng bộ an toàn.',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppTheme.darkTextSecondary, height: 1.4),
          ),
          const SizedBox(height: 24),

          // Google
          _buildLinkedCard(
            title: isEn ? 'Google Account' : 'Tài khoản Google',
            subtitle: _isGoogleLinked
                ? (user?.email ?? '')
                : (isEn ? 'Not linked' : 'Chưa liên kết'),
            icon: Icons.g_mobiledata_rounded,
            iconColor: Colors.redAccent,
            isLinked: _isGoogleLinked,
            onToggle: () {
              setState(() => _isGoogleLinked = !_isGoogleLinked);
              _showLinkToast('Google', _isGoogleLinked);
            },
          ),

          const SizedBox(height: 32),
          Divider(color: AppTheme.darkTextPrimary.withValues(alpha: 0.12)),
          const SizedBox(height: 24),

          // Nâng cấp gói VIP & Nhập Coupon
          _buildVipUpgradeSection(user),

          const SizedBox(height: 32),
          Divider(color: AppTheme.darkTextPrimary.withValues(alpha: 0.12)),
          const SizedBox(height: 20),

          // Vùng Nguy Hiểm: Xóa tài khoản vĩnh viễn
          Text(
            isEn ? 'Danger Zone ⚠️' : 'Vùng Nguy Hiểm ⚠️',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isEn
                ? 'Deleting your account will permanently wipe all your digital wardrobe data, AI outfits, style history, and profile information.'
                : 'Khi xóa tài khoản, toàn bộ dữ liệu gồm tủ đồ số, các outfit AI đã phối, sở thích phong cách và thông tin tài khoản của bạn sẽ bị xóa vĩnh viễn và không thể khôi phục.',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppTheme.darkTextSecondary, height: 1.4),
          ),
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentColor,
                side: BorderSide(color: AppTheme.accentColor, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.delete_forever_rounded, size: 22),
              label: Text(
                isEn ? 'DELETE ACCOUNT PERMANENTLY' : 'XÓA TÀI KHOẢN VĨNH VIỄN',
                style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5),
              ),
              onPressed: () => _confirmDeleteAccount(context),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isEn = langProvider.isEnglish;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppTheme.accentColor, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isEn ? 'Confirm Delete Account?' : 'Xác nhận xóa tài khoản?',
                style: GoogleFonts.outfit(
                    color: AppTheme.darkTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          isEn
              ? 'This action CANNOT be undone! All your smart wardrobe, outfits, style history and account data will be permanently removed from our servers.'
              : 'Hành động này KHÔNG THỂ hoàn tác! Toàn bộ tủ đồ thông minh, outfits, lịch sử phong cách và dữ liệu tài khoản của bạn sẽ bị xóa vĩnh viễn khỏi hệ thống.',
          style: GoogleFonts.inter(
              color: AppTheme.darkTextSecondary, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(isEn ? 'CANCEL' : 'HỦY BỎ',
                style: GoogleFonts.inter(
                    color: AppTheme.darkTextPrimary.withValues(alpha: 0.70),
                    fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final success = await authProvider.deleteAccount();
              if (context.mounted) {
                if (success) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          isEn
                              ? '🗑️ Your account has been permanently deleted.'
                              : '🗑️ Tài khoản của bạn đã được xóa vĩnh viễn khỏi hệ thống.'),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(authProvider.errorMessage ??
                          (isEn ? 'Failed to delete account.' : 'Xóa tài khoản thất bại.')),
                      backgroundColor: AppTheme.accentColor,
                    ),
                  );
                }
              }
            },
            child: Text(isEn ? 'DELETE PERMANENTLY' : 'XÓA VĨNH VIỄN',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
                  style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkTextPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppTheme.darkTextSecondary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isLinked
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : AppTheme.primaryColor,
              foregroundColor:
                  isLinked ? AppTheme.darkTextSecondary : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onToggle,
            child: Text(
              isLinked
                  ? (Provider.of<LanguageProvider>(context, listen: false).isEnglish
                      ? 'Unlink'
                      : 'Hủy liên kết')
                  : (Provider.of<LanguageProvider>(context, listen: false).isEnglish
                      ? 'Link'
                      : 'Liên kết'),
              style:
                  GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showLinkToast(String provider, bool linked) {
    final isEn = Provider.of<LanguageProvider>(context, listen: false).isEnglish;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(linked
            ? (isEn ? '✅ Linked $provider account' : '✅ Đã liên kết tài khoản $provider')
            : (isEn ? 'Unlinked $provider account' : 'Đã hủy liên kết $provider')),
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
      style: GoogleFonts.inter(color: AppTheme.darkTextPrimary),
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
          borderSide: BorderSide(color: AppTheme.primaryLight),
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
      style: GoogleFonts.inter(color: AppTheme.darkTextPrimary),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppTheme.darkTextSecondary),
        prefixIcon: Icon(Icons.lock_outline_rounded,
            color: AppTheme.primaryLight, size: 22),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: AppTheme.darkTextPrimary.withValues(alpha: 0.54),
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
          borderSide: BorderSide(color: AppTheme.primaryLight),
        ),
      ),
    );
  }

  Widget _buildVipUpgradeSection(dynamic user) {
    final isEn = Provider.of<LanguageProvider>(context).isEnglish;
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
                    isEn ? 'Upgrade VIP Plan ✨' : 'Nâng Cấp Gói VIP ✨',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkTextPrimary,
                    ),
                  ),
                  Text(
                    isEn
                        ? 'Unlock all AI Stylist privileges & smart wardrobe'
                        : 'Mở khóa toàn bộ đặc quyền AI Stylist và tủ đồ thời trang',
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
                      AppTheme.primaryColor.withValues(alpha: 0.08),
                      const Color(0xFFFFD700).withValues(alpha: 0.08),
                    ]
                  : [
                      AppTheme.darkCard,
                      AppTheme.darkCard,
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isVip
                  ? const Color(0xFFFFD700).withValues(alpha: 0.5)
                  : AppTheme.darkTextSecondary.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isVip
                    ? const Color(0xFFFFD700).withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: 15,
                offset: const Offset(0, 5),
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
                              : AppTheme.darkBackground,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isVip
                              ? Icons.stars_rounded
                              : Icons.star_border_rounded,
                          color: isVip
                              ? const Color(0xFFD4AF37)
                              : AppTheme.darkTextSecondary,
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
                              color: AppTheme.darkTextPrimary,
                            ),
                          ),
                          Text(
                            isVip
                                ? (isEn
                                    ? '$daysRemaining days remaining'
                                    : 'Còn $daysRemaining ngày sử dụng')
                                : (isEn
                                    ? 'Standard Account'
                                    : 'Tài khoản Tiêu chuẩn'),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isVip
                                  ? const Color(0xFFD4AF37)
                                  : AppTheme.darkTextSecondary,
                              fontWeight:
                                  isVip ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isVip
                          ? Colors.greenAccent.withValues(alpha: 0.1)
                          : AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isVip
                            ? Colors.greenAccent.withValues(alpha: 0.3)
                            : AppTheme.darkTextSecondary
                                .withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(
                      isVip
                          ? (isEn ? 'ACTIVE' : 'ĐANG KÍCH HOẠT')
                          : (isEn ? 'INACTIVE' : 'CHƯA KÍCH HOẠT'),
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color:
                            isVip ? Colors.green : AppTheme.darkTextSecondary,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          color: Color(0xFFD4AF37), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isEn
                              ? 'VIP Expires: ${DateFormat('dd/MM/yyyy - HH:mm').format(expiresAt)}'
                              : 'Thời hạn VIP đến: ${DateFormat('dd/MM/yyyy - HH:mm').format(expiresAt)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.darkTextPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),
              Divider(color: AppTheme.darkTextPrimary.withValues(alpha: 0.12)),
              const SizedBox(height: 14),

              // Đặc quyền VIP
              Text(
                isEn ? 'VIP Privileges:' : 'Đặc quyền gói VIP:',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkTextPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _buildVipPerkItem(
                  isEn
                      ? 'Unlimited items in digital wardrobe'
                      : 'Không giới hạn số lượng món đồ trong tủ đồ số'),
              const SizedBox(height: 8),
              _buildVipPerkItem(
                  isEn
                      ? 'Unlimited AI Stylist smart outfit suggestions'
                      : 'AI Stylist gợi ý phối đồ thông minh không giới hạn'),
              const SizedBox(height: 8),
              _buildVipPerkItem(
                  isEn
                      ? 'Deep personal color palette & body shape analysis'
                      : 'Phân tích bảng màu cá nhân & vóc dáng chuyên sâu'),
              const SizedBox(height: 8),
              _buildVipPerkItem(
                  isEn
                      ? 'High-speed AI priority processing & exclusive templates'
                      : 'Ưu tiên xử lý AI tốc độ cao & mẫu phối độc quyền'),

              const SizedBox(height: 20),
              Divider(color: AppTheme.darkTextPrimary.withValues(alpha: 0.12)),
              const SizedBox(height: 16),

              // Ô nhập Coupon
              Text(
                isEn ? 'Enter promo coupon code:' : 'Nhập mã Coupon ưu đãi:',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _couponController,
                textCapitalization: TextCapitalization.characters,
                style: GoogleFonts.outfit(
                  color: AppTheme.darkTextPrimary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                decoration: InputDecoration(
                  hintText: isEn ? 'Enter code (e.g. WEARSY)' : 'Nhập mã (VD: WEARSY)',
                  hintStyle: GoogleFonts.inter(
                    color: AppTheme.darkTextPrimary.withValues(alpha: 0.38),
                    fontSize: 13,
                    letterSpacing: 0,
                  ),
                  prefixIcon: Icon(
                    Icons.confirmation_number_outlined,
                    color: AppTheme.primaryLight,
                    size: 20,
                  ),
                  suffixIcon: _couponController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded,
                              color: AppTheme.darkTextPrimary
                                  .withValues(alpha: 0.38),
                              size: 18),
                          onPressed: () {
                            setState(() {
                              _couponController.clear();
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.darkBackground,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color:
                            AppTheme.darkTextSecondary.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color:
                            AppTheme.darkTextSecondary.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: AppTheme.primaryLight, width: 1.5),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isUpgradingVip ? null : _handleUpgradeVip,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF8B5CF6),
                          Color(0xFFEC4899),
                          Color(0xFFF59E0B)
                        ],
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
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: AppTheme.darkTextPrimary,
                                  strokeWidth: 2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.stars_rounded,
                                    color: AppTheme.darkTextPrimary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  isVip
                                      ? (isEn
                                          ? 'EXTEND VIP FOR 1 YEAR'
                                          : 'GIA HẠN THÊM VIP 1 NĂM')
                                      : (isEn
                                          ? 'ACTIVATE 1 YEAR VIP'
                                          : 'KÍCH HOẠT VIP 1 NĂM'),
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkTextPrimary,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.primaryLight.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.card_giftcard_rounded,
                        color: AppTheme.primaryLight, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.darkTextPrimary
                                  .withValues(alpha: 0.70)),
                          children: [
                            TextSpan(text: isEn ? 'Enter code ' : 'Nhập mã '),
                            TextSpan(
                              text: 'WEARSY',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFFD700),
                              ),
                            ),
                            TextSpan(
                                text: isEn
                                    ? ' to get 1 year free VIP!'
                                    : ' để nhận ngay 1 năm VIP miễn phí!'),
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
          child: Icon(Icons.check, color: AppTheme.darkTextPrimary, size: 12),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.darkTextPrimary,
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            authProvider.errorMessage ??
                'Nâng cấp VIP thất bại. Vui lòng thử lại.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppTheme.accentColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showVipSuccessDialog(BuildContext context, dynamic user) {
    final expiryDateStr = user?.vipExpiresAt != null
        ? DateFormat('dd/MM/yyyy - HH:mm').format(user!.vipExpiresAt!)
        : '1 năm tới';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFF3F3E5A),
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '🎉 NÂNG CẤP VIP THÀNH CÔNG!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3F3E5A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chúc mừng bạn đã kích hoạt gói VIP Fashionista trong 1 năm bằng mã Coupon WEARSY!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF4A4B6B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F5FC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E0F5)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Gói hội viên:',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF4A4B6B),
                        ),
                      ),
                      Text(
                        'VIP Fashionista 👑',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD4AF37),
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
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF4A4B6B),
                        ),
                      ),
                      Text(
                        expiryDateStr,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3F3E5A),
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
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
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
