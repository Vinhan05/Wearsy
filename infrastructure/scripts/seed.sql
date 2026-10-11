-- ==========================================================
-- WEARSY INITIAL SEED DATA SCRIPT
-- ==========================================================

-- 1. SEED CATEGORIES (Danh mục thời trang cơ bản & phân cấp)
INSERT INTO categories (parent_id, name, code, description) VALUES
(NULL, 'Áo (Tops)', 'TOPS', 'Tất cả các loại áo mặc thân trên'),
(NULL, 'Quần & Chân váy (Bottoms)', 'BOTTOMS', 'Các loại quần, váy mặc thân dưới'),
(NULL, 'Đầm / Váy liền (Dresses)', 'DRESSES', 'Đầm liền thân, váy dài/ngắn'),
(NULL, 'Áo khoác (Outerwear)', 'OUTERWEAR', 'Áo khoác gió, blazer, cardigan, hoodie'),
(NULL, 'Giày dép (Footwear)', 'FOOTWEAR', 'Giày sneakers, boots, cao gót, sandals'),
(NULL, 'Phụ kiện (Accessories)', 'ACCESSORIES', 'Túi xách, thắt lưng, mũ, trang sức')
ON CONFLICT (code) DO NOTHING;

-- Sub-categories for TOPS
INSERT INTO categories (parent_id, name, code, description) VALUES
((SELECT id FROM categories WHERE code = 'TOPS'), 'Áo thun (T-Shirt)', 'TOP_TSHIRT', 'Áo thun cộc tay, dài tay'),
((SELECT id FROM categories WHERE code = 'TOPS'), 'Áo sơ mi (Shirt)', 'TOP_SHIRT', 'Áo sơ mi công sở, casual'),
((SELECT id FROM categories WHERE code = 'TOPS'), 'Áo polo (Polo Shirt)', 'TOP_POLO', 'Áo polo có cổ')
ON CONFLICT (code) DO NOTHING;

-- Sub-categories for BOTTOMS
INSERT INTO categories (parent_id, name, code, description) VALUES
((SELECT id FROM categories WHERE code = 'BOTTOMS'), 'Quần Jeans', 'BOT_JEANS', 'Quần bò, jeans ống suông, skinny'),
((SELECT id FROM categories WHERE code = 'BOTTOMS'), 'Quần Tây / Khaki', 'BOT_TROUSERS', 'Quần âu, quần vải, chinos'),
((SELECT id FROM categories WHERE code = 'BOTTOMS'), 'Chân váy (Skirts)', 'BOT_SKIRT', 'Chân váy chữ A, midi, tennis')
ON CONFLICT (code) DO NOTHING;
