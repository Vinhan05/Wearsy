# Cấu Trúc Dự Án & Quy Định Cho Agent

## 1. Cấu Trúc Thư Mục Chuẩn (Target Project Structure)

```text
/my-large-project
├── .agent/                 # Cấu hình nội bộ cho Antigravity Agent
│   └── rules.md            # Các nguyên tắc code (linting, naming convention)
├── apps/                   # Nơi chứa các ứng dụng/services chính
│   ├── mobile-client/      # Ứng dụng Frontend 
│   │   ├── assets/         # Hình ảnh, font chữ, 2D resources
│   │   ├── lib/            # Mã nguồn chính của client
│   │   │   ├── core/       # Cấu hình chung, utilities, network client
│   │   │   ├── features/   # Chia mã nguồn theo từng cụm tính năng (Domain-driven)
│   │   │   └── shared/     # Các UI component dùng chung xuyên suốt app
│   │   └── test/           # Unit test và widget test
│   └── api-server/         # Máy chủ Backend 
│       ├── src/
│       │   ├── config/     # Biến môi trường, cấu hình database
│       │   ├── controllers/# Xử lý API request/response
│       │   ├── models/     # Định nghĩa schema (Database models)
│       │   ├── routes/     # Định tuyến API (Endpoints)
│       │   └── services/   # Business logic (Xử lý nghiệp vụ lõi)
│       └── tests/
├── packages/               # Các module hoặc thư viện tự viết dùng chung
│   ├── shared-types/       # Type definitions/Interfaces chung cho cả hệ thống
│   └── custom-lint/        # Các quy tắc linting tự viết
├── infrastructure/         # Cấu hình hạ tầng mạng và môi trường
│   ├── docker/             # Dockerfiles và docker-compose cho local/production
│   └── scripts/            # Shell/PowerShell scripts tự động hóa (build, migrate db)
├── docs/                   # Tài liệu dự án (API Postman/Swagger, Architecture)
├── .gitignore
└── AGENTS.md               # File quy định cấu trúc thư mục này cho Agent đọc
```

---

## 2. Quy Tắc Dọn Dẹp (Refactoring Rules)

Agent bắt buộc tuân thủ tuyệt đối các nguyên tắc sau:

1. **Gom API Endpoints:** Mọi API endpoint cũ đang nằm rải rác phải được gom về `/apps/api-server/src/routes/`.
2. **Tách biệt Data Access Layer:** Mọi logic truy xuất cơ sở dữ liệu phải được tách khỏi controller và đưa vào `/apps/api-server/src/services/`.
3. **Phân vùng giao diện Mobile:** Các thành phần giao diện (UI) dùng cho màn hình di động phải nằm trong `/apps/mobile-client/lib/features/<tên-tính-năng>/`.
4. **Giới hạn Thư mục Gốc & Quarantine:** Tuyệt đối không tạo thêm folder gốc (root folder) mới ngoài những thư mục đã được định nghĩa ở trên. Nếu có file rác không xác định, hãy gom tạm vào `/quarantine/` để tôi tự review.
