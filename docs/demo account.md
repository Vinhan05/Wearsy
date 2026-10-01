# SỔ TAY HƯỚNG DẪN ĐĂNG KÝ & KIỂM THỬ TÀI KHOẢN THẬT 100% - DỰ ÁN WEARSY
## (Production-Ready Live Authentication & Demonstration Handbook)

> **Tên dự án:** WEARSY - Smart Wardrobe & AI Fashion Assistant  
> **Mã môn:** EXE101 - FA26  
> **Phiên bản:** v3.0.0 (100% Live Backend Database - PostgreSQL Cloud, Zero Mock Accounts, Live OTP & SSO)  
> **Thời gian cập nhật:** 29/09/2026  

---

## 1. Nguyên Tắc Hoạt Động & Cô Lập Dữ Liệu 100% Real Database

Hệ thống WEARSY đã **xóa bỏ hoàn toàn cơ chế Mock Demo Account cục bộ**. Toàn bộ tài khoản, mật khẩu, tủ đồ và outfit đều được quản lý trực tiếp trên hệ cơ sở dữ liệu **PostgreSQL Database** thông qua NestJS Backend API:

1. 🔐 **Bảo mật & Mã hóa mật khẩu:**
   - Mật khẩu người dùng được băm (hash) bằng thuật toán chuẩn **bcrypt** trên máy chủ.
   - Không lưu trữ mật khẩu dạng plain-text trên thiết bị hay cơ sở dữ liệu.
   - Cơ chế cấp phát token **JWT (JSON Web Token)** chuẩn xác thực OAuth2 / Bearer Token.

2. 🆕 **Trải nghiệm khởi tạo tài khoản mới 100%:**
   - Khi người dùng đăng ký tài khoản mới hoặc đăng nhập Google/Facebook SSO:
   - Hệ thống tạo hồ sơ người dùng mới trong cơ sở dữ liệu.
   - Tủ đồ khởi đầu là **TỦ ĐỒ TRẮNG HOÀN TOÀN (0 món đồ, 0 outfit)** để người dùng tự do tải lên và phân loại trang phục thực tế của bản thân.
   - Mọi trang phục và outfit của mỗi tài khoản đều được phân tách và bảo mật riêng biệt theo User ID.

---

## 2. Hướng Dẫn Đăng Ký & Đăng Nhập Tài Khoản Thật

### 2.1. Đăng Ký Tài Khoản Mới Thật Qua Form Đăng Ký & OTP Email
1. Tại màn hình Đăng nhập ứng dụng, bấm **"Đăng ký ngay"**.
2. Nhập các thông tin:
   - **Họ và tên:** Tên thật của bạn (ví dụ: *Võ Thế Đan*, *Nguyễn Thị Mai*).
   - **Email:** Email cá nhân thật (Gmail, Outlook, FPT Edu...) để nhận mã OTP.
   - **Mật khẩu:** Tối thiểu 8 ký tự, bao gồm ít nhất 1 chữ cái và 1 chữ số (ví dụ: `Wearsy2026`).
3. Bấm **"ĐĂNG KÝ"**: Hệ thống máy chủ backend gửi mã OTP 6 số qua hệ thống email Brevo SMTP Relay (`smtp-relay.brevo.com`).
4. Nhập mã 6 chữ số để kích hoạt tài khoản và đăng nhập ngay vào ứng dụng.

---

### 2.2. Đăng Nhập Một Chạm Nhanh Bằng Google SSO
1. Tại màn hình Đăng nhập, bấm nút **"Đăng nhập nhanh bằng Google"**.
2. Chọn tài khoản Google có sẵn trên điện thoại / Emulator.
3. Ứng dụng tự động lấy thông tin tên, email và đăng nhập tức thì.

---

