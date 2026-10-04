-- ========================================================
-- WEARSY Smart Fashion Assistant - PostgreSQL Database Dump
-- Export Date: 2026-10-04T13:04:20.299Z
-- Database Engine: PostgreSQL 15+ (Supabase Cloud)
-- ========================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop tables if exist
DROP TABLE IF EXISTS "shopping_check_logs" CASCADE;
DROP TABLE IF EXISTS "outfit_items" CASCADE;
DROP TABLE IF EXISTS "outfits" CASCADE;
DROP TABLE IF EXISTS "wardrobe_items" CASCADE;
DROP TABLE IF EXISTS "categories" CASCADE;
DROP TABLE IF EXISTS "user_profiles" CASCADE;
DROP TABLE IF EXISTS "users" CASCADE;

-- --------------------------------------------------------
-- Table structure for "users"
-- --------------------------------------------------------
CREATE TABLE "users" (
  "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
  "email" VARCHAR(255) NOT NULL,
  "password_hash" VARCHAR(255) NOT NULL,
  "full_name" VARCHAR(100) NOT NULL,
  "role" VARCHAR(20) NOT NULL DEFAULT 'USER'::character varying,
  "is_vip" BOOL NOT NULL DEFAULT false,
  "vip_expires_at" TIMESTAMPTZ,
  "is_active" BOOL NOT NULL DEFAULT true,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "avatar_url" VARCHAR(512),
  PRIMARY KEY ("id")
);

-- --------------------------------------------------------
-- Table structure for "user_profiles"
-- --------------------------------------------------------
CREATE TABLE "user_profiles" (
  "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
  "user_id" UUID NOT NULL,
  "preferred_styles" JSONB NOT NULL DEFAULT '[]'::jsonb,
  "color_preferences" JSONB NOT NULL DEFAULT '{}'::jsonb,
  "budget_range" JSONB NOT NULL DEFAULT '{"tier": "medium"}'::jsonb,
  "body_measurements" JSONB NOT NULL DEFAULT '{}'::jsonb,
  "ai_learning_data" JSONB NOT NULL DEFAULT '{}'::jsonb,
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE
);

-- --------------------------------------------------------
-- Table structure for "categories"
-- --------------------------------------------------------
CREATE TABLE "categories" (
  "id" INT4 NOT NULL,
  "parent_id" INT4,
  "name" VARCHAR(100) NOT NULL,
  "code" VARCHAR(50) NOT NULL,
  "description" TEXT,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  FOREIGN KEY ("parent_id") REFERENCES "categories" ("id") ON DELETE CASCADE
);

-- --------------------------------------------------------
-- Table structure for "wardrobe_items"
-- --------------------------------------------------------
CREATE TABLE "wardrobe_items" (
  "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
  "user_id" UUID NOT NULL,
  "category_id" INT4 NOT NULL,
  "name" VARCHAR(150) NOT NULL,
  "image_url" VARCHAR(512) NOT NULL,
  "bg_removed_url" VARCHAR(512),
  "primary_color" VARCHAR(50) NOT NULL,
  "sub_colors" JSONB NOT NULL DEFAULT '[]'::jsonb,
  "style_tags" JSONB NOT NULL DEFAULT '[]'::jsonb,
  "season" VARCHAR(30) NOT NULL DEFAULT 'ALL'::character varying,
  "purchase_price" NUMERIC,
  "wear_count" INT4 NOT NULL DEFAULT 0,
  "ai_processing_status" VARCHAR(20) NOT NULL DEFAULT 'COMPLETED'::character varying,
  "status" VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'::character varying,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "brand" VARCHAR(100) NOT NULL DEFAULT ''::character varying,
  "wardrobe_id" VARCHAR(100) NOT NULL DEFAULT 'default'::character varying,
  "ai_match_score" NUMERIC NOT NULL DEFAULT '9'::numeric,
  "layer_order" INT4 NOT NULL DEFAULT 1,
  PRIMARY KEY ("id")
);

