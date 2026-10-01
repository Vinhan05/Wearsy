# CI/CD Trigger Rule for WEARSY Project

Khi người dùng nhập **"chạy CI/CD"** (hoặc các biến thể như `chay CI/CD`, `run CI/CD`, `test CI/CD`, `chạy pipeline`):

Agent **BẮT BUỘC TỰ ĐỘNG CHẠY TOÀN BỘ FLOW CI/CD** chuẩn của dự án theo đúng đặc tả:

---

## 1. Flow Kiểm thử Tự động (Full CI Pipeline Execution)

Chạy tuần tự 7 bước cho cả **Backend** và **Mobile**:

### A. Phân hệ Backend (`wearsy-backend`):
1. **Install dependencies:** `npm ci`
2. **Check format:** `npm run format:check`
3. **Run lint:** `npm run lint`
4. **Run typecheck:** `npm run typecheck`
5. **Run unit tests:** `npm test -- --coverage`
6. **Run integration tests:** `npm run test:e2e` (bao gồm test `/health`)
7. **Build project:** `npm run build`

### B. Phân hệ Mobile (`wearsy_mobile`):
1. **Install dependencies:** `flutter pub get`
2. **Check format:** `dart format --output=none --set-exit-if-changed lib test`
3. **Run lint:** `flutter analyze --no-fatal-infos`
4. **Run typecheck:** `dart analyze --fatal-warnings lib test`
5. **Run unit tests:** `flutter test test/auth_validation_test.dart test/smart_fit_test.dart --coverage`
6. **Run integration tests:** `flutter test test/widget_test.dart`
7. **Build project:** `flutter build apk --debug --no-tree-shake-icons` (Smoke test build)

### C. Safe Database Migration Check:
- Chạy: `node database/migrate.js --dry-run`

---

## 2. Quy tắc Đánh giá PR Gate
- Nếu **BẤT KỲ** bước nào trong 7 bước trên bị fail ➔ Báo cáo CI FAILED, chỉ rõ dòng lỗi và yêu cầu sửa trước khi merge.
- Nếu **TẤT CẢ** các bước đều pass ➔ Báo cáo PR Gate PASSED, đủ điều kiện Review và Merge vào `main`.

---

## 3. Xác minh CD Workflow
- Kiểm tra tính hợp lệ của file [`.github/workflows/ci.yml`](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/.github/workflows/ci.yml) và [`.github/workflows/cd.yml`](file:///d:/FPTDocuments/FA26/EXE101/Project%20WEARSY/.github/workflows/cd.yml).
- Đảm bảo CD flow tuân thủ: `Merge -> main` ➔ `Build artifact (tag sha-...)` ➔ `Push GHCR` ➔ `Deploy Staging` ➔ `Smoke Test Staging` ➔ `Deploy Production` ➔ `Post-deployment Health Check` ➔ `Rollback nếu có lỗi`.