### 2.3. Cơ Chế Chống Tấn Công Dò Mật Khẩu (Brute-force Protection)
- **Thông báo lỗi chung bảo mật:** Khi email hoặc mật khẩu không chính xác, hệ thống luôn trả về: `Email hoặc mật khẩu không chính xác. Vui lòng kiểm tra lại.`
- **Client Rate Limiting:** Sai 5 lần liên tiếp sẽ tạm khóa nút 1 phút; sai 10 lần liên tiếp khóa 5 phút kèm đồng hồ đếm ngược trực tiếp.
- **Server Rate Limiting (NestJS Throttler):** Tối đa 10 lượt đăng nhập/phút trên mỗi IP để ngăn chặn tấn công tự động.

---

## 3. Các Tính Năng Người Dùng Trải Nghiệm Thực Tế

### 3.1. Số Hóa Tủ Đồ Cá Nhân (Digital Wardrobe)
- Người dùng có thể nhấn nút **"+ Thêm đồ"** hoặc **"Chụp ảnh trang phục"**.
- Hệ thống hỗ trợ tách nền tự động qua **Cloudinary AI Computer Vision** (`bvxcghig`), phân loại tự động vào 6 danh mục chính:
  - 👕 **Áo (Tops):** Áo sơ mi, T-shirt, Polo, Áo len...
  - 👖 **Quần (Bottoms):** Quần tây, Jeans, Short, Kaki...
  - 🧥 **Áo khoác (Outerwear):** Blazer, Denim Jacket, Bomber, Cardigan...
  - 👟 **Giày (Shoes):** Sneaker, Oxford, Loafers, Boots...
  - 👗 **Váy/Đầm (Dresses):** Đầm liền, Chân váy, Maxi...
  - 👜 **Phụ kiện (Accessories):** Thắt lưng, Đồng hồ, Túi xách, Balo...

---

## 4. Gợi Ý Phối Đồ Tự Động Bằng AI (Gemini Flash AI Engine)

Khi người dùng đã có các món đồ trong tủ đồ:
- Nhấn **"Tạo Outfit Mới Bằng AI"** tại Dashboard hoặc tab **Outfits**.
- AI Gemini sẽ phân tích theo ngữ cảnh thời tiết thực tế (OpenWeather API), số đo hình thể (Smart Fit) và quy tắc bánh xe màu sắc để phối các set đồ phù hợp cho từng hoàn cảnh:
  - 🏢 **Công sở (Work / Office)**
  - ☕️ **Dạo phố (Casual / Weekend)**
  - 🎩 **Trang trọng (Formal / Event)**
  - 🍷 **Hẹn hò (Evening / Date Night)**
  - 🏃‍♂️ **Thể thao & Du lịch (Active / Travel)**

---

## 5. Tính Năng Điểm Màu Sắc (Color Score) & Gamification

Hệ thống phân tích màu sắc thời trang chuẩn quốc tế:

- **Điểm hài hòa màu sắc (Color Harmony Score):** `9.5/10` (Xuất sắc).
- **Quy tắc phối màu áp dụng:** Quy tắc tỷ lệ vàng 60-30-10 & Phối màu tương đồng (Analogous).
- **Phân tích mùa cá nhân (Personal Season):** 
  - *Xuân Ấm Áp (Spring Warm)*: Tươi sáng, rực rỡ, tone ấm.
  - *Hạ Dịu Dàng (Summer Cool)*: Pastel, thanh nhã, tone lạnh.
  - *Thu Trầm Ấm (Autumn Deep)*: Tone đất, vintage, ấm áp.
  - *Đông Sắc Nét (Winter Vivid)*: Tương phản cao, sang trọng, sắc sảo.
- **Thử thách phối màu (Color Challenges):** Nhiệm vụ thử thách hàng tuần nhận huy hiệu và điểm thưởng thời trang.

---

## 6. Tính Năng Smart Shopping (Kiểm Tra Độ Tương Thích Trang Phục Mới)

