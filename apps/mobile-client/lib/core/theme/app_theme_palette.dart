import 'package:flutter/material.dart';

/// Class đại diện cho Theme màu chuẩn của ứng dụng WEARSY (Theme 1).
/// Phong cách thiết kế: Wearsy Minimalist Studio
/// Tone màu: Trắng tinh giản (White canvas), Đen Obsidian (Primary), Xanh Sapphire (Accent UI), Đồng Hoàng Gia (Luxury VIP).
class AppThemePalette {
  final String id;
  final String name;
  final String description;
  final Color primary;
  final Color primaryLight;
  final Color secondary;
  final Color accent;
  final Color lightBackground;
  final Color cardColor;
  final Color surfaceColor;
  final Color textPrimary;
  final Color textSecondary;
  final LinearGradient primaryGradient;
  final LinearGradient accentGradient;

  const AppThemePalette({
    required this.id,
    required this.name,
    required this.description,
    required this.primary,
    required this.primaryLight,
    required this.secondary,
    this.accent = const Color(0xFF8A6728),
    required this.lightBackground,
    required this.cardColor,
    required this.surfaceColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.primaryGradient,
    required this.accentGradient,
  });

  // =========================================================================
  // THEME 1: Wearsy Minimalist Studio (Giao diện Mặc định duy nhất của WEARSY)
  // =========================================================================
  static const AppThemePalette theme1 = AppThemePalette(
    id: 'theme_1',
    name: 'Theme 1 - Wearsy Minimalist Studio (Mặc định)',
    description:
        'Tone trắng đen tối giản cao cấp, tinh tế chuẩn studio thời trang quốc tế',
    primary: Color(0xFF18181B), // Đen obsidian hiện đại (nút, thanh điều hướng, tiêu đề)
    primaryLight: Color(0xFF8A6728), // Nâu hoàng gia sang trọng (highlight, tab active, viền lựa chọn)
    secondary: Color(0xFF1E293B), // Xám than sâu
    accent: Color(0xFF8A6728), // Vàng đồng sang trọng (VIP card & Lưu outfit)
    lightBackground: Color(0xFFFFFFFF), // Nền trắng tinh khôi chuẩn studio
    cardColor: Color(0xFFF4F4F6), // Khối card xám nhạt hiện đại
    surfaceColor: Color(0xFFFFFFFF), // Bề mặt ô nhập / popup trắng
    textPrimary: Color(0xFF111827), // Chữ đen đậm nét
    textSecondary: Color(0xFF6B7280), // Chữ xám trung tính thanh lịch
    primaryGradient: LinearGradient(
      colors: [Color(0xFF18181B), Color(0xFF27272A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentGradient: LinearGradient(
      colors: [Color(0xFF8A6728), Color(0xFF6E521C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  /// Danh sách bộ theme chuẩn (Theme 1 là duy nhất và mặc định)
  static const List<AppThemePalette> allThemes = [
    theme1,
  ];

  /// Lấy palette theo id (mặc định trả về Theme 1)
  static AppThemePalette getById(String id) {
    return theme1;
  }
}
