# SỔ TAY TÀI KHOẢN DEMO & HƯỚNG DẪN KIỂM THỬ THỰC TẾ - DỰ ÁN WEARSY
## (Comprehensive Testing & Demonstration Handbook)

> **Tên dự án:** WEARSY - Smart Wardrobe & AI Fashion Assistant  
> **Mã môn:** EXE101 - FA26  
> **Phiên bản:** v2.1.0 (Đồng bộ chuẩn 100% dữ liệu MockDataService, 13 Trang phục, 5 Outfits, Phân loại Giày/Phụ kiện & VIP Fashion Coupon)  
> **Thời gian cập nhật:** 26/09/2026  

---

## 1. Nguyên Tắc Cấp Phát Dữ Liệu & Phân Quyền Tủ Đồ

Hệ thống WEARSY áp dụng cơ chế cô lập dữ liệu người dùng đa tầng (Data Isolation) nhằm đảm bảo tính chuyên nghiệp khi thuyết trình và trải nghiệm thực tế khi triển khai người dùng thật:

1. ⭐️ **Tài khoản được cấp để test/demo (`demo@wearsy.app`, `test@wearsy.app`...):**
   - Được nạp sẵn **13 trang phục thời trang mẫu** phân bố đồng đều trên **6 danh mục** và **5 bộ Outfit AI hoàn chỉnh**.
   - Phục vụ ban giám khảo chấm đồ án, test chức năng phối đồ, lọc danh mục, xem chi tiết món đồ ngay lập tức mà không cần tốn thời gian chụp ảnh nạp từng món đồ.
2. 🆕 **Tài khoản tạo mới (Đăng ký qua form OTP hoặc Đăng nhập Google/Facebook SSO):**
   - Khởi tạo với **TỦ ĐỒ TRẮNG HOÀN TOÀN (0 món đồ, 0 outfit)**.
   - Thống kê trang chủ hiển thị `0 Tủ Đồ` - `0 AI Outfit`.
   - Giao diện Tủ đồ & Phối đồ hiển thị Empty State chào mừng tinh tế kèm nút bấm **"+ Thêm đồ đầu tiên"** để người dùng tự do số hóa trang phục thực tế của mình.
   - Mọi trang phục người dùng tự thêm sẽ được lưu trữ độc lập theo tài khoản (`custom_wardrobe_items_$email`), không bị rò rỉ sang tài khoản khác.

---

## 2. Thông Tin Tài Khoản Được Cấp Để Test

### 2.1. Tài Khoản Demo Chính (Khuyên Dùng Cho Thuyết Trình / Báo Cáo)

| Trường Thông Tin | Dữ Liệu Thật Trong Ứng Dụng |
| :--- | :--- |
| **Email đăng nhập** | `demo@wearsy.app` |
| **Mật khẩu** | `123456` |
| **Họ và Tên** | **Nguyễn Văn Demo** |
| **Chế độ vận hành** | Hỗ trợ 100% Offline (Không cần Backend/Internet) lẫn Online |
| **Thống kê trang chủ** | **13 Món đồ** • **5 Bộ Outfit AI** • **9.5/10 Điểm màu sắc** |
| **Hồ sơ phong cách** | • **Phong cách ưa thích:** Thanh lịch, Minimalism, Công sở<br>• **Tông màu yêu thích:** Trắng, Đen, Xanh Navy, Beige, Xám<br>• **Tông màu tránh:** Vàng, Đỏ<br>• **Ngân sách:** 300.000 đ – 2.000.000 đ<br>• **Số đo thể hình:** Cao 172cm, Nặng 65kg, Ngực 92cm, Eo 78cm, Mông 94cm |

### 2.2. Tài Khoản Test Dự Phòng

| Email Test | Mật Khẩu | Mục Đích Sử Dụng | Dữ Liệu Khởi Tạo |
| :--- | :--- | :--- | :--- |
| `test@wearsy.app` | `123456` | Kiểm tra luồng Đăng nhập / Đăng xuất | 13 món đồ + 5 outfits |
| `admin.demo@wearsy.app` | `123456` | Thử nghiệm kịch bản quản trị | 13 món đồ + 5 outfits |
| `user.test@gmail.com` | `123456` | Kiểm tra tài khoản test đuôi Gmail | 13 món đồ + 5 outfits |

> 📌 **Lưu ý bảo mật (Brute-force Protection & Anti-User Enumeration):**
> - Khi nhập sai tài khoản hoặc mật khẩu, hệ thống **luôn trả về thông báo lỗi chung duy nhất**: `Email hoặc mật khẩu không chính xác. Vui lòng kiểm tra lại.`
> - **Khóa nút đăng nhập:** Sai 5 lần liên tiếp sẽ tự khóa trong **1 phút**; sai 10 lần liên tiếp khóa trong **5 phút** kèm đồng hồ đếm ngược trực tiếp trên nút.

---

## 3. Chi Tiết Dữ Liệu 13 Trang Phục Mẫu Sẵn Có (Wardrobe Items)

