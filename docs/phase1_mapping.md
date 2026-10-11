# Báo Cáo Rà Soát & Bản Đồ Ánh Xạ Hệ Thống API & Database (Phase 1 Mapping)
**Dự án:** WEARSY AI Smart Wardrobe  
**Mục tiêu:** Định vị, kiểm toán vi phạm quy tắc kiến trúc và lập bản đồ di chuyển chuẩn theo [AGENTS.md](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/AGENTS.md).  
**Chế độ thực thi:** Read-Only Inventory (Không sửa đổi mã nguồn).

---

## 1. Tổng Quan Hiện Trạng Hệ Thống (Executive Summary)

Sau khi quét toàn diện hệ thống mã nguồn hiện tại (`wearsy-backend`, `database`, `wearsy_mobile`, `docs`), hiện trạng được ghi nhận như sau:

| Hạng mục kiểm toán | Số lượng phát hiện | Đánh giá tình trạng tuân thủ theo AGENTS.md |
| :--- | :--- | :--- |
| **Controllers & Routers** | 6 Controllers, 22 Endpoints | ⚠️ **Vi phạm Rule 1 & Rule 2:** Thiếu folder `src/routes/` tập trung; `wardrobe.controller.ts` truy vấn trực tiếp DB. |
| **Services (Business Logic)** | 8 Services | ✅ Hầu hết logic nghiệp vụ đã được đóng gói trong Service; cần tiếp nhận thêm CRUD từ `wardrobe.controller.ts`. |
| **Entities / Database Models** | 7 Entities TypeORM, 7 Tables SQL | ⚠️ Cần chuyển từ các sub-module rải rác về `/apps/api-server/src/models/`. |
| **Database Migrations & Scripts** | 3 files (`database/`) | ⚠️ Cần chuyển runner về `/infrastructure/scripts/` và schema về `/apps/api-server/src/models/` hoặc giữ tại DB layer chuẩn. |
| **Thiếu hụt Endpoint (Missing APIs)** | 2 Endpoints (`/outfits/*`, `/users/style-profile`) | ⚠️ Mobile & OpenAPI đã khai báo nhưng Backend chưa có Controller tiếp nhận (chỉ mới có Service nội bộ). |
| **File nghi vấn / Cần cách ly** | 10 Files | ⚠️ Thư mục root `wearsy UI` (9 ảnh PNG) và file `.env.backup` vi phạm Rule 4. |

---

## 2. Bảng Ánh Xạ Chi Tiết: API & Controllers

> **Quy tắc kiểm toán áp dụng:**
> - **Rule 1:** Mọi API endpoint cũ đang nằm rải rác phải được gom về `/apps/api-server/src/routes/`.
> - **Rule 2:** Mọi logic truy xuất cơ sở dữ liệu phải được tách khỏi controller và đưa vào `/apps/api-server/src/services/`.