Người dùng có thể thử tính năng kiểm tra món đồ định mua trước khi chi tiền:
1. Nhấn nút **Smart Shopping** trên Dashboard hoặc từ tab Mua sắm.
2. Tải ảnh hoặc chọn sản phẩm thời trang mới.
3. AI sẽ tự động phân tích độ tương thích (Compatibility Score %) với **13 món đồ hiện có trong tủ đồ**, gợi ý ngay các cách mix & match khả thi.

---

## 7. Tính Năng Nâng Cấp VIP Fashion & Mã Coupon "WEARSY"

Ứng dụng cung cấp gói hội viên đặc quyền **VIP Fashion** dành cho các tín đồ thời trang:

### 7.1. Vị trí nút nâng cấp & Cách kích hoạt VIP:
1. Mở màn hình **Hồ sơ (Profile)**: Bấm trực tiếp vào nút **Nâng Cấp VIP** trên thẻ cá nhân (hoặc chuyển sang tab **Liên kết**).
2. Tại trường nhập **Mã giảm giá / Coupon**, nhập mã:
   ```text
   WEARSY
   ```
   *(Không phân biệt chữ hoa, chữ thường: `WEARSY` hoặc `wearsy`)*.
3. Bấm **Áp Dụng Coupon**: Hệ thống sẽ nâng cấp tài khoản lên **VIP Fashion 1 Năm hoàn toàn miễn phí**, tự động hiển thị huy hiệu sao vàng VIP trên hồ sơ cá nhân.

### 7.2. Bảng So Sánh Đặc Quyền: VIP Fashion vs Tài Khoản Thường

| Tiêu Chí So Sánh | Tài Khoản Thường (Free) | Tài Khoản VIP Fashion (⭐ VIP) |
| :--- | :---: | :---: |
| **Gợi ý phối đồ AI (Gemini 3.6 Flash)** | Giới hạn 3 lượt / ngày | **Không giới hạn lượt tạo** |
| **Tách nền ảnh tự động (Cloudinary AI)** | Chất lượng chuẩn | **HD Studio siêu nét, viền mượt** |
| **Smart Shopping Compatibility** | Thử tối đa 2 sản phẩm / ngày | **Quét kiểm tra không giới hạn** |
| **Quy tắc bánh xe màu sắc (Color Wheel)** | 3 quy tắc cơ bản | **Đầy đủ 8 quy tắc phối màu cao cấp** |
| **Giao diện & Quảng cáo** | Có banner tài trợ | **100% Không quảng cáo** |
| **Huy hiệu hồ sơ cá nhân** | Thành viên cơ bản | **Huy hiệu VIP Fashion danh giá** |

---

## 8. Hướng Dẫn Kiểm Thử Tài Khoản Mới Thật 100%

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

## 9. Dịch Vụ Lưu Trữ & AI Tách Nền Ảnh Trang Phục (Cloudinary)

- **Môi trường Cloud:** Cloudinary Product Environment (`bvxcghig`).
- **Công nghệ Computer Vision:** Tự động nhận diện biên trang phục, bóc tách hoàn toàn nền hậu cảnh (`background_removal: 'cloudinary_ai'`) và lưu ảnh định dạng PNG trong suốt.
- **Trạng thái:** ✅ Sẵn sàng 100% cho mọi hình ảnh người dùng chụp từ camera hoặc chọn từ thư viện ảnh.

---

## 10. Đặt Lại Trạng Thái Mặc Định (Reset to Default)

Nếu trong quá trình test bạn đã thêm/xóa nhiều món đồ hoặc outfit và muốn đưa ứng dụng về lại trạng thái chuẩn demo ban đầu:
- Vào **Hồ sơ (Profile)** → **Cài đặt tài khoản** → Chọn **Khôi phục dữ liệu demo mặc định**.
- Hoặc đăng xuất và đăng nhập lại bằng tài khoản `demo@wearsy.app`.

---

*Tài liệu nội bộ dự án EXE101 - WEARSY Mobile System.*

