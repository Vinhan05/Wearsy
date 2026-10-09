# 🌐 HƯỚNG DẪN DỊCH THUẬT & BẢN ĐỊA HÓA ỨNG DỤNG WEARSY
*(Tài liệu bàn giao cho nhân sự phụ trách dịch thuật / biên dịch ngôn ngữ)*

---

## 📌 1. Giới Thiệu Dự Án & Bối Cảnh Sản Phẩm

- **Tên ứng dụng:** **WEARSY**
- **Slogan:** *Smart Wardrobe & AI Fashion Assistant* (Tủ đồ thông minh & Trợ lý thời trang ứng dụng AI).
- **Đối tượng người dùng chính:** Giới trẻ (Gen Z, Millennials), người yêu thích thời trang, bận rộn, cần quản lý tủ quần áo thông minh và nhận gợi ý trang phục mỗi ngày từ AI.
- **Phong cách ngôn từ (Tone of Voice):**
  - **Trẻ trung, hiện đại, thời thượng (Trendy & Chic):** Gần gũi nhưng không quá suồng sã.
  - **Ngắn gọn, súc tích (Concise):** Phù hợp với màn hình điện thoại di động (Mobile App UI).
  - **Khích lệ, tích cực & truyền cảm hứng:** Giúp người dùng cảm thấy tự tin hơn vào gu ăn mặc của mình.

---

## ⚠️ 2. Các Quy Tắc Kỹ Thuật Bắt Buộc (Critical Rules)

Để bản dịch sau khi bàn giao có thể đưa trực tiếp vào code mà không gây lỗi ứng dụng, người dịch cần tuân thủ nghiêm ngặt các quy tắc sau:

### 2.1. Tuyệt đối không dịch hoặc làm mất Biến (Placeholders)
Trong văn bản sẽ xuất hiện các đoạn nằm trong dấu ngoặc nhọn `{...}` hoặc có dấu `$`. Đây là các giá trị hệ thống tự động điền vào khi chạy:
- Ví dụ:
  - Gốc: `Chào buổi sáng, {userName}!`
  - Tiếng Anh: `Good morning, {userName}!` *(Giữ nguyên `{userName}`, không dịch thành `{tênNgườiDùng}`)*
  - Gốc: `Đã chọn {count} món đồ`
  - Tiếng Anh: `{count} items selected`

### 2.2. Kiểm soát độ dài từ ngữ (UI Constraint - Tránh vỡ khung)
- Giao diện mobile có kích thước nút bấm, thẻ thông tin (Card) giới hạn.
- Bản dịch nên có độ dài tương đương hoặc **không dài quá 20% so với câu gốc tiếng Việt**.
- Với các **Nút bấm (Button)** hoặc **Tiêu đề tab (Tab Bar)**, ưu tiên từ ngắn:
  - *Ví dụ:* Thay vì dịch "Thêm vào danh sách đồ phối của bạn" -> Dùng "Lưu bộ phối" (Save outfit).

### 2.3. Quy chuẩn viết hoa & dấu câu
- **Nút bấm & Menu:** Viết hoa chữ cái đầu mỗi từ (Title Case) đối với tiếng Anh (VD: `Add Item`, `Save Outfit`), hoặc viết hoa đầu câu theo phong cách tự nhiên.
- **Dấu câu:** Giữ nguyên các biểu tượng cảm xúc (Emoji), dấu chấm câu `.` `!` `...` ở cuối câu nếu bản gốc có.

---

## 👗 3. Bảng Thuật Ngữ Thời Trang WEARSY (Fashion Glossary)

Để đảm bảo tính nhất quán trên toàn ứng dụng, vui lòng tham khảo bảng quy ước thuật ngữ:

| Thuật ngữ gốc (VI) | Gợi ý Tiếng Anh (EN) | Gợi ý Ngôn ngữ khác (Ví dụ Nhật/Hàn/Pháp/Trung) | Ghi chú ngữ cảnh |
| :--- | :--- | :--- | :--- |
| **Tủ đồ** | Wardrobe / Closet | クローゼット / 옷장 / 衣橱 | Không gian lưu trữ đồ ảo |
| **Phối đồ / Bộ phối** | Outfit / Mix & Match | コーディネート / 착장, 코디 / 穿搭 | Một bộ đồ kết hợp nhiều món |
| **Chấm điểm màu sắc** | Color Score | カラーマッチ度 / 컬러 점수 / 色彩评分 | Tính năng AI chấm độ hài hòa màu sắc |
| **Bảng màu / Bảng màu cá nhân** | Color Palette / Personal Palette | パーソナルカラー / 퍼스널 컬러 / 个人色彩 | Bảng màu phù hợp phong cách |
| **Trang phục hôm nay (OOTD)** | Today's Outfit / OOTD | 今日のコーデ / 오늘의 룩 / 今日穿搭 | Gợi ý mặc trong ngày |
| **Trợ lý AI / AI Stylist** | AI Stylist / AI Assistant | AIスタイリスト / AI 스타일리스트 / AI 造型师 | AI gợi ý phong cách |
| **Tủ đồ con / Bộ sưu tập** | Capsule / Collection | カプセル / 캡슐 컬렉션 / 胶囊衣橱 | Tủ đồ theo mùa, theo dịp |
| **Dịp mặc** | Occasion | シーン / TPO / 착용 상황 / 适用场合 | Đi làm, dự tiệc, đi chơi, hẹn hò... |
| **Món đồ** | Item / Clothing Item | アイテム / 의류 아이템 / 单品 | Từng chiếc áo, quần, váy lẻ |

---

## 🗂️ 4. Danh Mục Màn Hình & Các Phân Đoạn Cần Dịch

Ứng dụng gồm **8 phân đoạn chính**:
1. **Common & Navigation:** Nút bấm chung (Lưu, Hủy, Đóng, Xóa...), Thanh điều hướng đáy (Bottom Bar).
2. **Authentication (Xác thực):** Đăng nhập, Đăng ký, Quên mật khẩu, Nhập mã OTP, Khóa tài khoản tạm thời do nhập sai nhiều lần.
3. **Wardrobe (Tủ đồ):** Quản lý quần áo, Danh mục (Áo, Quần, Đầm, Phụ kiện...), Thêm món đồ mới bằng Camera/Thư viện, Chi tiết món đồ.
4. **Outfits (Phối đồ & Trợ lý ảo):** Gợi ý phối đồ theo thời tiết/dịp, Tạo bộ đồ mới, Mix & Match, Đánh giá độ phù hợp.
5. **Color Score (Phân tích Màu sắc):** Chấm điểm trang phục, phân tích tương phản, tone màu da, bảng màu khuyến nghị.
6. **Smart Shopping (Mua sắm):** Gợi ý đồ còn thiếu trong tủ để bổ sung, Giỏ hàng, Chi tiết sản phẩm.
7. **Profile & Settings (Cá nhân & Cài đặt):** Thông tin cá nhân, Đổi giao diện (Theme), Đổi mật khẩu, Cài đặt ngôn ngữ, Trợ giúp.
8. **Notifications & System Alerts:** Thông báo thành công, Báo lỗi kết nối mạng, Xác nhận hành động nguy hiểm.

---

## 📥 5. Cấu Trúc Các File Ngôn Ngữ Riêng Biệt (docs/translations/)

Dự án đã chuẩn bị đầy đủ cả file **Excel (.xlsx)** chuyên nghiệp (mở trực tiếp không sợ lỗi font) và file **CSV**:

