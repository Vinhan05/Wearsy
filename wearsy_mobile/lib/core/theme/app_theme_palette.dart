import 'package:flutter/material.dart';

/// Class đại diện cho một bộ Theme màu của ứng dụng WEARSY.
/// Theme 1 là giao diện hiện tại của ứng dụng.
/// Người dùng có thể dễ dàng thêm hoặc chỉnh sửa mã màu của các Theme 2, 3, 4, 5 bên dưới.
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
    this.accent = const Color(0xFFFF5252),
    required this.lightBackground,
    required this.cardColor,
    required this.surfaceColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.primaryGradient,
    required this.accentGradient,
  });

  // =========================================================================
  // THEME 1: Tím Lavender (Giao diện hiện tại của ứng dụng)
  // =========================================================================
  static const AppThemePalette theme1 = AppThemePalette(
    id: 'theme_1',
    name: 'Theme 1 - Tím Lavender (Mặc định)',
    description: 'Tone tím lavender nhận diện thương hiệu nguyên bản của WEARSY',
    primary: Color(0xFF8174DB),
    primaryLight: Color(0xFF9E94E8),
    secondary: Color(0xFF00CEC9),
    accent: Color(0xFFFF5252),
    lightBackground: Color(0xFFF3F1FA),
    cardColor: Color(0xFFEBE7F7),
    surfaceColor: Color(0xFFF4F1FD),
    textPrimary: Color(0xFF2C2849),
    textSecondary: Color(0xFF6E698F),
    primaryGradient: LinearGradient(
      colors: [Color(0xFF8D80ED), Color(0xFF7464CF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentGradient: LinearGradient(
      colors: [Color(0xFF8174DB), Color(0xFF6B5BCD)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // =========================================================================
  // THEME 2: Xanh Hoàng Gia & Nâu Cacao (Blue Royal & Mocha Espresso)
  // Trích xuất trực tiếp từ thiết kế wearsy UI/2.png (wearsy-signup-blue-royal)
  // =========================================================================
  static const AppThemePalette theme2 = AppThemePalette(
    id: 'theme_2',
    name: 'Theme 2 - Xanh Hoàng Gia & Nâu Cacao (Blue Royal)',
    description: 'Tone xanh hoàng gia nhạt phối nâu cacao cổ điển, sang trọng và thanh lịch theo thiết kế 2.png',
    primary: Color(0xFF543D37),        // Nâu cacao / espresso đậm (nút chính, logo W, tiêu đề Wearsy)
    primaryLight: Color(0xFF8EBAE5),   // Xanh hoàng gia pastel (viền ô input, icon AI, highlight)
    secondary: Color(0xFF6BA3E8),      // Xanh royal sapphire điểm nhấn
    accent: Color(0xFFD63031),         // Đỏ cảnh báo / xóa
    lightBackground: Color(0xFFFAF5F1),// Nền kem hạnh nhân ấm áp, thanh lịch
    cardColor: Color(0xFFF0E8E1),      // Nền khối thẻ card be sáng
    surfaceColor: Color(0xFFFCFAF7),   // Nền bên trong ô gõ chữ
    textPrimary: Color(0xFF432F2A),    // Chữ chính nâu đậm sang trọng (tương phản AAA > 11:1)
    textSecondary: Color(0xFF7A6A64),  // Chữ phụ nâu ấm thanh thoát
    primaryGradient: LinearGradient(
      colors: [Color(0xFF634942), Color(0xFF4A342E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentGradient: LinearGradient(
      colors: [Color(0xFFA5C8EC), Color(0xFF76A8DC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // =========================================================================
  // THEME 3: Tím Hoàng Gia (Deep Amethyst) - Bạn có thể tùy chỉnh màu tại đây
  // =========================================================================
  static const AppThemePalette theme3 = AppThemePalette(
    id: 'theme_3',
    name: 'Theme 3 - Tím Hoàng Gia',
    description: 'Tone tím đậm sang trọng, cuốn hút và cá tính',
    primary: Color(0xFF6C5CE7),
    primaryLight: Color(0xFFA29BFE),
    secondary: Color(0xFF74B9FF),
    accent: Color(0xFFFF5252),
    lightBackground: Color(0xFFF1F0FB),
    cardColor: Color(0xFFE4E1F8),
    surfaceColor: Color(0xFFF7F6FE),
    textPrimary: Color(0xFF231B4D),
    textSecondary: Color(0xFF5A5285),
    primaryGradient: LinearGradient(
      colors: [Color(0xFF7D6DF2), Color(0xFF5946DF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentGradient: LinearGradient(
      colors: [Color(0xFF6C5CE7), Color(0xFF4C3EC7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // =========================================================================
  // THEME 4: Xanh Bạc Hà (Mint Fresh) - Bạn có thể tùy chỉnh màu tại đây
  // =========================================================================
  static const AppThemePalette theme4 = AppThemePalette(
    id: 'theme_4',
    name: 'Theme 4 - Xanh Bạc Hà',
    description: 'Tone xanh mint mát mẻ, trẻ trung và tràn đầy năng lượng',
    primary: Color(0xFF00B894),
    primaryLight: Color(0xFF55EFC4),
    secondary: Color(0xFF0984E3),
    accent: Color(0xFFFF7675),
    lightBackground: Color(0xFFF0FDF8),
    cardColor: Color(0xFFDBF6EB),
    surfaceColor: Color(0xFFF4FEFA),
    textPrimary: Color(0xFF143B30),
    textSecondary: Color(0xFF4A7468),
    primaryGradient: LinearGradient(
      colors: [Color(0xFF26DE81), Color(0xFF00A381)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentGradient: LinearGradient(
      colors: [Color(0xFF00B894), Color(0xFF008A6F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // =========================================================================
  // THEME 5: Xanh Đại Dương (Ocean Blue) - Bạn có thể tùy chỉnh màu tại đây
  // =========================================================================
  static const AppThemePalette theme5 = AppThemePalette(
    id: 'theme_5',
    name: 'Theme 5 - Xanh Đại Dương',
    description: 'Tone xanh biển năng động, hiện đại và thanh lịch',
    primary: Color(0xFF0984E3),
    primaryLight: Color(0xFF74B9FF),
    secondary: Color(0xFF00CEC9),
    accent: Color(0xFFFF6B6B),
    lightBackground: Color(0xFFF0F7FD),
    cardColor: Color(0xFFDCEBFA),
    surfaceColor: Color(0xFFF4FAFE),
    textPrimary: Color(0xFF132F4C),
    textSecondary: Color(0xFF4A6B8A),
    primaryGradient: LinearGradient(
      colors: [Color(0xFF2E97EB), Color(0xFF026BC0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentGradient: LinearGradient(
      colors: [Color(0xFF0984E3), Color(0xFF0667B0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  /// Danh sách tất cả 5 bộ theme có sẵn
  static const List<AppThemePalette> allThemes = [
    theme1,
    theme2,
    theme3,
    theme4,
    theme5,
  ];

  /// Lấy palette theo id (mặc định trả về theme 1 nếu không tìm thấy)
  static AppThemePalette getById(String id) {
    return allThemes.firstWhere(
      (t) => t.id == id,
      orElse: () => theme1,
    );
  }
}