Tủ đồ của tài khoản demo bao gồm **13 món đồ chuẩn hóa** phân theo 6 danh mục:

| ID | Tên Món Đồ | Danh Mục (Category) | Màu Sắc | Thương Hiệu | Điểm AI | Thẻ Tag (Styles) |
| :---: | :--- | :--- | :--- | :--- | :---: | :--- |
| `w001` | **Áo Sơ Mi Lụa Trắng** | 👕 Áo (Tops) | Trắng | Zara | 9.2 | Formal, Smart Casual, Công sở |
| `w002` | **Quần Tây Slim Fit Đen** | 👖 Quần (Bottoms) | Đen | H&M | 9.5 | Formal, Versatile |
| `w003` | **Áo Blazer Beige** | 🧥 Áo khoác (Outerwear) | Be | Mango | 8.8 | Smart Casual, Business |
| `w004` | **Giày Oxford Da Nâu** | 👟 Giày (Shoes) | Nâu | Clarks | 9.0 | Formal, Classic |
| `w005` | **T-Shirt Cotton Xám** | 👕 Áo (Tops) | Xám | Uniqlo | 8.5 | Casual, Minimalist, Daily |
| `w006` | **Quần Jeans Navy Slim** | 👖 Quần (Bottoms) | Navy | Levi's | 9.1 | Casual, Weekend, Versatile |
| `w007` | **Áo Polo Trắng** | 👕 Áo (Tops) | Trắng | Lacoste | 8.7 | Smart Casual, Sport |
| `w008` | **Sneaker Trắng Clean** | 👟 Giày (Shoes) | Trắng | Nike | 9.3 | Casual, Street, Sport |
| `w009` | **Đồng Hồ Dây Da** | 👜 Phụ kiện (Accessories) | Nâu/Vàng | Fossil | 9.4 | Classic, Formal, Elegant |
| `w010` | **Áo Khoác Denim** | 🧥 Áo khoác (Outerwear) | Xanh denim | Pull & Bear | 8.6 | Casual, Street, Weekend |
| `w011` | **Quần Short Khaki Be Nam** | 👖 Quần (Bottoms) | Be | Uniqlo | 8.9 | Casual, Summer, Dạo phố |
| `w012` | **Balo Da Nam Minimalist** | 👜 Phụ kiện (Accessories) | Đen | Bellroy | 8.8 | Minimalist, Daily, Công sở |
| `w013` | **Đầm Lụa Midi Dự Tiệc** | 👗 Váy (Dresses) | Đỏ Ruby | Zara | 9.6 | Dự tiệc, Quyến rũ, Sang trọng |

---

## 4. Chi Tiết 5 Bộ Trang Phục AI Phối Sẵn (AI Outfits)

Hệ thống AI Gemini tích hợp sẵn 5 bộ outfit gợi ý theo ngữ cảnh thời tiết và sự kiện:

| Mã | Tên Bộ Outfit | Hoàn Cảnh (Occasion) | Điểm Phối | Các Món Đồ Kết Hợp | Lập Luận Phối Đồ Của AI (AI Reasoning) |
| :---: | :--- | :--- | :---: | :--- | :--- |
| `o001` | **Business Casual Lịch Lãm Nam** | Công sở (Work) | **9.5** | Sơ mi trắng (`w001`) + Quần tây đen (`w002`) + Blazer beige (`w003`) + Giày Oxford (`w004`) | Áo sơ mi trắng kết hợp quần tây đen tạo phong cách công sở chỉn chu. Áo blazer màu be khoác ngoài mang đến vẻ lịch lãm và chuyên nghiệp. |
| `o002` | **Weekend Casual Nam Năng Động** | Dạo phố (Casual) | **9.1** | T-shirt xám (`w005`) + Jeans navy (`w006`) + Sneaker trắng (`w008`) | T-shirt xám đơn giản tinh tế đi cùng quần jeans navy slim fit. Đôi sneaker trắng vừa tạo điểm nhấn vừa thoải mái vận động cả ngày. |
| `o003` | **Smart Casual Thuyết Trình Nam** | Trang trọng (Formal) | **9.3** | Polo trắng (`w007`) + Quần tây đen (`w002`) + Đồng hồ dây da (`w009`) | Áo polo trắng lịch sự không quá cứng nhắc, phối cùng quần tây đen chỉn chu và điểm nhấn đồng hồ dây da nâu cuốn hút. |
| `o004` | **Street Style Denim Nam Cực Chất** | Đi chơi (Casual) | **8.8** | Áo khoác denim (`w010`) + T-shirt xám (`w005`) + Jeans navy (`w006`) + Sneaker trắng (`w008`) | Áo khoác denim nam layering cùng T-shirt xám và quần jeans navy. Combo phối màu xanh & xám nam tính chuẩn phong cách dạo phố. |
| `o005` | **Summer Date Night Nam Thanh Lịch** | Hẹn hò (Evening) | **9.6** | Sơ mi trắng (`w001`) + Short khaki be (`w011`) + Sneaker trắng (`w008`) + Balo da (`w012`) | Áo sơ mi trắng lụa nam xắn tay nhẹ kết hợp quần short khaki be thoáng mát. Giày sneaker trắng cùng balo da tạo diện mạo trẻ trung, cuốn hút. |

