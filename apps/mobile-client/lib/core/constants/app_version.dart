class AppVersion {
  /// Tên phiên bản hiện tại theo chuẩn quy ước dự án WEARSY (bắt đầu từ beta 1.0.0)
  static const String versionName = 'beta 1.0.9';

  /// Mã build tăng dần theo mỗi lần cập nhật (+1)
  static const int buildNumber = 10;

  /// Tháng phát hành
  static const String releaseDate = '10/2026';

  /// Chuỗi hiển thị đầy đủ trên giao diện Cài đặt & Thông tin ứng dụng
  static const String fullDisplay = '$versionName (Build $buildNumber)';

  /// Chuỗi hiển thị ngắn gọn
  static const String shortDisplay = versionName;
}