| File hiện tại | Endpoints phụ trách | Vị trí đích dự kiến (`apps/api-server/...`) | Vi phạm quy tắc phát hiện | Hành động xử lý (Phase 2) | Mức độ rủi ro |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `wearsy-backend/src/app.controller.ts` | `GET /health` | `apps/api-server/src/controllers/health.controller.ts`<br>`apps/api-server/src/routes/health.route.ts` | Không có vi phạm Rule 2 (không gọi DB). Route chưa nằm trong `src/routes/`. | Tách Route & Controller | **Thấp (Low)** |
| `wearsy-backend/src/modules/auth/auth.controller.ts` | `POST /auth/register`<br>`POST /auth/login`<br>`POST /auth/google`<br>`POST /auth/facebook`<br>`POST /auth/logout`<br>`POST /auth/change-password`<br>`POST /auth/send-otp`<br>`POST /auth/verify-otp` | `apps/api-server/src/controllers/auth.controller.ts`<br>`apps/api-server/src/routes/auth.route.ts` | DTOs khai báo trực tiếp trong file controller. Route chưa tập trung. | Tách DTOs ra module riêng, tách routes sang `src/routes/auth.route.ts`. | **Trung bình (Medium)** |
| `wearsy-backend/src/modules/users/users.controller.ts` | `POST /users/upgrade-vip`<br>`GET /users/profile`<br>`PUT /users/profile` | `apps/api-server/src/controllers/users.controller.ts`<br>`apps/api-server/src/routes/users.route.ts` | Thiếu endpoint `GET /users/style-profile` mà Mobile & OpenAPI đang dùng. | Tách Route & Controller; bổ sung handler style-profile. | **Thấp (Low)** |
| `wearsy-backend/src/modules/wardrobe/wardrobe.controller.ts` | `POST /wardrobe/upload`<br>`POST /wardrobe/analyze-image`<br>`POST /wardrobe/scan-bulk`<br>`POST /wardrobe/bulk-commit`<br>`GET /wardrobe/items`<br>`POST /wardrobe/items`<br>`PUT /wardrobe/items/:id`<br>`DELETE /wardrobe/items/:id`<br>`DELETE /wardrobe/items` | `apps/api-server/src/controllers/wardrobe.controller.ts`<br>`apps/api-server/src/routes/wardrobe.route.ts` | 🚨 **VI PHẠM NGHIÊM TRỌNG RULE 2:** Controller tiêm `Repository<WardrobeItemEntity>` & `Repository<UserEntity>` và gọi trực tiếp `itemRepo.find/save/update/create`. | **Refactor bắt buộc:** Chuyển toàn bộ logic CRUD và helper `getOrCreateUserId` sang `WardrobeService`. | **Cao (High)** |
| `wearsy-backend/src/modules/shopping/shopping.controller.ts` | `POST /shopping/compatibility-check`<br>`GET /shopping/missing-items`<br>`GET /shopping/history`<br>`GET /shopping/sample-products` | `apps/api-server/src/controllers/shopping.controller.ts`<br>`apps/api-server/src/routes/shopping.route.ts` | Không vi phạm Rule 2 (ủy thác qua `ShoppingService`). Route chưa tập trung. | Tách Route & Controller sang `src/routes/`. | **Thấp (Low)** |
| `wearsy-backend/src/modules/gamification/gamification.controller.ts` | `POST /gamification/color-score`<br>`GET /gamification/challenges` | `apps/api-server/src/controllers/gamification.controller.ts`<br>`apps/api-server/src/routes/gamification.route.ts` | Không vi phạm Rule 2 (ủy thác qua `GamificationService`). Route chưa tập trung. | Tách Route & Controller sang `src/routes/`. | **Thấp (Low)** |
| *(Chưa có Controller)* `wearsy-backend/src/modules/outfits/` | `POST /outfits/recommend`<br>`POST /outfits/recommend-by-context`<br>`POST /outfits/:id/rate` | `apps/api-server/src/controllers/outfits.controller.ts`<br>`apps/api-server/src/routes/outfits.route.ts` | Đã có `AiOutfitService` nhưng chưa export controller tiếp nhận request từ Mobile/OpenAPI. | Tạo mới `outfits.controller.ts` và `outfits.route.ts` để kết nối `AiOutfitService`. | **Trung bình (Medium)** |

---

## 3. Bảng Ánh Xạ Chi Tiết: Database Models, Configs & Services

