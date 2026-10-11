class ApiConstants {
  // Base URL hỗ trợ truyền biến môi trường từ Render.com:
  // ví dụ: flutter run --dart-define=BACKEND_URL=https://wearsy-backend.onrender.com/v1
  static String get baseUrl {
    const envUrl = String.fromEnvironment('BACKEND_URL');
    // Backend API chính thức trên Render.com (PostgreSQL Supabase DB)
    return _customBaseUrl ?? 'https://wearsy-wd0c.onrender.com/v1';
  }
  static String? _customBaseUrl;
  static void setBaseUrl(String url) => _customBaseUrl = url;

  // Auth & Profile Endpoints
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String googleLogin = '/auth/google';
  static const String facebookLogin = '/auth/facebook';
  static const String profile = '/users/profile';
  static const String styleProfile = '/users/style-profile';
  static const String upgradeVip = '/users/upgrade-vip';

  // Digital Wardrobe Endpoints
  static const String wardrobeItems = '/wardrobe/items';
  static const String analyzeImage = '/wardrobe/analyze-image';
  static const String scanBulk = '/wardrobe/scan-bulk';
  static const String bulkCommit = '/wardrobe/bulk-commit';
  static const String removeBackground = '/wardrobe/remove-background';
  static const String uploadWardrobeImage = '/wardrobe/upload';

  // AI Outfits Endpoints
  static const String recommendOutfits = '/outfits/recommend';
  static const String recommendByContext = '/outfits/recommend-by-context';

  // Smart Shopping Endpoints
  static const String compatibilityCheck = '/shopping/compatibility-check';
  static const String missingItems = '/shopping/missing-items';

  // Gamification Endpoints
  static const String colorScore = '/gamification/color-score';
  static const String challenges = '/gamification/challenges';
}