### 📊 Các File Excel Trực Tiếp (.xlsx):
* 🇻🇳 **[WEARSY_Tieng_Viet_Goc.xlsx](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/docs/translations/WEARSY_Tieng_Viet_Goc.xlsx)**: File Excel chứa toàn bộ từ ngữ tiếng Việt đang dùng trên app (định dạng đẹp, cố định dòng tiêu đề, có độ rộng cột chuẩn).
* 🌐 **[WEARSY_Mau_Dich_Ngon_Ngu.xlsx](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/docs/translations/WEARSY_Mau_Dich_Ngon_Ngu.xlsx)**: File Excel tổng hợp gồm **4 Sheet** riêng biệt:
  - **Sheet 1 (`Mẫu Dịch Ngôn Ngữ 1`):** Dành cho bạn ngôn ngữ 1 điền vào cột màu xanh lá.
  - **Sheet 2 (`Mẫu Dịch Ngôn Ngữ 2`):** Dành cho bạn ngôn ngữ 2 điền vào cột màu xanh lá.
  - **Sheet 3 (`Tiếng Việt Chuẩn`):** Toàn bộ dữ liệu tiếng Việt gốc để tra cứu.
  - **Sheet 4 (`Tiếng Anh Chuẩn`):** Bản dịch tiếng Anh chuẩn thời trang để tham chiếu.

### 📄 Các File CSV Độc Lập (Tùy chọn):
| File | Mục đích | Cách sử dụng |
| :--- | :--- | :--- |
| 🇻🇳 [vi.csv](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/docs/translations/vi.csv) | **Ngôn ngữ gốc Tiếng Việt** | Bản chuẩn hiện tại trên app (chỉ đọc tham khảo). |
| 🇬🇧 [en.csv](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/docs/translations/en.csv) | **Tiếng Anh (English)** | Đã có sẵn bản dịch chuẩn thời trang. |

### 5.1. Cấu trúc cột trong mỗi file mẫu dịch:
- **`Mã kỹ thuật (key)`**: Mã định danh trong code (❌ **Giữ nguyên 100%, không chỉnh sửa**).
- **`Màn hình (screen)`**: Tên màn hình/tính năng chứa từ đó (để biết ngữ cảnh dịch).
- **`Tiếng Việt gốc`**: Câu gốc tiếng Việt để đối chiếu.
- **`Tiếng Anh tham chiếu`**: Câu tham chiếu tiếng Anh để hiểu rõ thuật ngữ thời trang quốc tế.
- **`Bản dịch mới`**: ✍️ **Cột duy nhất cần điền bản dịch của ngôn ngữ mới**.
- **`Ghi chú kỹ thuật & Giữ biến`**: Các nhắc nhở kỹ thuật quan trọng (ví dụ: cần giữ biến `{userName}`, `{count}`).

### 5.2. Cách làm việc với file:
1. Mở trực tiếp file Excel `.xlsx` bằng **Microsoft Excel** hoặc kéo thả vào **Google Sheets**.
2. Điền nội dung dịch vào cột bản dịch mới.
3. Lưu lại và gửi lại file Excel hoặc link Google Sheets.

---

## ✅ 6. Checklist Kiểm Tra Trước Khi Bàn Giao

Trước khi gửi lại file cho nhóm phát triển (Developer), vui lòng kiểm tra nhanh:
- [ ] Đã dịch 100% các dòng trong cột `your_translation`, không để trống ô nào.
- [ ] Tất cả các biến `{...}` đều được giữ nguyên dạng (ví dụ: `{userName}`, `{count}`).
- [ ] Không có từ ngữ quá dài gây tràn khung (đặc biệt ở các nút bấm `btn_...`).
- [ ] Giọng văn tự nhiên, chuẩn phong cách thời trang WEARSY, nhất quán giữa các màn hình.
- [ ] File được lưu đúng định dạng UTF-8 (không bị lỗi font tiếng có dấu hoặc chữ tượng hình).

---
*Nếu có bất kỳ thắc mắc nào về ngữ cảnh cụ thể của từng từ, vui lòng liên hệ nhóm phát triển để xem ảnh chụp màn hình tương ứng.*
