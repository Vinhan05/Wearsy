# BẢN ĐẶC TẢ CHI TIẾT CÔNG THỨC MÀU SẮC, CƠ CHẾ ĐỔI THEME & HƯỚNG DẪN TẠO THEME MỚI (WEARSY)

> **Tài liệu chuẩn hóa hệ thống giao diện đa màu sắc (Dynamic Multi-Theme System) cho dự án WEARSY.**  
> File này cung cấp đầy đủ: Quy trình 1-chạm tạo theme từ ảnh, cơ chế kỹ thuật đồng bộ 100% toàn app, công thức toán học trích xuất màu, mã màu chi tiết của 5 Theme hiện có và danh mục các file mã nguồn liên quan.

---

## MỤC LỤC
1. [HƯỚNG DẪN 1-CHẠM: TẠO THEME MỚI TỪ ẢNH (DÀNH CHO NGƯỜI DÙNG & AI)](#1-hướng-dẫn-1-chạm-tạo-theme-mới-từ-ảnh-dành-cho-người-dùng--ai)
2. [CƠ CHẾ KỸ THUẬT ĐỔI MÀU TOÀN BỘ ỨNG DỤNG (LIVE DYNAMIC SWITCHING)](#2-cơ-chế-kỹ-thuật-đổi-màu-toàn-bộ-ứng-dụng-live-dynamic-switching)
3. [ĐỒNG BỘ HÓA ĐẶC BIỆT: MÀN HÌNH WELCOME & LOGIN / REGISTER](#3-đồng-bộ-hóa-đặc-biệt-màn-hình-welcome--login--register)
4. [BẢNG MÃ MÀU CHI TIẾT CỦA CẢ 5 BỘ THEME HIỆN CÓ](#4-bảng-mã-màu-chi-tiết-của-cả-5-bộ-theme-hiện-có)
5. [CÔNG THỨC TOÁN HỌC & NGUYÊN TẮC THIẾT KẾ THEME MỚI](#5-công-thức-toán-học--nguyên-tắc-thiết-kế-theme-mới)
6. [ĐOẠN CODE MẪU CHUẨN ĐỂ THÊM VÀO `app_theme_palette.dart`](#6-đoạn-code-mẫu-chuẩn-để-thêm-vào-app_theme_palettedart)
7. [DANH MỤC CÁC FILE ĐÃ HOÀN TOÀN ĐỒNG BỘ THEME TRONG DỰ ÁN](#7-danh-mục-các-file-đã-hoàn-toàn-đồng-bộ-theme-trong-dự-án)
8. [HƯỚNG DẪN KIỂM THỬ TRÊN THIẾT BỊ / MÁY ẢO](#8-hướng-dẫn-kiểm-thử-trên-thiết-bị--máy-ảo)

---

## 1. HƯỚNG DẪN 1-CHẠM: TẠO THEME MỚI TỪ ẢNH (DÀNH CHO NGƯỜI DÙNG & AI)

### Câu hỏi: *"Nếu tôi dán file này kèm 1 ảnh giao diện mới vào chat AI, AI có tạo được theme mới cho app không?"*
👉 **HOÀN TOÀN ĐƯỢC 100%!** Hệ thống mã nguồn WEARSY đã được thiết kế theo kiến trúc Dynamic Theme Provider. Khi người dùng gửi file này kèm một ảnh thiết kế mới:

### Quy trình AI xử lý tự động:
1. **Trích xuất màu mắt thần (Color Extraction):**
   * Quét các điểm màu chính trong ảnh: Màu nút bấm (`primary`), màu viền/icon AI (`primaryLight`), màu nền app (`lightBackground`), màu thẻ card (`cardColor`), màu chữ (`textPrimary`, `textSecondary`).
2. **Chuẩn hóa HSL/RGB theo tỷ lệ vàng:**
   * Áp dụng công thức ở [Phần 5](#5-công-thức-toán-học--nguyên-tắc-thiết-kế-theme-mới) để đảm bảo độ tương phản chữ đạt chuẩn AAA (> 7:1) và nền chống mỏi mắt.
3. **Cập nhật mã nguồn:**
   * Thêm đối tượng `AppThemePalette` vào file `apps/mobile-client/lib/core/theme/app_theme_palette.dart`.
   * Thêm theme mới vào danh sách `allThemes`.
4. **Kết quả:**
   * Không cần sửa đổi bất kỳ màn hình nào khác (Welcome, Login, Home, Closet, Shopping, Profile...) vì toàn bộ widget đã liên kết trực tiếp với `AppTheme` và `ThemeProvider`.

---

## 2. CƠ CHẾ KỸ THUẬT ĐỔI MÀU TOÀN BỘ ỨNG DỤNG (LIVE DYNAMIC SWITCHING)

Để khi người dùng chọn bất kỳ Theme nào, **toàn bộ 100% ứng dụng** lập tức chuyển màu mượt mà trong thời gian thực:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           KIẾN TRÚC LIVE THEME                              │
│                                                                             │
│  [SharedPreferences]  ◄── Lưu / Tải ID Theme ('theme_1', 'theme_2'...)      │
│          ▲                                                                  │
│          │                                                                  │
│  [ThemeProvider]     ───► Quản lý Palette hiện tại                          │
│          │                Gọi notifyListeners() khi đổi màu                 │
│          ▼                                                                  │
│    [AppTheme]         ───► Cầu nối Dynamic Getters                          │
│          │                (primaryColor, lightBackground, textPrimary...)   │
│          ▼                                                                  │
│  [Toàn Bộ Màn Hình]  ───► Welcome, Login, Register, Home, Closet,           │
│                           Shopping, Profile, BottomBar, Dialogs, Cards...   │
└─────────────────────────────────────────────────────────────────────────────┘
```

1. **Quản lý trạng thái trung tâm (`ThemeProvider`):**
   * File: `apps/mobile-client/lib/core/theme/theme_provider.dart`
   * Quản lý biến trạng thái `_currentPalette` và tự động lưu `selected_app_theme_id` vào bộ nhớ máy.
   * Khi đổi màu, gọi `switchTheme(themeId)`:
     ```dart
     AppTheme.setPalette(newPalette);
     notifyListeners(); // Tái tạo toàn bộ cây widget tức thì
     ```
2. **Cầu nối màu sắc tập trung (`AppTheme`):**
   * File: `apps/mobile-client/lib/core/theme/app_theme.dart`
   * Toàn bộ thuộc tính màu (`primaryColor`, `primaryLight`, `secondaryColor`, `lightBackground`, `lavenderCard`, `lavenderSurface`, `cardColor`, `surfaceColor`, `darkTextPrimary`, `darkTextSecondary`, `primaryGradient`, `accentGradient`) đều là **Dynamic Getters** trỏ thẳng về `AppTheme.current`.
3. **Cập nhật giao diện gốc (`main.dart`):**
   * `MaterialApp` được bọc bên trong `Consumer<ThemeProvider>`:
     ```dart
     Consumer<ThemeProvider>(
       builder: (context, themeProvider, child) {
         return MaterialApp(
           theme: themeProvider.currentThemeData,
           darkTheme: themeProvider.currentThemeData,
           ...
         );
       },
     )
     ```

---

## 3. ĐỒNG BỘ HÓA ĐẶC BIỆT: MÀN HÌNH WELCOME & LOGIN / REGISTER

Cả 2 màn hình đầu tiên khi người dùng mở app đã được đồng bộ 100% màu sắc:

### A. Màn hình Khởi động (`WelcomeScreen` - `welcome_screen.dart`):
* **Nút hành động "GET STARTED":**
  * Được phủ bằng widget cảm ứng động ngay đúng tọa độ chuẩn phía dưới màn hình.
  * **Theme 1:** Nền tím nhạt `#C4B8FA`, chữ tím than đậm `#2C2849` (chuẩn mẫu gốc `1.png`).
  * **Theme 2:** Nền nâu Mocha Cacao `#543D37`, chữ in hoa trắng `#FFFFFF` (chuẩn mẫu `2.png`).
  * **Theme khác:** Tự động lấy `AppTheme.primaryColor` làm nền và chữ tương phản phù hợp.
* **Lớp phủ hòa sắc tủ đồ (Ambient Tone Harmonizer):**
  * Với Theme 2 (Mocha & Ice Blue), một lớp phủ màu nâu ấm với chế độ hòa trộn tinh tế được áp dụng nhẹ nhàng lên ảnh tủ đồ để chuyển tone tím gốc sang tone ấm áp hoàng gia, tạo cảm giác liền mạch tuyệt đối.

### B. Màn hình Đăng nhập & Đăng ký (`LoginScreen` & `RegisterScreen`):
* **Nền màn hình (Scaffold Background):** Kế thừa `AppTheme.lightBackground` (Theme 1: Trắng ánh tím `#F3F1FA`; Theme 2: Kem hạnh nhân ấm `#FAF5F1`).
* **Khung nhập liệu (TextField - Email & Password):** 
  * Theme 1: Nền tím sữa `#F4F1FD`, viền tím nhạt `#9E94E8`.
  * Theme 2: Nền ngà sáng `#FCFAF7`, viền xanh hoàng gia Ice Blue `#8EBAE5`, icon điểm nhấn xanh.
* **Nút hành động chính ("Đăng Nhập" / "Đăng Ký"):**
  * Theme 1: Màu tím Lavender `#8174DB`.
  * Theme 2: Màu nâu Mocha Cacao `#543D37` đậm chất thời trang sang trọng, chuẩn 1:1 theo `2.png`.
* **Khối thẻ Form Card:** Bo tròn góc 32px, màu nền kem/trắng sứ thích ứng tự động.

---

## 4. BẢNG MÃ MÀU CHI TIẾT CỦA CẢ 5 BỘ THEME HIỆN CÓ

Dưới đây là thông số kỹ thuật đầy đủ của 5 Theme đã được lập trình sẵn trong hệ thống:

### Bảng So Sánh Mã Màu Trực Quan:

| Thuộc tính Palette | Theme 1 (Tím Lavender - Gốc `1.png`) | Theme 2 (Xanh & Nâu Cacao - Gốc `2.png`) | Theme 3 (Tím Hoàng Gia - Deep Amethyst) | Theme 4 (Xanh Bạc Hà - Mint Fresh) | Theme 5 (Xanh Đại Dương - Ocean Blue) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **`id`** | `theme_1` | `theme_2` | `theme_3` | `theme_4` | `theme_5` |
| **`primary`** (Nút chính, Tab active) | `#8174DB` | `#543D37` | `#6C5CE7` | `#00B894` | `#0984E3` |
| **`primaryLight`** (Viền input, Icon AI) | `#9E94E8` | `#8EBAE5` | `#A29BFE` | `#55EFC4` | `#74B9FF` |
| **`secondary`** (Tag phụ, Điểm nhấn) | `#00CEC9` | `#6BA3E8` | `#74B9FF` | `#0984E3` | `#00CEC9` |
| **`accent`** (Xóa, Cảnh báo, Đăng xuất) | `#FF5252` | `#D63031` | `#FF5252` | `#FF7675` | `#FF6B6B` |
| **`lightBackground`** (Nền toàn app) | `#F3F1FA` | `#FAF5F1` | `#F1F0FB` | `#F0FDF8` | `#F0F7FD` |
| **`cardColor`** (Thẻ card, Tủ đồ) | `#EBE7F7` | `#F0E8E1` | `#E4E1F8` | `#DBF6EB` | `#DCEBFA` |
| **`surfaceColor`** (Ô nhập liệu, Dialog) | `#F4F1FD` | `#FCFAF7` | `#F7F6FE` | `#F4FEFA` | `#F4FAFE` |
| **`textPrimary`** (Tiêu đề H1/H2, Tên đồ) | `#2C2849` | `#432F2A` | `#231B4D` | `#143B30` | `#132F4C` |
| **`textSecondary`** (Ghi chú mờ, Nhãn phụ) | `#6E698F` | `#7A6A64` | `#5A5285` | `#4A7468` | `#4A6B8A` |
| **`primaryGradient`** (Banner, FAB +) | `#8D80ED` ➡️ `#7464CF` | `#634942` ➡️ `#4A342E` | `#7D6DF2` ➡️ `#5946DF` | `#26DE81` ➡️ `#00A381` | `#2E97EB` ➡️ `#026BC0` |
| **`accentGradient`** (Chuyển sắc phụ) | `#8174DB` ➡️ `#6B5BCD` | `#A5C8EC` ➡️ `#76A8DC` | `#6C5CE7` ➡️ `#4C3EC7` | `#00B894` ➡️ `#008A6F` | `#0984E3` ➡️ `#0667B0` |

---

## 5. CÔNG THỨC TOÁN HỌC & NGUYÊN TẮC THIẾT KẾ THEME MỚI

Khi bạn hoặc AI tạo thêm các Theme tiếp theo (Theme 6, 7, 8...), hãy luôn tuân thủ **Quy tắc tỷ lệ vàng 4 bước**:

### Bước 1: Chọn màu chủ đạo (`primary`)
* Chọn màu bản sắc mong muốn (ví dụ: Hồng phấn thời trang `#FF6584`, Vàng mù tạt hoàng gia `#E1B12C`...).
* `primaryLight`: Pha thêm 15% - 20% sắc trắng hoặc chọn sắc thái pastel bổ trợ.

### Bước 2: Tạo màu nền (`lightBackground`) & màu thẻ (`cardColor`)
* **`lightBackground`**: Lấy hue của `primary`, hạ độ bão hòa (Saturation) xuống **3% - 6%**, và đẩy độ sáng (Lightness) lên **97% - 98%**.
  * ⚠️ *Tuyệt đối không dùng trắng tinh `#FFFFFF` làm nền app vì sẽ gây chói mắt và mất chiều sâu thẩm mỹ.*
* **`cardColor`**: Lấy cùng hue với nền, tăng độ đậm lên **4% - 6%** (độ sáng 92% - 94%) để thẻ nổi khối tự nhiên.
* **`surfaceColor`**: Nền bên trong ô gõ chữ, độ sáng 98.5% tạo độ chìm nhẹ nhàng.

### Bước 3: Tạo màu chữ (`textPrimary` & `textSecondary`)
* **`textPrimary`**: Đen pha 20% sắc thái của `primary` (độ sáng 15% - 20%). Đảm bảo độ tương phản AAA (> 7:1) theo tiêu chuẩn quốc tế WCAG.
* **`textSecondary`**: Nâng độ sáng lên **45% - 55%** từ tone của `textPrimary` để nhãn phụ thanh thoát, dễ chịu.

### Bước 4: Tạo Gradient chuyển sắc (`primaryGradient`)
* Điểm bắt đầu (Top-Left): Sáng hơn màu `primary` khoảng 5% - 7%.
* Điểm kết thúc (Bottom-Right): Đậm hơn màu `primary` khoảng 8% - 10%.

---

## 6. ĐOẠN CODE MẪU CHUẨN ĐỂ THÊM VÀO `app_theme_palette.dart`

Khi có thông số theme mới, chỉ cần copy khối mã sau dán vào:  
📁 **`apps/mobile-client/lib/core/theme/app_theme_palette.dart`**

```dart
static const AppThemePalette themeMoi = AppThemePalette(
  id: 'theme_x',                         // ID duy nhất (vd: 'theme_6')
  name: 'Theme X - Tên Phong Cách',     // Tên hiển thị trong danh mục đổi màu
  description: 'Mô tả ngắn phong cách thẩm mỹ của theme',

  // 1. Nhóm màu chính
  primary: Color(0xFF......),            // Nút chính, logo, icon active
  primaryLight: Color(0xFF......),       // Viền ô nhập, icon AI, highlight
  secondary: Color(0xFF......),          // Tag điểm nhấn phụ
  accent: Color(0xFFFF5252),             // Nút xóa, đăng xuất, cảnh báo

  // 2. Nhóm màu nền & bố cục
  lightBackground: Color(0xFF......),    // Nền app (pastel 97-98%)
  cardColor: Color(0xFF......),          // Nền thẻ card (pastel 92-94%)
  surfaceColor: Color(0xFF......),       // Nền ô nhập liệu (98.5%)

  // 3. Nhóm màu chữ
  textPrimary: Color(0xFF......),        // Tiêu đề, chữ đậm (15-20% sáng)
  textSecondary: Color(0xFF......),      // Nhãn phụ, mô tả (45-55% sáng)

  // 4. Gradient chuyển sắc
  primaryGradient: LinearGradient(
    colors: [Color(0xFF......), Color(0xFF......)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  accentGradient: LinearGradient(
    colors: [Color(0xFF......), Color(0xFF......)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
);
```

Sau đó thêm `themeMoi` vào danh sách `allThemes`:
```dart
static const List<AppThemePalette> allThemes = [
  theme1,
  theme2,
  theme3,
  theme4,
  theme5,
  themeMoi, // <-- Thêm vào đây
];
```

---

## 7. DANH MỤC CÁC FILE ĐÃ HOÀN TOÀN ĐỒNG BỘ THEME TRONG DỰ ÁN

| Đường dẫn file | Vai trò trong hệ thống Theme |
| :--- | :--- |
| `lib/core/theme/app_theme_palette.dart` | Khai báo các bộ màu mẫu (Theme 1 đến Theme 5) |
| `lib/core/theme/app_theme.dart` | Cung cấp các dynamic getters trỏ về theme đang chọn |
| `lib/core/theme/theme_provider.dart` | Lưu trữ trạng thái, lắng nghe thay đổi và lưu vào SharedPreferences |
| `lib/main.dart` | Bọc `Consumer<ThemeProvider>` cập nhật ThemeData toàn ứng dụng |
| `lib/features/auth/screens/welcome_screen.dart` | Nút Get Started cảm ứng động & hòa sắc ảnh nền |
| `lib/features/auth/screens/login_screen.dart` | Nền, ô nhập liệu viền xanh/nâu, nút Đăng nhập theo theme |
| `lib/features/auth/screens/register_screen.dart` | Màn hình đăng ký tài khoản đồng bộ màu hoàn toàn |
| `lib/core/layout/main_layout.dart` | Thanh Bottom Navigation Bar & Nút tròn (+) FloatingActionButton động |
| `lib/features/home/screens/home_screen.dart` | Banner trang chủ, card thống kê, outfit gợi ý |
| `lib/features/closet/screens/smart_wardrobe_screen.dart` | Danh mục quần áo, thẻ đồ, bộ lọc phân loại |
| `lib/features/shopping/screens/smart_shopping_screen.dart` | Giao diện mua sắm thông minh, thẻ giá, ưu đãi |
| `lib/features/profile/screens/profile_screen.dart` | Giao diện chọn Theme trực tiếp với preview màu |

---

## 8. HƯỚNG DẪN KIỂM THỬ TRÊN THIẾT BỊ / MÁY ẢO

1. **Chuyển đổi Theme:**
   * Mở ứng dụng WEARSY -> Chọn tab **Hồ sơ (Profile)** ở góc phải dưới.
   * Cuộn đến mục **"Giao diện & Chủ đề màu (Theme)"**.
   * Nhấn chọn bất kỳ Theme nào (Theme 1 Tím, Theme 2 Nâu & Xanh, Theme 3, 4, 5).
   * Toàn bộ thanh điều hướng, nút bấm, banner trang chủ và các thẻ đồ lập tức đổi màu.
2. **Kiểm tra màn hình Welcome & Đăng nhập:**
   * Tại tab Hồ sơ, bấm **"Đăng xuất"**.
   * Quan sát màn hình **Welcome** (nút GET STARTED đã đổi màu chuẩn theo Theme vừa chọn).
   * Bấm vào nút để đến màn hình **Đăng nhập** (nền, viền ô nhập liệu và nút Đăng Nhập hiển thị chuẩn xác 100% theo Theme).