-- --------------------------------------------------------
-- Table structure for "outfits"
-- --------------------------------------------------------
CREATE TABLE "outfits" (
  "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
  "user_id" UUID NOT NULL,
  "title" VARCHAR(150) NOT NULL,
  "occasion" VARCHAR(100),
  "ai_generated" BOOL NOT NULL DEFAULT true,
  "elegance_score" NUMERIC,
  "ai_reasoning" TEXT,
  "is_favorite" BOOL NOT NULL DEFAULT false,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "image_url" VARCHAR(512),
  PRIMARY KEY ("id")
);

-- --------------------------------------------------------
-- Table structure for "outfit_items"
-- --------------------------------------------------------
CREATE TABLE "outfit_items" (
  "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
  "outfit_id" UUID NOT NULL,
  "item_id" UUID NOT NULL,
  "layer_order" INT4 NOT NULL DEFAULT 1,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY ("id"),
  FOREIGN KEY ("outfit_id") REFERENCES "outfits" ("id") ON DELETE CASCADE,
  FOREIGN KEY ("item_id") REFERENCES "wardrobe_items" ("id") ON DELETE CASCADE
);

-- --------------------------------------------------------
-- Table structure for "shopping_check_logs"
-- --------------------------------------------------------
CREATE TABLE "shopping_check_logs" (
  "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
  "user_id" UUID NOT NULL,
  "target_item_name" VARCHAR(150) NOT NULL,
  "target_item_price" NUMERIC NOT NULL,
  "target_image_url" VARCHAR(512),
  "compatible_item_count" INT4 NOT NULL DEFAULT 0,
  "compatibility_score" VARCHAR(20) NOT NULL,
  "recommendation_status" VARCHAR(30) NOT NULL,
  "analysis_details" JSONB NOT NULL DEFAULT '{}'::jsonb,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY ("id")
);

-- ========================================================
-- Dumping data for tables
-- ========================================================

-- Data for "users" (4 rows)
INSERT INTO "users" ("id", "email", "password_hash", "full_name", "role", "is_vip", "vip_expires_at", "is_active", "created_at", "updated_at", "avatar_url") VALUES ('0ba850b6-9ff4-4bcb-9013-9864c92614e9', 'savageflame5764@dustmail.net', 'SSO_AUTO_ACCOUNT', 'savageflame5764', 'USER', FALSE, NULL, TRUE, '"2026-10-01T18:57:44.973Z"', '"2026-10-01T18:57:44.973Z"', NULL);
INSERT INTO "users" ("id", "email", "password_hash", "full_name", "role", "is_vip", "vip_expires_at", "is_active", "created_at", "updated_at", "avatar_url") VALUES ('1a9d1e4a-a0fc-4d12-8f2a-2fc9b1cde955', 'megasable8920@dustmail.net', '$2b$12$T7Pt49JVxMMpy/qWfK1xNuI6UX9ok5Nlrid/UTnOx8dHKDeeE.M0O', 'Demo c', 'USER', TRUE, '"2027-10-01T18:59:43.254Z"', TRUE, '"2026-10-01T18:59:09.770Z"', '"2026-10-01T19:04:47.750Z"', NULL);
INSERT INTO "users" ("id", "email", "password_hash", "full_name", "role", "is_vip", "vip_expires_at", "is_active", "created_at", "updated_at", "avatar_url") VALUES ('d140b5f9-8f4e-4b78-ae35-cbf40907184c', 'acondog468@gmail.com', 'SSO_AUTH_ACCOUNT', 'User 1', 'USER', TRUE, '"2027-10-01T19:00:32.855Z"', TRUE, '"2026-10-01T19:00:05.298Z"', '"2026-10-01T19:38:21.387Z"', NULL);
INSERT INTO "users" ("id", "email", "password_hash", "full_name", "role", "is_vip", "vip_expires_at", "is_active", "created_at", "updated_at", "avatar_url") VALUES ('d9944be7-a90c-483d-8521-3ba0823e6b24', 'velvetray7847@dustmail.net', '$2b$12$qETW9lbMxeKx.OcGxAhd6.Nudf/OGRh5xQPXai7LulC/9Akq.T1PK', 'Demo si3', 'USER', FALSE, NULL, TRUE, '"2026-10-03T17:22:30.235Z"', '"2026-10-03T17:22:30.235Z"', NULL);

