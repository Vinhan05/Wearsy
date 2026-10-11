# WEARSY - Hoàn Thiện Mobile App Demo (Android Studio)

## Tổng Quan

Ứng dụng WEARSY đã có nền tảng Flutter cơ bản với Auth (Login/Register), Dashboard, và Profile. Mục tiêu là **hoàn thiện thành một demo app hoàn chỉnh** có thể chạy offline trên Android Emulator — nghĩa là loại bỏ phụ thuộc backend thực, thêm dữ liệu mock, và bổ sung các màn hình còn thiếu.

## User Review Required

> [!IMPORTANT]
> App hiện tại kết nối tới `http://localhost:8000/v1` (NestJS backend). Để demo trên điện thoại **không cần bật backend**, toàn bộ API sẽ được thay bằng **Mock Service** với dữ liệu giả thực tế. Nếu bạn muốn kết nối backend thật, hãy thông báo để điều chỉnh IP.

> [!WARNING]
> `api_constants.dart` cần đổi base URL sang `10.0.2.2:8000` để chạy trên Android Emulator (thay vì `localhost`). Bản demo này sẽ dùng mock data hoàn toàn.

## Phân Tích Hiện Trạng

| Màn hình | Trạng thái | Vấn đề |
|---|---|---|
| Splash/Loading | ✅ Có | OK |
| Login | ✅ Có | Cần gọi API thật → mock |
| Register | ✅ Có | Cần gọi API thật → mock |
| Dashboard | ✅ Có | Dữ liệu tĩnh, ảnh network |
| Tủ đồ (Wardrobe) | ❌ Placeholder | Cần xây dựng |
| AI Outfit | ❌ Placeholder | Cần xây dựng |
| Profile | ✅ Có | Cần mock data |
| Edit Style Profile | ✅ Có | Cần mock |

## Proposed Changes

---

### 1. Core — Mock Services & Offline Mode

#### [MODIFY] [api_client.dart](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/wearsy_mobile/lib/core/network/api_client.dart)
- Thêm timeout và error handling tốt hơn

#### [NEW] `lib/core/mock/mock_data_service.dart`
- Dữ liệu tĩnh: user profile, wardrobe items (10+ món), outfit suggestions (5+ bộ)
- Demo login: email `demo@wearsy.app` / password `123456` → luôn thành công
- `getWardrobeItems()`, `getOutfitSuggestions()`, `getWeatherInfo()`

#### [MODIFY] [auth_service.dart](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/wearsy_mobile/lib/features/auth/services/auth_service.dart)
- Bọc gọi API trong try/catch, fallback sang mock khi offline
- Demo mode: nếu email chứa `demo` → dùng mock user

---

### 2. Feature — Tủ Đồ Kỹ Thuật Số (Digital Wardrobe)

#### [NEW] `lib/features/wardrobe/models/wardrobe_item_model.dart`
- Model: id, name, category, color, imageUrl, brand, tags

#### [NEW] `lib/features/wardrobe/providers/wardrobe_provider.dart`
- State: danh sách items, filter theo category, loading

#### [NEW] `lib/features/wardrobe/screens/wardrobe_screen.dart`
- Grid view các món đồ với filter tabs (Tất cả / Áo / Quần / Giày / Phụ kiện)
- Mỗi item card có ảnh, tên, màu tag
- FAB để "thêm đồ" (mở dialog demo)

#### [NEW] `lib/features/wardrobe/screens/item_detail_screen.dart`
- Chi tiết 1 món đồ: ảnh lớn, thông tin, "Phối với AI" button

---

### 3. Feature — AI Outfit Suggestions

#### [NEW] `lib/features/outfits/models/outfit_model.dart`
- Model: id, name, items[], occasion, weatherSuitable, aiScore

#### [NEW] `lib/features/outfits/providers/outfit_provider.dart`
- State: danh sách outfits, loading, generate state

#### [NEW] `lib/features/outfits/screens/outfit_screen.dart`
- List các outfit AI đã gợi ý (cards với ảnh combo)
- "Tạo Outfit Mới" button → loading animation → hiện outfit mới
- Filter theo dịp (Đi làm / Đi chơi / Thể thao / Formal)

#### [NEW] `lib/features/outfits/screens/outfit_detail_screen.dart`
- Chi tiết outfit: danh sách items, AI Score, lý do phối đồ

---

### 4. Enhancement — Dashboard & Navigation

#### [MODIFY] [main_navigation_screen.dart](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/wearsy_mobile/lib/features/home/screens/main_navigation_screen.dart)
- Thay 2 `_PlaceholderScreen` bằng `WardrobeScreen` và `OutfitScreen` thật

#### [MODIFY] [dashboard_screen.dart](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/wearsy_mobile/lib/features/home/screens/dashboard_screen.dart)
- Kết nối wardrobe items từ provider (không hard-code)
- "Tạo Outfit" button navigate sang Outfit tab
- Thêm Recent Outfits section

#### [MODIFY] [main.dart](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/wearsy_mobile/lib/main.dart)
- Thêm `WardrobeProvider` và `OutfitProvider` vào MultiProvider

---

### 5. Assets & Setup

#### [NEW] `android/app/src/main/AndroidManifest.xml` — thêm INTERNET permission
#### [MODIFY] `pubspec.yaml`
- Thêm package `cached_network_image: ^3.3.1` (hiển thị ảnh mượt)
- Thêm `image_picker: ^1.0.7` (demo thêm đồ)

## Verification Plan

### Automated
```bash
cd wearsy_mobile
flutter pub get
flutter analyze
flutter build apk --debug
```

### Manual Verification (Android Studio)
1. Chạy trên Android Emulator (API 33+)
2. Màn hình splash → Login với `demo@wearsy.app` / `123456`
3. Kiểm tra Dashboard có data thật
4. Tab Tủ đồ: grid items, filter, click vào detail
5. Tab AI Outfit: list outfits, tạo outfit mới
6. Tab Profile: xem thông tin, đăng xuất

## Demo Flow

```
Splash → Login (demo@wearsy.app/123456) → Dashboard 
  → [Tủ Đồ] Xem grid, filter, detail
  → [AI Outfit] Xem gợi ý, tạo mới
  → [Profile] Xem hồ sơ → Đăng xuất
```
