# 📱 QUY ƯỚC ĐÁNH SỐ PHIÊN BẢN APK WEARSY (MOBILE CLIENT)

> **Dành cho:** Tất cả lập trình viên và các **AI Coding Agents** (Antigravity, Gemini, Cursor, Copilot...) tham gia phát triển dự án WEARSY.

---

## 1. Chuẩn phiên bản hiện tại (Mốc khởi đầu)
* **Tên phiên bản:** `beta 1.0.0`
* **Mã build (Build Number):** `1`
* **File APK tương ứng:** `app-debug.apk`

---

## 2. Quy tắc tăng phiên bản (Strict Versioning Increment)
Mỗi khi có cập nhật tính năng, sửa lỗi hoặc xuất bản bản build APK mới:
1. **Quy tắc cộng dồn:** Phiên bản kế tiếp **BẮT BUỘC** phải tăng theo thứ tự:
   * Bản hiện tại: `beta 1.0.0` (Build 1)
   * Bản tiếp theo: `beta 1.0.1` (Build 2)
   * Bản tiếp theo nữa: `beta 1.0.2` (Build 3)
   * Bản tiếp theo nữa: `beta 1.0.3` (Build 4)
   * ...và tiếp tục tăng dần đều (+0.0.1 cho version và +1 cho build number).

2. **Khi nào tăng số Minor (vd: beta 1.1.0)?**
   * Chỉ tăng lên `beta 1.1.0` khi phát hành một nhóm tính năng lớn đột phá (Major breakthrough feature) hoặc hoàn tất một cột mốc Sprint lớn và được cả hai đồng tác giả thống nhất.

---

## 3. Các bước cần làm khi nâng cấp phiên bản (Dành cho AI Agent & Devs)

Trước khi chạy lệnh `flutter build apk`:

### Bước 1: Cập nhật file `apps/mobile-client/pubspec.yaml`
Tìm dòng `version:` ở đầu file và tăng lên:
```yaml
# Ví dụ nâng từ 1.0.0+1 lên 1.0.1+2:
version: 1.0.1+2
```

### Bước 2: Cập nhật file `apps/mobile-client/lib/core/constants/app_version.dart`
Cập nhật hằng số hiển thị tương ứng:
```dart
class AppVersion {
  static const String versionName = 'beta 1.0.1'; // Tăng lên 1.0.1
  static const int buildNumber = 2;               // Tăng lên 2
  static const String releaseDate = '10/2026';
  static const String fullDisplay = '$versionName (Build $buildNumber)';
  static const String shortDisplay = versionName;
}
```

### Bước 3: Build APK
Chạy lệnh biên dịch:
```bash
cd apps/mobile-client
flutter build apk --debug
```

File APK sẽ được sinh ra tại:
* `apps/mobile-client/build/app/outputs/flutter-apk/app-debug.apk`
* `apps/mobile-client/build/app/outputs/apk/debug/app-debug.apk`

### Bước 4: Commit và Push lên Git
Commit kèm thông điệp rõ ràng theo chuẩn:
```bash
git add .
git commit -m "chore(release): bump mobile client to beta 1.0.x (Build N)"
git push origin main
git push origin feature/breakthrough-innovation
```

---

## 4. Lịch sử các phiên bản (Release Changelog)

| Phiên bản | Build | Ngày phát hành | Tác giả | Nội dung cập nhật chính |
| :--- | :---: | :---: | :--- | :--- |
| **beta 1.0.0** | **1** | 12/10/2026 | Võ Thế Đan & Đỗ Phúc Hậu | Mốc khởi đầu chính thức. Tích hợp AI Stylist Chat, bóc tách nền U2Net transparent PNG, phục dựng đồ thật Studio Lookbook, fix OTP email Resend, font chữ Montserrat tiếng Việt. |
| *beta 1.0.1* | *2* | *(Chờ cập nhật)* | | *(Dành cho bản cập nhật kế tiếp)* |
