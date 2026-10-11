# Implementation Plan - WEARSY Mobile App (Flutter)

Xây dựng ứng dụng di động **WEARSY** bằng Flutter theo mô hình kiến trúc sạch (Clean Architecture), tập trung trước hết vào phân hệ **Authentication (Đăng nhập / Đăng ký)** & **Hồ sơ cá nhân & Phong cách (User Profile & Style Profile)** kết nối trực tiếp với backend RESTful API.

## User Review Required

> [!IMPORTANT]
> - Dự án sẽ được khởi tạo tại thư mục `wearsy_mobile/` trong workspace.
> - Sử dụng Google Fonts (Inter / Outfit) kết hợp với bảng màu hiện đại (Deep Violet / Obsidian Glassmorphism) để mang lại trải nghiệm WOW trực quan.
> - Thiết lập cấu trúc API Client hỗ trợ JWT Authentication Header `Authorization: Bearer <token>` tương thích chính xác với Backend NestJS (`http://localhost:8000/v1`).

## Proposed Changes

### 1. Flutter Project Foundation (`wearsy_mobile/`)

#### [NEW] [pubspec.yaml](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/wearsy_mobile/pubspec.yaml)
Khai báo thông tin app, cấu hình SDK, dependencies (http, provider, google_fonts, shared_preferences, intl, flutter_spinkit).

#### [NEW] [main.dart](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/wearsy_mobile/lib/main.dart)
Entrypoint chính ứng dụng, khởi tạo AuthProvider, cấu hình Routing và Theme.

---

### 2. Core Layer (`lib/core/`)

#### [NEW] [api_constants.dart](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/wearsy_mobile/lib/core/constants/api_constants.dart)
Định nghĩa Base URLs (`http://localhost:8000/v1`), endpoints (`/auth/login`, `/auth/register`, `/users/profile`, `/users/style-profile`).

#### [NEW] [app_theme.dart](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/wearsy_mobile/lib/core/theme/app_theme.dart)
Hệ thống Design System với HSL Dark & Light Mode, màu chủ đạo Purple/Violet gradient, glassmorphism card theme, custom inputs.

#### [NEW] [api_client.dart](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/wearsy_mobile/lib/core/network/api_client.dart)
Tầng xử lý gọi HTTP request (GET, POST, PUT, DELETE), tự động gắn Bearer JWT token và chuẩn hóa phản hồi theo định dạng API WEARSY (`{ success, code, data, error }`).

#### [NEW] [token_storage.dart](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/wearsy_mobile/lib/core/storage/token_storage.dart)
Quản lý lưu vết token và dữ liệu phiên làm việc người dùng qua `shared_preferences`.

---

### 3. Auth & Profile Features (`lib/features/`)

#### [NEW] [user_model.dart](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/wearsy_mobile/lib/features/auth/models/user_model.dart)
Data models cho `UserModel`, `AuthSuccessResponse` (khớp chính xác với OpenAPI schema).

#### [NEW] [auth_service.dart](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/wearsy_mobile/lib/features/auth/services/auth_service.dart)
Tầng giao tiếp API cho `login()`, `register()`, `getProfile()`.

#### [NEW] [auth_provider.dart](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/wearsy_mobile/lib/features/auth/providers/auth_provider.dart)
State Management bằng `ChangeNotifier` quản lý trạng thái đăng nhập, lưu thông tin user, thông báo lỗi.

#### [NEW] [login_screen.dart](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/wearsy_mobile/lib/features/auth/screens/login_screen.dart)
Giao diện Đăng nhập sang trọng, form validation, nút gradient với hiệu ứng loading.

#### [NEW] [register_screen.dart](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/wearsy_mobile/lib/features/auth/screens/register_screen.dart)
Giao diện Đăng ký tài khoản mới (Họ tên, Email, Mật khẩu, Xác nhận mật khẩu).

#### [NEW] [style_profile_model.dart](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/wearsy_mobile/lib/features/profile/models/style_profile_model.dart)
Model cho Hồ sơ phong cách cá nhân (Preferred styles, color preferences, budget, body measurements).

#### [NEW] [profile_screen.dart](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/wearsy_mobile/lib/features/profile/screens/profile_screen.dart)
Giao diện Hồ sơ cá nhân: Hiển thị thông tin user, phong cách ưa thích, ngân sách, số đo, nút Đăng xuất.

#### [NEW] [edit_style_profile_screen.dart](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/wearsy_mobile/lib/features/profile/screens/edit_style_profile_screen.dart)
Giao diện cập nhật Hồ sơ phong cách cá nhân với các thẻ style chip selectable, màu sắc yêu thích, khoảng giá mua sắm.

#### [NEW] [main_navigation_screen.dart](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/wearsy_mobile/lib/features/home/screens/main_navigation_screen.dart)
Thanh Bottom Navigation tổng quan ứng dụng (Home, Wardrobe, AI Outfits, Profile).

#### [NEW] [dashboard_screen.dart](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/wearsy_mobile/lib/features/home/screens/dashboard_screen.dart)
Màn hình trang chủ với Banner chào mừng, Lối tắt AI Stylist, Tủ đồ nhanh và Thử thách phối màu.

---

## Verification Plan

### Automated Verification
- Kiểm tra cú pháp Dart và cấu trúc file trong thư mục `wearsy_mobile`.
- Đảm bảo tất cả các dữ liệu gửi lên và trả về khớp với định dạng RESTful API đặc tả trong `docs/openapi.yaml`.

### Manual Verification
- Hướng dẫn chạy `flutter run` hoặc xem trước ứng dụng Flutter trên Android Studio / VS Code / Flutter Web.
