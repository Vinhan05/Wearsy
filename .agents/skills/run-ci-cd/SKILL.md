---
name: run-ci-cd
description: >-
  Tự động thực thi toàn bộ chu trình CI/CD chuẩn cho dự án WEARSY khi người dùng
  yêu cầu "chạy CI/CD", "run CI/CD", "kiểm tra CI/CD" hoặc "chạy pipeline".
---

# WEARSY Full CI/CD Execution Skill

Kỹ năng này chịu trách nhiệm tự động chạy kiểm thử toàn diện 7 tầng của cả Backend và Mobile, xác thực Database Migration, kiểm tra Health Check và mô phỏng luồng CD khép kín.

## Các bước thực thi chi tiết

### Bước 1: Backend CI (7 bước tuần tự)
Chạy trong thư mục `apps/api-server`:
1. `npm ci`
2. `npm run format:check`
3. `npm run lint`
4. `npm run typecheck`
5. `npm test -- --coverage`
6. `npm run test:e2e`
7. `npm run build`

### Bước 2: Mobile CI (7 bước tuần tự)
Chạy trong thư mục `apps/mobile-client`:
1. `flutter pub get`
2. `dart format --output=none --set-exit-if-changed lib test`
3. `flutter analyze --no-fatal-infos`
4. `dart analyze --fatal-warnings lib test`
5. `flutter test test/auth_validation_test.dart test/smart_fit_test.dart --coverage`
6. `flutter test test/widget_test.dart`
7. `flutter build apk --debug --no-tree-shake-icons`

### Bước 3: Kiểm tra Cơ sở Dữ liệu & Safe Migration
Tại thư mục gốc:
```bash
node infrastructure/scripts/migrate.js --dry-run
```

### Bước 4: Tổng hợp & Đánh giá Cổng PR Gate
Xuất bảng báo cáo kết quả:
| Phân hệ / Bước | Lệnh thực thi | Kết quả | Ghi chú |
| :--- | :--- | :---: | :--- |
| **Backend 1-7** | Format, Lint, Typecheck, Test, E2E, Build | PASS / FAIL | Báo cáo chi tiết |
| **Mobile 1-7** | Format, Lint, Typecheck, Test, Smoke Build | PASS / FAIL | Báo cáo chi tiết |
| **Safe Migration** | Transaction DDL & Dry-run | PASS / FAIL | An toàn dữ liệu |

- **Kết luận PR Gate:**
  - Nếu tất cả PASS ➔ Thông báo `✅ PR GATE PASSED: Đủ điều kiện để Review & Merge vào main`.
  - Nếu có lỗi ➔ Dừng lại ngay lập tức, phân tích nguyên nhân và đề xuất phương án sửa lỗi.
