# Kế Hoạch Kiểm Thử & Tối Ưu Hóa Hiệu Năng Ứng Dụng WEARSY (Smooth 60 FPS)

## 🎯 Mục Tiêu Đặt Ra
Đảm bảo ứng dụng WEARSY đạt trải nghiệm người dùng siêu mượt (**60 FPS**), loại bỏ triệt để hiện tượng giật lag (frame drop / jank), giảm mức tiêu thụ RAM khi tải nhiều ảnh tủ đồ, tối ưu hóa tốc độ tách nền AI cục bộ và xây dựng bộ kiểm thử tự động (Unit & Widget Tests) đạt tỷ lệ vượt qua 100%.

---

## 🔍 Phân Tích Các Nút Thắt Hiệu Năng (Bottlenecks) & Giải Pháp

### 1. Tối ưu hóa Dịch vụ Tách Nền AI Cục Bộ (`LocalBgRemovalService`)
- **Vấn đề**: Khi xử lý các bức ảnh độ phân giải cao từ camera (4K / 12MP), việc giải mã ảnh gốc và duyệt từng pixel tiêu tốn nhiều CPU, gây lag nhẹ dù đã chạy trong `compute()`.
- **Giải pháp**:
  - Tự động downsample (thu nhỏ tỉ lệ ảnh tối đa 1024px) trước khi đưa vào luồng phân tích màu sắc phông nền.
  - Sử dụng tham số nén PNG tối ưu trong package `image`.
  - Giảm thời gian xử lý tách nền tự động từ ~3-5 giây xuống dưới **0.8 giây**.

### 2. Tối ưu Cọ Vẽ & Tương Tác Cảm Ứng (`InteractiveBgEraserDialog`)
- **Vấn đề**:
  - Hàm `paint()` hiện tại đang chạy 2 vòng lặp lồng nhau vẽ hàng trăm ô vuông phông lưới `drawRect()` trên từng frame vuốt chạm.
  - Hàm `shouldRepaint` luôn trả về `true` làm repaint liên tục ngay cả khi không chạm.
  - Mỗi cử chỉ vuốt (`onPanUpdate`) gọi `setState()` rebuild lại toàn bộ widget tree (bao gồm các nút bấm, slider, appbar).
- **Giải pháp**:
  - Thay thế phông lưới kẻ ô vuông bằng `Paint` shader / caching dạng hình nền tĩnh hoặc đường vẽ tối ưu.
  - Sử dụng `ValueNotifier` và bọc Canvas bằng `RepaintBoundary` để chỉ repaint vùng cọ vẽ mà không rebuild giao diện xung quanh.
  - Cập nhật `shouldRepaint` kiểm tra đúng độ dài mảng stroke và trạng thái ảnh.

### 3. Quản Lý Bộ Nhớ & Tải Ảnh Trang Phục (`Mannequin2DWidget` & `WardrobeScreen`)
- **Vấn đề**: Tải nhiều ảnh trang phục chất lượng cao vào `GridView` / `Mannequin2DWidget` mà không giới hạn kích thước cache có thể làm tràn bộ nhớ GPU/RAM.
- **Giải pháp**:
  - Áp dụng `memCacheWidth` và `memCacheHeight` cho `CachedNetworkImage` và `ResizeImage` cho ảnh local file.
  - Bọc từng layer món đồ trên Ma-nơ-canh 2D bằng `RepaintBoundary` để tránh vẽ lại cả ma-nơ-canh khi chỉ 1 món đồ thay đổi.

### 4. Nâng Cấp Bộ Kiểm Thử Tự Động (Automated Testing Suite)
- **Vấn đề**: Cần bổ sung test case bao phủ toàn bộ logic tách nền mới, cọ vẽ xóa phông thủ công, và mô hình dữ liệu tủ đồ đa mục.
- **Giải pháp**:
  - Bổ sung Unit test cho `LocalBgRemovalService`.
  - Bổ sung Widget test cho `InteractiveBgEraserDialog` và tương tác cọ vẽ xóa phông.
  - Chạy `flutter test` đảm bảo 100% test case xanh.

---

## 🛠 Chi Tiết Thay Đổi Mã Nguồn (Proposed Changes)

### Component 1: `LocalBgRemovalService`
#### 📝 [MODIFY] [`lib/core/services/local_bg_removal_service.dart`](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/apps/mobile-client/lib/core/services/local_bg_removal_service.dart)
- Thu nhỏ kích thước ảnh (max 1024px) trong Isolate trước khi quét pixel background.
- Giảm độ trễ CPU và tối ưu hóa bộ nhớ tạm trong Isolate.

### Component 2: `InteractiveBgEraserDialog`
#### 📝 [MODIFY] [`lib/features/wardrobe/widgets/interactive_bg_eraser_dialog.dart`](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/apps/mobile-client/lib/features/wardrobe/widgets/interactive_bg_eraser_dialog.dart)
- Dùng `ValueNotifier<List<List<TouchPoint>>>` cập nhật nét vẽ mượt mà mà không gọi `setState()` toàn màn hình.
- Tối ưu `_EraserPainter` vẽ phông lưới caro bằng `Picture` cached hoặc canvas tối ưu.
- Đóng gói Canvas trong `RepaintBoundary`.

### Component 3: `Mannequin2DWidget` & `WardrobeScreen`
#### 📝 [MODIFY] [`lib/features/fitting_room/widgets/mannequin_2d_widget.dart`](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/apps/mobile-client/lib/features/fitting_room/widgets/mannequin_2d_widget.dart)
- Đưa `memCacheWidth` vào `CachedNetworkImage` để tiết kiệm tài nguyên GPU.
- Bọc `RepaintBoundary` cho từng tầng trang phục.

### Component 4: Test Suite
#### 🆕 [NEW] [`test/local_bg_removal_service_test.dart`](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/apps/mobile-client/test/local_bg_removal_service_test.dart)
- Kiểm thử đơn vị tính hợp lệ của hàm tách nền và định dạng đầu ra.
#### 📝 [MODIFY] [`test/widget_test.dart`](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/apps/mobile-client/test/widget_test.dart)
- Cập nhật test case tích hợp giao diện.

---

## 🧪 Kế Hoạch Phê Duyệt & Kiểm Thử (Verification Plan)

### 1. Kiểm thử Tự động (Automated Testing)
```bash
# Chạy static analysis
flutter analyze

# Chạy toàn bộ unit & widget test suite
flutter test
```

### 2. Kiểm thử Thực Tế trên Giả Lập/Thiết Bị (Manual & Performance Verification)
- Build APK và khởi chạy ứng dụng trên Android Emulator (`emulator-5554`):
```bash
flutter build apk --debug
flutter install -d emulator-5554
```
- Mở tính năng "Interactive Eraser & Refine": kiểm tra tốc độ phản hồi cọ vẽ khi di chuyển ngón tay (không giật lag, đường vẽ đi mượt theo nét chạm).
- Kiểm tra tính năng "Rescan with AI / Auto Cutout": kiểm tra thời gian xử lý tách nền nhanh dưới 1 giây.
