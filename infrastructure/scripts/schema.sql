-- ============================================================
-- WEARSY MOBILE APP - DATABASE SCHEMA & SEED DATA
-- Target DB: PostgreSQL 13+
-- Author: Phụ trách Kỹ thuật & An toàn thông tin Võ Thế Dân
-- ============================================================

-- Bật Extension tạo UUID tự động
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Function tự động cập nhật timestamp updated_at
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------------------
-- 1. BẢNG users (Xác thực & Tài khoản)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'USER',
    is_vip BOOLEAN NOT NULL DEFAULT false,
    vip_expires_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users(email);

CREATE TRIGGER set_timestamp_users
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

-- ------------------------------------------------------------
-- 2. BẢNG user_profiles (Hồ sơ phong cách & Data Học Máy AI)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    preferred_styles JSONB NOT NULL DEFAULT '[]'::jsonb,
    color_preferences JSONB NOT NULL DEFAULT '{}'::jsonb,
    budget_range JSONB NOT NULL DEFAULT '{"tier": "medium"}'::jsonb,
    body_measurements JSONB DEFAULT '{}'::jsonb,
    ai_learning_data JSONB DEFAULT '{}'::jsonb,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);

CREATE TRIGGER set_timestamp_user_profiles
BEFORE UPDATE ON user_profiles
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

-- ------------------------------------------------------------
-- 3. BẢNG categories (Cấu trúc phân loại trang phục đa cấp)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categories (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    parent_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_categories_parent_id ON categories(parent_id);

-- Seed Data danh mục trang phục chuẩn cho WEARSY
INSERT INTO categories (parent_id, name, code, description) VALUES
(NULL, 'Áo (Tops)', 'TOPS', 'Các loại áo mặc phía trên'),
(NULL, 'Quần & Váy (Bottoms)', 'BOTTOMS', 'Các loại quần, chân váy mặc phía dưới'),
(NULL, 'Giày Dép (Footwear)', 'FOOTWEAR', 'Các loại giày, dép, ủng'),
(NULL, 'Áo Khoác (Outerwear)', 'OUTERWEAR', 'Các loại áo khoác ngoài'),
(NULL, 'Phụ Kiện (Accessories)', 'ACCESSORIES', 'Túi xách, thắt lưng, nón, trang sức')
ON CONFLICT (code) DO NOTHING;

-- ------------------------------------------------------------
-- 4. BẢNG wardrobe_items (Digital Wardrobe - Kho đồ cá nhân)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS wardrobe_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    name VARCHAR(150) NOT NULL,
    image_url VARCHAR(512) NOT NULL,
    bg_removed_url VARCHAR(512),
    primary_color VARCHAR(50) NOT NULL,
    sub_colors JSONB DEFAULT '[]'::jsonb,
    style_tags JSONB DEFAULT '[]'::jsonb,
    season VARCHAR(30) DEFAULT 'ALL',
    purchase_price NUMERIC(12, 2),
    wear_count INTEGER NOT NULL DEFAULT 0,
    ai_processing_status VARCHAR(20) NOT NULL DEFAULT 'COMPLETED',
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_wardrobe_items_user_status ON wardrobe_items(user_id, status);
CREATE INDEX IF NOT EXISTS idx_wardrobe_items_category_id ON wardrobe_items(category_id);

-- ------------------------------------------------------------
-- 5. BẢNG outfits (Bộ trang phục AI / Người dùng tạo)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS outfits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    occasion VARCHAR(100),
    ai_generated BOOLEAN NOT NULL DEFAULT true,
    elegance_score NUMERIC(3, 1),
    ai_reasoning TEXT,
    is_favorite BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_outfits_user_ai ON outfits(user_id, ai_generated);
CREATE INDEX IF NOT EXISTS idx_outfits_user_favorite ON outfits(user_id, is_favorite);

-- ------------------------------------------------------------
-- 6. BẢNG outfit_items (Junction Table: Chi tiết Layering Outfit)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS outfit_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    outfit_id UUID NOT NULL REFERENCES outfits(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES wardrobe_items(id) ON DELETE CASCADE,
    layer_order INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_outfit_item UNIQUE (outfit_id, item_id)
);

CREATE INDEX IF NOT EXISTS idx_outfit_items_outfit_id ON outfit_items(outfit_id);
CREATE INDEX IF NOT EXISTS idx_outfit_items_item_id ON outfit_items(item_id);

-- ------------------------------------------------------------
-- 7. BẢNG shopping_check_logs (Nhật ký Smart Shopping Check)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS shopping_check_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_item_name VARCHAR(150) NOT NULL,
    target_item_price NUMERIC(12, 2) NOT NULL,
    target_image_url VARCHAR(512),
    compatible_item_count INTEGER NOT NULL DEFAULT 0,
    compatibility_score VARCHAR(20) NOT NULL,
    recommendation_status VARCHAR(30) NOT NULL,
    analysis_details JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_shopping_logs_user_date ON shopping_check_logs(user_id, created_at);
