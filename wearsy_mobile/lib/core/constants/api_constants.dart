class ApiConstants {
  // Base URL:
  //   Android Emulator → 10.0.2.2 (maps to host machine's localhost)
  //   iOS Simulator / macOS → localhost or 127.0.0.1
  //   Physical device → actual machine IP on local network
  static const String baseUrl = 'http://10.0.2.2:8000/v1';

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