-- Data for "wardrobe_items" (8 rows)
INSERT INTO "wardrobe_items" ("id", "user_id", "category_id", "name", "image_url", "bg_removed_url", "primary_color", "sub_colors", "style_tags", "season", "purchase_price", "wear_count", "ai_processing_status", "status", "created_at", "brand", "wardrobe_id", "ai_match_score", "layer_order") VALUES ('5daac710-f084-49cc-a977-2da4f391c8bb', 'd140b5f9-8f4e-4b78-ae35-cbf40907184c', 1, 'Áo Thời Trang Thiết Kế', '/data/user/0/app.wearsy.mobile/cache/scaled_1000000040.jpg', NULL, 'Xám', '[]', '["Smart Casual","Tối giản","Thanh lịch"]', 'ALL', NULL, 0, 'COMPLETED', 'ACTIVE', '"2026-10-01T19:00:06.222Z"', '', 'default', '9.0', 1);
INSERT INTO "wardrobe_items" ("id", "user_id", "category_id", "name", "image_url", "bg_removed_url", "primary_color", "sub_colors", "style_tags", "season", "purchase_price", "wear_count", "ai_processing_status", "status", "created_at", "brand", "wardrobe_id", "ai_match_score", "layer_order") VALUES ('3a70c7fa-10d8-45c3-8f61-854a382501c8', 'd140b5f9-8f4e-4b78-ae35-cbf40907184c', 1, 'Áo Thời Trang Thiết Kế', '/data/user/0/app.wearsy.mobile/cache/scaled_1000000068.jpg', NULL, 'Trắng', '[]', '["Smart Casual","Tối giản","Thanh lịch"]', 'ALL', NULL, 0, 'COMPLETED', 'ACTIVE', '"2026-10-01T19:00:06.592Z"', '', 'default', '9.0', 1);
INSERT INTO "wardrobe_items" ("id", "user_id", "category_id", "name", "image_url", "bg_removed_url", "primary_color", "sub_colors", "style_tags", "season", "purchase_price", "wear_count", "ai_processing_status", "status", "created_at", "brand", "wardrobe_id", "ai_match_score", "layer_order") VALUES ('42165f13-100f-48e7-aaf5-4ac2f5ca95a9', 'd140b5f9-8f4e-4b78-ae35-cbf40907184c', 1, 'Áo Thời Trang Thiết Kế', '/data/user/0/app.wearsy.mobile/cache/scaled_1000000068.jpg', NULL, 'Trắng', '[]', '["Smart Casual","Tối giản","Thanh lịch"]', 'ALL', NULL, 0, 'COMPLETED', 'ACTIVE', '"2026-10-01T19:00:06.620Z"', '', 'default', '9.0', 1);
INSERT INTO "wardrobe_items" ("id", "user_id", "category_id", "name", "image_url", "bg_removed_url", "primary_color", "sub_colors", "style_tags", "season", "purchase_price", "wear_count", "ai_processing_status", "status", "created_at", "brand", "wardrobe_id", "ai_match_score", "layer_order") VALUES ('a4bb3c21-3127-4ecc-aa3d-2a2096b60c0b', 'd140b5f9-8f4e-4b78-ae35-cbf40907184c', 1, 'Áo Thun Nam Cổ Tròn Màu Đen Basic', '/data/user/0/app.wearsy.mobile/cache/scaled_1000000067.jpg', NULL, 'Đen', '[]', '["Tối giản","Hàn Quốc","Năng động"]', 'ALL', NULL, 0, 'COMPLETED', 'ACTIVE', '"2026-10-01T19:00:06.624Z"', '', 'default', '9.0', 1);
INSERT INTO "wardrobe_items" ("id", "user_id", "category_id", "name", "image_url", "bg_removed_url", "primary_color", "sub_colors", "style_tags", "season", "purchase_price", "wear_count", "ai_processing_status", "status", "created_at", "brand", "wardrobe_id", "ai_match_score", "layer_order") VALUES ('35b48c12-65d1-4697-9c1c-cbf8a0c7fa7b', 'd140b5f9-8f4e-4b78-ae35-cbf40907184c', 1, 'Áo Thời Trang Thiết Kế', '/data/user/0/app.wearsy.mobile/cache/scaled_1000000040.jpg', NULL, 'Xám', '[]', '["Smart Casual","Tối giản","Thanh lịch"]', 'ALL', NULL, 0, 'COMPLETED', 'ACTIVE', '"2026-10-01T19:00:06.688Z"', '', 'default', '9.0', 1);
INSERT INTO "wardrobe_items" ("id", "user_id", "category_id", "name", "image_url", "bg_removed_url", "primary_color", "sub_colors", "style_tags", "season", "purchase_price", "wear_count", "ai_processing_status", "status", "created_at", "brand", "wardrobe_id", "ai_match_score", "layer_order") VALUES ('a9b4ab21-b837-4aaa-a44f-4ca4a2c632bd', 'd140b5f9-8f4e-4b78-ae35-cbf40907184c', 1, 'Áo Thun Nam Cổ Tròn Màu Đen Basic', '/data/user/0/app.wearsy.mobile/cache/scaled_1000000067.jpg', NULL, 'Đen', '[]', '["Tối giản","Hàn Quốc","Năng động"]', 'ALL', NULL, 0, 'COMPLETED', 'ACTIVE', '"2026-10-01T19:00:06.737Z"', '', 'default', '9.0', 1);
INSERT INTO "wardrobe_items" ("id", "user_id", "category_id", "name", "image_url", "bg_removed_url", "primary_color", "sub_colors", "style_tags", "season", "purchase_price", "wear_count", "ai_processing_status", "status", "created_at", "brand", "wardrobe_id", "ai_match_score", "layer_order") VALUES ('6394525e-c322-4469-90e2-c6338111f787', 'd9944be7-a90c-483d-8521-3ba0823e6b24', 1, 'Áo Thun Cotton Form Rộng In Hình', '/data/user/0/app.wearsy.mobile/cache/scaled_1000000081.jpg', NULL, 'Trắng', '[]', '["Streetwear","Năng động","Hàn Quốc"]', 'ALL', NULL, 0, 'COMPLETED', 'ACTIVE', '"2026-10-03T17:24:32.181Z"', 'Local Brand', 'default', '9.6', 1);
INSERT INTO "wardrobe_items" ("id", "user_id", "category_id", "name", "image_url", "bg_removed_url", "primary_color", "sub_colors", "style_tags", "season", "purchase_price", "wear_count", "ai_processing_status", "status", "created_at", "brand", "wardrobe_id", "ai_match_score", "layer_order") VALUES ('f1663275-e0ae-4903-8937-342f7a6581cf', 'd9944be7-a90c-483d-8521-3ba0823e6b24', 1, 'Áo Sweater Frozen Shark Nỉ Bông Cotton 100 Unisex Local Brand', 'https://down-vn.img.susercontent.com/file/vn-11134207-7ras8-m8310ffh8t8516', NULL, 'Xám', '[]', '["Cotton","Unisex","Sweater","Nỉ Bông","Local Brand"]', 'ALL', NULL, 0, 'COMPLETED', 'ACTIVE', '"2026-10-03T17:27:57.644Z"', 'Frozen Shark', 'default', '9.0', 1);