| File hiện tại | Chức năng hiện tại | Vị trí đích (`AGENTS.md`) | Đánh giá & Rủi ro | Hành động cần làm (Phase 2) |
| :--- | :--- | :--- | :--- | :--- |
| `database/schema.sql` | DDL khởi tạo 7 bảng PostgreSQL & triggers | `apps/api-server/src/models/schema.sql` (hoặc `infrastructure/docker/postgres/init.sql`) | Độc lập, chạy qua transaction an toàn. Rủi ro: Thấp. | Di chuyển vào vị trí hạ tầng / DB initialization. |
| `database/migrate.js` | Script chạy migration có hỗ trợ Dry-Run | `infrastructure/scripts/migrate.js` | Đang được workflow CI/CD gọi ở root (`node database/migrate.js --dry-run`). Rủi ro: Cao (ảnh hưởng CI/CD). | Di chuyển vào `infrastructure/scripts/` và cập nhật đường dẫn trong `ci.yml`, `cd.yml`, `ci-cd-trigger.md`. |
| `database/seed.sql` | Dữ liệu mẫu danh mục quần áo | `infrastructure/scripts/seed.sql` | Độc lập. Rủi ro: Thấp. | Di chuyển đồng bộ cùng schema/migrate. |
| `wearsy-backend/src/database/database.config.ts` | Cấu hình TypeORM kết nối PostgreSQL / Supabase | `apps/api-server/src/config/database.config.ts` | Đang đọc trực tiếp qua `ConfigService`. Rủi ro: Thấp. | Di chuyển sang thư mục `src/config/` chuẩn. |
| `wearsy-backend/src/modules/users/entities/user.entity.ts` | Model người dùng (bảng `users`) | `apps/api-server/src/models/user.entity.ts` | Dùng bởi Auth, Users, Wardrobe. Rủi ro: Trung bình. | Gom về `src/models/`, cập nhật import path. |
| `wearsy-backend/src/modules/users/entities/user-profile.entity.ts` | Model hồ sơ (bảng `user_profiles`) | `apps/api-server/src/models/user-profile.entity.ts` | Quan hệ 1-1 với `UserEntity`. Rủi ro: Thấp. | Gom về `src/models/`. |
| `wearsy-backend/src/modules/wardrobe/entities/category.entity.ts` | Model danh mục (bảng `categories`) | `apps/api-server/src/models/category.entity.ts` | Quan hệ đệ quy (parent-child). Rủi ro: Thấp. | Gom về `src/models/`. |
| `wearsy-backend/src/modules/wardrobe/entities/wardrobe-item.entity.ts` | Model trang phục (bảng `wardrobe_items`) | `apps/api-server/src/models/wardrobe-item.entity.ts` | Bảng trung tâm tủ đồ. Rủi ro: Trung bình. | Gom về `src/models/`. |
| `wearsy-backend/src/modules/outfits/entities/outfit.entity.ts` | Model outfit (bảng `outfits`) | `apps/api-server/src/models/outfit.entity.ts` | Khóa ngoại tới `users`. Rủi ro: Thấp. | Gom về `src/models/`. |
| `wearsy-backend/src/modules/outfits/entities/outfit-item.entity.ts` | Junction table (bảng `outfit_items`) | `apps/api-server/src/models/outfit-item.entity.ts` | Nối `outfits` và `wardrobe_items`. Rủi ro: Thấp. | Gom về `src/models/`. |
| `wearsy-backend/src/modules/shopping/entities/shopping-check-log.entity.ts` | Model lịch sử mua sắm (`shopping_check_logs`) | `apps/api-server/src/models/shopping-check-log.entity.ts` | Khóa ngoại tới `users`. Rủi ro: Thấp. | Gom về `src/models/`. |
| `wearsy-backend/src/modules/auth/auth.service.ts` | Nghiệp vụ xác thực (bcrypt, JWT, OTP) | `apps/api-server/src/services/auth.service.ts` | Đóng gói DB chuẩn qua `UserRepository`. Rủi ro: Thấp. | Chuyển sang `src/services/`. |
| `wearsy-backend/src/modules/users/users.service.ts` | Nghiệp vụ User, VIP, Profile | `apps/api-server/src/services/users.service.ts` | Đóng gói DB chuẩn qua `UserRepository`. Rủi ro: Thấp. | Chuyển sang `src/services/`. |
| `wearsy-backend/src/modules/wardrobe/services/wardrobe-scanner.service.ts` | AI Scanner qua Gemini & Cloudinary | `apps/api-server/src/services/wardrobe-scanner.service.ts` | Đã có sẵn repo items & category. Rủi ro: Trung bình. | Chuyển sang `src/services/`, mở rộng để tiếp nhận CRUD từ controller. |
| `wearsy-backend/src/modules/outfits/services/ai-outfit.service.ts` | Phối đồ AI qua Gemini (Layering + Smart Fit) | `apps/api-server/src/services/ai-outfit.service.ts` | Độc lập, có test case đi kèm. Rủi ro: Thấp. | Chuyển sang `src/services/`. |
| `wearsy-backend/src/modules/shopping/services/shopping.service.ts` | Đánh giá mua sắm qua Gemini & DB Log | `apps/api-server/src/services/shopping.service.ts` | Đóng gói repo `shoppingLogRepo`. Rủi ro: Thấp. | Chuyển sang `src/services/`. |
| `wearsy-backend/src/modules/gamification/services/gamification.service.ts` | Chấm điểm màu sắc bánh xe màu | `apps/api-server/src/services/gamification.service.ts` | Thuần thuật toán logic, không dính DB. Rủi ro: Thấp. | Chuyển sang `src/services/`. |