---

## 5. Tính Năng Nâng Cấp VIP Fashion & Mã Coupon "WEARSY"

Ứng dụng cung cấp gói hội viên đặc quyền **VIP Fashion** dành cho các tín đồ thời trang:

### 5.1. Vị trí nút nâng cấp & Cách kích hoạt VIP:
1. Mở màn hình **Hồ sơ (Profile)**: Bấm trực tiếp vào nút **Nâng Cấp VIP** trên thẻ cá nhân (hoặc chuyển sang tab **Liên kết**).
2. Tại trường nhập **Mã giảm giá / Coupon**, nhập mã:
   ```text
   WEARSY
   ```
   *(Không phân biệt chữ hoa, chữ thường: `WEARSY` hoặc `wearsy`)*.
3. Bấm **Áp Dụng Coupon**: Hệ thống sẽ nâng cấp tài khoản lên **VIP Fashion 7 Ngày hoàn toàn miễn phí**, tự động hiển thị huy hiệu sao vàng VIP trên hồ sơ cá nhân.

### 5.2. Bảng So Sánh Đặc Quyền: VIP Fashion vs Tài Khoản Thường

| Tiêu Chí So Sánh | Tài Khoản Thường (Free) | Tài Khoản VIP Fashion (⭐ VIP) |
| :--- | :---: | :---: |
| **Gợi ý phối đồ AI (Gemini 3.6 Flash)** | Giới hạn 3 lượt / ngày | **Không giới hạn lượt tạo** |
| **Tách nền ảnh tự động (Cloudinary AI)** | Chất lượng chuẩn | **HD Studio siêu nét, viền mượt** |
| **Smart Shopping Compatibility** | Thử tối đa 2 sản phẩm / ngày | **Quét kiểm tra không giới hạn** |
| **Quy tắc bánh xe màu sắc (Color Wheel)** | 3 quy tắc cơ bản | **Đầy đủ 8 quy tắc phối màu cao cấp** |
| **Giao diện & Quảng cáo** | Có banner tài trợ | **100% Không quảng cáo** |
| **Huy hiệu hồ sơ cá nhân** | Thành viên cơ bản | **Huy hiệu VIP Fashion danh giá** |

---

## 6. Hướng Dẫn Kiểm Thử Tài Khoản Mới Thật 100%

### Cách 1: Đăng Ký Tài Khoản & Nhận Mã OTP Thật Qua Email (Brevo SMTP Relay)
1. Tại màn hình Đăng nhập, bấm **"Đăng ký ngay"**.
2. Nhập Họ và tên, Email cá nhân bạn muốn nhận thư (Ví dụ: Gmail cá nhân, Outlook hoặc email trường học), Mật khẩu (tối thiểu 6 ký tự).
3. Bấm **"ĐĂNG KÝ"**: Hệ thống máy chủ backend tự động sinh mã OTP 6 số ngẫu nhiên và gửi trực tiếp qua hạ tầng Brevo SMTP Relay chuyên dụng (`smtp-relay.brevo.com` - WEARSY Support) về hộp thư người đăng ký.
4. Mở hòm thư (hoặc thư mục Spam/Junk) lấy mã 6 chữ số, nhập vào khung xác thực OTP và xác nhận.
5. **Kết quả:** Đăng nhập thành công với **Tủ Đồ: 0 món**, **Outfit: 0 bộ** (Tủ đồ trắng chuẩn mực).

### Cách 2: Đăng Nhập Một Chạm Thật Bằng Google SSO (Firebase)
1. Tại màn hình Đăng nhập, bấm nút **"Đăng nhập nhanh bằng Google"**.
2. Hộp thoại Google Play Services xuất hiện, chọn tài khoản Gmail thật của bạn trên máy.
3. **Kết quả:** Đăng nhập tức thì không cần mật khẩu. Vì là tài khoản người dùng cá nhân mới, ứng dụng sẽ khởi tạo **Tủ đồ trắng** để người dùng tự do thêm trang phục của riêng mình.

---

## 7. Dịch Vụ Lưu Trữ & AI Tách Nền Ảnh Trang Phục (Cloudinary)

- **Môi trường Cloud:** Cloudinary Product Environment (`bvxcghig`).
- **Công nghệ Computer Vision:** Tự động nhận diện biên trang phục, bóc tách hoàn toàn nền hậu cảnh (`background_removal: 'cloudinary_ai'`) và lưu ảnh định dạng PNG trong suốt.
- **Trạng thái:** ✅ Sẵn sàng 100% cho mọi hình ảnh người dùng chụp từ camera hoặc chọn từ thư viện ảnh.

---

*Tài liệu nội bộ dự án EXE101 - WEARSY Mobile System.*
