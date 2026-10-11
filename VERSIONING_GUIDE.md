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

### Bước 3: Build & Lưu trữ APK (Tự động giữ lại mọi bản cũ đề phòng)
Dự án có sẵn script tự động build và lưu trữ vào kho `releases/apk/`:
```bash
# Cách 1: Chạy file Batch (Khuyên dùng)
.\build_and_archive_apk.bat

# Hoặc Cách 2: Chạy script PowerShell
powershell -ExecutionPolicy Bypass -File .\build_and_archive_apk.ps1
```

Script sẽ tự động:
1. Đọc số version trong `app_version.dart`.
2. Build APK hoàn chỉnh (`flutter build apk`).
3. Sao chép và lưu thành: `releases/apk/wearsy-beta-X.Y.Z.apk`.
4. Cập nhật bản dùng nhanh: `releases/apk/wearsy-latest.apk`.
5. **ĐẶC BIỆT (ROLLBACK SAFETY):** Giữ nguyên vẹn toàn bộ các bản APK cũ trước đó (vd: `wearsy-beta-1.0.0.apk`, `wearsy-beta-1.0.1.apk`, ...). Tuyệt đối không xóa app cũ để người dùng hoặc lập trình viên có thể quay lui bất cứ lúc nào nếu app mới phát sinh lỗi.

> [!NOTE]
> File APK nhị phân (~213MB) được cấu hình trong `.gitignore` để không bị push lên GitHub (tránh lỗi giới hạn 100MB của GitHub), nhưng toàn bộ lịch sử file APK được lưu trữ đầy đủ tại máy tính cục bộ trong thư mục `releases/apk/`.

### Bước 4: Commit và Push mã nguồn lên Git
Commit kèm thông điệp rõ ràng theo chuẩn:
```bash
git add .
git commit -m "chore(release): bump mobile client to beta 1.0.x (Build N)"
git push origin main
git push origin feature/breakthrough-innovation
```

---

## 4. Danh mục lưu trữ APK & Chính sách Rollback (Bảo hiểm sự cố)

Tất cả các bản dựng APK được bảo lưu vĩnh viễn tại thư mục:
📂 `D:\wearsy\Wearsy\releases\apk\`

```text
releases/apk/
├── wearsy-beta-1.0.0.apk   <-- Bản gốc ban đầu (luôn giữ đề phòng)
├── wearsy-beta-1.0.1.apk   <-- Bản cập nhật kế tiếp
├── wearsy-beta-1.0.2.apk   <-- Bản cập nhật tiếp theo nữa
└── wearsy-latest.apk       <-- Shortcut trỏ tới bản mới nhất hiện tại
```

* **Khi app mới gặp sự cố:** Chỉ cần mở thư mục `releases/apk/` và cài lại file APK của phiên bản ổn định gần nhất trước đó.
* **Người dùng / Tester:** Luôn có thể lấy `wearsy-latest.apk` để trải nghiệm bản mới nhất mà không sợ mất bản cũ.

---

## 5. Lịch sử các phiên bản (Release Changelog)

| Phiên bản | Build | Ngày phát hành | Tác giả | Nội dung cập nhật chính |
| :--- | :---: | :---: | :--- | :--- |
| **beta 1.0.0** | **1** | 12/10/2026 | Võ Thế Đan & Đỗ Phúc Hậu | Mốc khởi đầu chính thức. Tích hợp AI Stylist Chat, bóc tách nền U2Net transparent PNG, phục dựng đồ thật Studio Lookbook, fix OTP email Resend, font chữ Montserrat tiếng Việt. |
| **beta 1.0.1** | **2** | 12/10/2026 | Đỗ Phúc Hậu & Võ Thế Đan | Sửa dứt điểm lỗi Tân trang AI (hỗ trợ Base64 từ bộ nhớ thiết bị sang AI Orchestrator), nâng cấp AI Stylist Chat thông minh (đọc danh sách đồ thật trong tủ, tư vấn mix match thời thượng, xóa bỏ câu trả lời rập khuôn, tăng timeout kết nối 25s). |
| **beta 1.0.2** | **3** | 12/10/2026 | Võ Thế Đan & Đỗ Phúc Hậu | Tích hợp bản sửa gửi OTP Gmail đáng tin cậy, nâng cấp giao diện Modal nhập OTP tương phản cao dễ đọc (nền sáng, chữ và mã số rõ nét), đồng bộ mượt mà cùng tính năng Tân trang AI & Stylist Chat. |
| **beta 1.0.3** | **4** | 12/10/2026 | Đỗ Phúc Hậu & Võ Thế Đan | Tích hợp dữ liệu thời trang Việt Nam (VN_Fashion_data) & Polyvore outfit compatibility, phân tích chuyên sâu vóc dáng từ Profile người dùng (chiều cao, cân nặng, BMI, dáng quả lê/đồng hồ cát/thước kẻ, quy tắc hack dáng Petite <1m58); giao diện thống kê tủ đồ realtime tương tác tab chuyển đổi và modal danh sách yêu thích; triệt tiêu hoàn toàn thiên kiến vẽ nhầm vest của ComfyUI; tự động đồng bộ link Cloudflare về Render. |
| **beta 1.0.4** | **5** | 12/10/2026 | Võ Thế Đan & Đỗ Phúc Hậu | Tích hợp bộ lọc tủ đồ thông minh (Wardrobe Filter Modal theo danh mục/màu sắc/phong cách), tính năng đổi tên bộ phối đồ (Outfit Rename), hệ thống tương tác cảm xúc Like/Dislike cho outfit gợi ý; cải tiến tách nền AI siêu nét (alpha matting + khử răng cưa viền mềm), tự động hủy URL Cloudflare chết trên Render; cơ chế cảnh báo lỗi kết nối rõ ràng trên điện thoại. |
| *beta 1.0.5* | *6* | *(Chờ cập nhật)* | | *(Dành cho bản cập nhật kế tiếp)* |