---

## 4. Danh Sách Đề Xuất Cách Ly (`/quarantine/`)

Theo **Rule 4 trong AGENTS.md**: *"Tuyệt đối không tạo thêm folder gốc mới. Nếu có file rác không xác định, hãy gom tạm vào `/quarantine/` để người dùng tự review."*

Các tệp sau đang nằm sai quy định tại root hoặc là tệp sao lưu dư thừa:

| Tệp / Thư mục hiện tại | Loại tệp | Lý do đề xuất cách ly | Đề xuất xử lý cuối cùng |
| :--- | :--- | :--- | :--- |
| `wearsy UI/1.png` | Resource đồ họa UI | Nằm ở root folder không được phép (`wearsy UI`). | Di chuyển về `apps/mobile-client/assets/designs/` hoặc `/quarantine/wearsy-ui/`. |
| `wearsy UI/2.png` | Resource đồ họa UI | Nằm ở root folder không được phép. | Di chuyển về `/quarantine/wearsy-ui/`. |
| `wearsy UI/3.png` | Resource đồ họa UI | Nằm ở root folder không được phép. | Di chuyển về `/quarantine/wearsy-ui/`. |
| `wearsy UI/home (2).png` | Ảnh mockup Figma | Nằm ở root folder không được phép. | Di chuyển về `/quarantine/wearsy-ui/`. |
| `wearsy UI/home.png` | Ảnh mockup Figma | Nằm ở root folder không được phép. | Di chuyển về `/quarantine/wearsy-ui/`. |
| `wearsy UI/theme2_blue_royal.png` | Ảnh theme | Nằm ở root folder không được phép. | Di chuyển về `/quarantine/wearsy-ui/`. |
| `wearsy UI/tủ đồ (2).png` | Ảnh mockup | Nằm ở root folder không được phép. | Di chuyển về `/quarantine/wearsy-ui/`. |
| `wearsy UI/tủ đồ (3).png` | Ảnh mockup | Nằm ở root folder không được phép. | Di chuyển về `/quarantine/wearsy-ui/`. |
| `wearsy UI/tủ đồ.png` | Ảnh mockup | Nằm ở root folder không được phép. | Di chuyển về `/quarantine/wearsy-ui/`. |
| `wearsy-backend/.env.backup` | File nhạy cảm / backup | File sao lưu môi trường cũ không nên commit trực tiếp. | Đưa vào `/quarantine/env-backup/` hoặc thêm vào `.gitignore`. |

---

## 5. Kế Hoạch Di Chuyển Bước Tiếp Theo (Phase 2 Roadmap)

Để đảm bảo không làm gián đoạn CI/CD pipeline hiện tại, quá trình di chuyển sẽ chia thành 4 bước tuần tự:

1. **Bước 1: Chuẩn bị Hạ tầng thư mục & Cách ly file thừa (Quarantine)**
   - Tạo cây thư mục rỗng chuẩn: `/apps/api-server/src/{config,controllers,models,routes,services}`, `/apps/mobile-client`, `/packages`, `/infrastructure/{docker,scripts}`.
   - Gom `wearsy UI/` và `.env.backup` vào `/quarantine/`.
2. **Bước 2: Di chuyển & Tách biệt Data Access Layer (Fix Rule 2)**
   - Gom các entity vào `/apps/api-server/src/models/`.
   - Tạo `WardrobeService.ts` để bóc toàn bộ logic truy vấn DB ra khỏi `wardrobe.controller.ts`.
   - Chuyển toàn bộ services về `/apps/api-server/src/services/`.
3. **Bước 3: Gom Routes & Tái cấu trúc Controllers (Fix Rule 1)**
   - Tách router endpoints về `/apps/api-server/src/routes/`.
   - Bổ sung `OutfitsController` để khớp hoàn toàn với `docs/openapi.yaml` và `wearsy_mobile`.
4. **Bước 4: Cập nhật Scripts, CI/CD Workflows & Kiểm thử Hồi quy**
   - Cập nhật đường dẫn migration trong `.github/workflows/ci.yml` và `.github/workflows/cd.yml`.
   - Chạy lệnh `npm test` và `npm run build` để kiểm tra độ tương thích 100%.
