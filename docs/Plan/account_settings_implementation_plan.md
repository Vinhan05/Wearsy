# Kế Hoạch Triển Khai: Màn Hình Cài Đặt Tài Khoản & Chỉnh Sửa Thông Tin

Kế hoạch bổ sung nút mở form chỉnh sửa thông tin ngay trên thẻ người dùng tại tab **Hồ sơ**, bao gồm:
1. **Nút chỉnh sửa trực tiếp** trên thẻ người dùng (Profile Header Card).
2. **Màn hình `AccountSettingsScreen`** chuyên nghiệp, chia thành 3 phân vùng quản lý:
   - **Thông tin cá nhân:** Đổi họ tên, số điện thoại, ngày sinh, giới tính, đổi avatar.
   - **Đổi mật khẩu:** Mật khẩu cũ, mật khẩu mới, xác nhận mật khẩu (kèm nút ẩn/hiện và kiểm tra độ mạnh).
   - **Quản lý liên kết tài khoản:** Trạng thái kết nối Google, Facebook, Apple ID.

---

## 1. Chi Tiết Giao Diện & Tính Năng

### A. Thẻ Người Dùng (`profile_screen.dart`):
- Bổ sung nút **`Chỉnh sửa` (Icon bút chì ✏️)** nổi bật ở góc phải trên thẻ User.
- Cả thẻ có thể chạm vào (`InkWell`) để mở nhanh màn hình cài đặt tài khoản.

### B. Màn Hình Mới: `AccountSettingsScreen`
- **Tab 1: Thông Tin Cá Nhân (Personal Info):**
  - Avatar người dùng kèm nút camera thay đổi ảnh đại diện.
  - Form nhập:
    - Họ và tên
    - Email (có nhãn *Đã xác thực OTP*)
    - Số điện thoại
    - Giới tính (Nam / Nữ / Khác)
    - Ngày sinh
  - Nút **Lưu Thay Đổi** (cập nhật đồng bộ vào `AuthProvider` và lưu phiên làm việc).
- **Tab 2: Đổi Mật Khẩu (Security & Password):**
  - Mật khẩu hiện tại
  - Mật khẩu mới (tối thiểu 6 ký tự)
  - Xác nhận mật khẩu mới
  - Nút **Đổi Mật Khẩu** (kiểm tra khớp mật khẩu, hiển thị SnackBar thành công).
- **Tab 3: Tài Khoản Liên Kết (Linked Accounts):**
  - **Google:** Đã liên kết (hiển thị email tài khoản Google).
  - **Facebook:** Công tắc / Nút bấm Liên kết hoặc Hủy liên kết.
  - **Apple ID:** Tùy chọn kết nối bảo mật Apple.

---

## 2. Các File Sẽ Được Tạo & Sửa Đổi

### [NEW] [`lib/features/profile/screens/account_settings_screen.dart`](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/wearsy_mobile/lib/features/profile/screens/account_settings_screen.dart)
- Xây dựng giao diện màn hình cài đặt tài khoản toàn diện, thiết kế Dark Mode cao cấp chuẩn phong cách WEARSY.

### [MODIFY] [`lib/features/profile/screens/profile_screen.dart`](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/wearsy_mobile/lib/features/profile/screens/profile_screen.dart)
- Thêm nút và sự kiện điều hướng mở `AccountSettingsScreen`.

### [MODIFY] [`lib/features/auth/providers/auth_provider.dart`](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/wearsy_mobile/lib/features/auth/providers/auth_provider.dart)
- Thêm phương thức `updateUserInfo(...)` để cập nhật họ tên và thông tin người dùng.

---

## 3. Kế Hoạch Xác Minh

- Chạy `dart analyze` đảm bảo không có lỗi lint/cú pháp.
- Đóng gói APK và cập nhật lên máy ảo Android Studio.
- Mở tab **Hồ sơ** -> Bấm nút chỉnh sửa trên thẻ -> Thử đổi họ tên (ví dụ: đổi thành `Nguyễn Tuấn Kiệt`) -> Bấm Lưu -> Kiểm tra xem màn hình Hồ sơ và Trang chủ có cập nhật tên mới ngay lập tức không.
- Thử nghiệm form Đổi mật khẩu và chuyển đổi trạng thái Liên kết tài khoản.
