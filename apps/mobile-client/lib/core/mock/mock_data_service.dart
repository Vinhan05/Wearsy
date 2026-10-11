import '../../../features/auth/models/user_model.dart';
import '../../features/wardrobe/models/wardrobe_item_model.dart';
import '../../features/outfits/models/outfit_model.dart';

/// Mock data service — provides offline preview fallback data for WEARSY app.
class MockDataService {
  // ─── Auth ──────────────────────────────────────────────────────────────────

  static AuthSuccessData getMockAuthData({
    String fullName = 'Người Dùng WEARSY',
    String email = '',
  }) {
    return AuthSuccessData(
      token: 'mock_token_wearsy_2024',
      expiresIn: 86400,
      user: UserModel(
        id: 'mock_user_001',
        email: email,
        fullName: fullName,
        preferredStyles: ['Thanh lịch', 'Minimalism', 'Công sở'],
        colorPreferences: {
          'favorites': ['Trắng', 'Đen', 'Xanh Navy', 'Beige', 'Xám'],
          'avoid': ['Vàng', 'Đỏ'],
        },
        budgetRange: {'min': 300000, 'max': 2000000},
        bodyMeasurements: {
          'height': 172,
          'weight': 65,
          'chest': 92,
          'waist': 78,
          'hip': 94,
        },
      ),
    );
  }

  // ─── Wardrobe Items ────────────────────────────────────────────────────────

  static List<WardrobeItemModel> getMockWardrobeItems() {
    return [
      WardrobeItemModel(
        id: 'w001',
        name: 'Áo Sơ Mi Lụa Trắng',
        category: WardrobeCategory.tops,
        color: 'Trắng',
        brand: 'Zara',
        imageUrl:
            'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?q=80&w=600&auto=format&fit=crop',
        tags: ['Formal', 'Smart Casual', 'Công sở'],
        aiMatchScore: 9.2,
      ),
      WardrobeItemModel(
        id: 'w002',
        name: 'Quần Tây Slim Fit Đen',
        category: WardrobeCategory.bottoms,
        color: 'Đen',
        brand: 'H&M',
        imageUrl:
            'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?q=80&w=600&auto=format&fit=crop',
        tags: ['Formal', 'Versatile'],
        aiMatchScore: 9.5,
      ),
      WardrobeItemModel(
        id: 'w003',
        name: 'Áo Blazer Beige',
        category: WardrobeCategory.outerwear,
        color: 'Be',
        brand: 'Mango',
        imageUrl:
            'https://images.unsplash.com/photo-1507679799987-c73779587ccf?q=80&w=600&auto=format&fit=crop',
        tags: ['Smart Casual', 'Business'],
        aiMatchScore: 8.8,
      ),
      WardrobeItemModel(
        id: 'w004',
        name: 'Giày Oxford Da Nâu',
        category: WardrobeCategory.shoes,
        color: 'Nâu',
        brand: 'Clarks',
        imageUrl:
            'https://images.unsplash.com/photo-1614252235316-8c857d38b5f4?q=80&w=600&auto=format&fit=crop',
        tags: ['Formal', 'Classic'],
        aiMatchScore: 9.0,
      ),
      WardrobeItemModel(
        id: 'w005',
        name: 'T-Shirt Cotton Xám',
        category: WardrobeCategory.tops,
        color: 'Xám',
        brand: 'Uniqlo',
        imageUrl:
            'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?q=80&w=600&auto=format&fit=crop',
        tags: ['Casual', 'Minimalist', 'Daily'],
        aiMatchScore: 8.5,
      ),
      WardrobeItemModel(
        id: 'w006',
        name: 'Quần Jeans Navy Slim',
        category: WardrobeCategory.bottoms,
        color: 'Navy',
        brand: 'Levi\'s',
        imageUrl:
            'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?q=80&w=600&auto=format&fit=crop',
        tags: ['Casual', 'Weekend', 'Versatile'],
        aiMatchScore: 9.1,
      ),
      WardrobeItemModel(
        id: 'w007',
        name: 'Áo Polo Trắng',
        category: WardrobeCategory.tops,
        color: 'Trắng',
        brand: 'Lacoste',
        imageUrl:
            'https://images.unsplash.com/photo-1586790170083-2f9ceadc732d?q=80&w=600&auto=format&fit=crop',
        tags: ['Smart Casual', 'Sport'],
        aiMatchScore: 8.7,
      ),
      WardrobeItemModel(
        id: 'w008',
        name: 'Sneaker Trắng Clean',
        category: WardrobeCategory.shoes,
        color: 'Trắng',
        brand: 'Nike',
        imageUrl:
            'https://images.unsplash.com/photo-1542291026-7eec264c27ff?q=80&w=600&auto=format&fit=crop',
        tags: ['Casual', 'Street', 'Sport'],
        aiMatchScore: 9.3,
      ),
      WardrobeItemModel(
        id: 'w009',
        name: 'Đồng Hồ Dây Da',
        category: WardrobeCategory.accessories,
        color: 'Nâu/Vàng',
        brand: 'Fossil',
        imageUrl:
            'https://images.unsplash.com/photo-1523275335684-37898b6baf30?q=80&w=600&auto=format&fit=crop',
        tags: ['Classic', 'Formal', 'Elegant'],
        aiMatchScore: 9.4,
      ),
      WardrobeItemModel(
        id: 'w010',
        name: 'Áo Khoác Denim',
        category: WardrobeCategory.outerwear,
        color: 'Xanh denim',
        brand: 'Pull & Bear',
        imageUrl:
            'https://images.unsplash.com/photo-1551537482-f2075a1d41f2?q=80&w=600&auto=format&fit=crop',
        tags: ['Casual', 'Street', 'Weekend'],
        aiMatchScore: 8.6,
      ),
      WardrobeItemModel(
        id: 'w011',
        name: 'Quần Short Khaki Be Nam',
        category: WardrobeCategory.bottoms,
        color: 'Be',
        brand: 'Uniqlo',
        imageUrl:
            'https://images.unsplash.com/photo-1591195853828-11db59a44f6b?q=80&w=600&auto=format&fit=crop',
        tags: ['Casual', 'Summer', 'Dạo phố'],
        aiMatchScore: 8.9,
      ),
      WardrobeItemModel(
        id: 'w012',
        name: 'Balo Da Nam Minimalist',
        category: WardrobeCategory.accessories,
        color: 'Đen',
        brand: 'Bellroy',
        imageUrl:
            'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?q=80&w=600&auto=format&fit=crop',
        tags: ['Minimalist', 'Daily', 'Công sở'],
        aiMatchScore: 8.8,
      ),
      WardrobeItemModel(
        id: 'w013',
        name: 'Đầm Lụa Midi Dự Tiệc',
        category: WardrobeCategory.dresses,
        color: 'Đỏ Ruby',
        brand: 'Zara',
        imageUrl:
            'https://images.unsplash.com/photo-1595777457583-95e059d581b8?q=80&w=600&auto=format&fit=crop',
        tags: ['Dự tiệc', 'Quyến rũ', 'Sang trọng'],
        aiMatchScore: 9.6,
      ),
    ];
  }

  // ─── Outfit Suggestions ─────────────────────────────────────────────────────

  static List<OutfitModel> getMockOutfits() {
    return [
      OutfitModel(
        id: 'o001',
        name: 'Business Casual Lịch Lãm Nam',
        occasion: OutfitOccasion.work,
        weatherSuitable: ['Nắng nhẹ', 'Mát mẻ'],
        aiScore: 9.5,
        eleganceScore: 9.6,
        colorScore: 9.4,
        aiReason:
            'Áo sơ mi trắng kết hợp quần tây đen tạo phong cách công sở chỉn chu. Áo blazer màu be khoác ngoài mang đến vẻ lịch lãm và chuyên nghiệp.',
        itemIds: ['w001', 'w002', 'w003', 'w004'],
        coverImageUrl:
            'https://images.unsplash.com/photo-1594938298603-c8148c4b4671?q=80&w=600&auto=format&fit=crop',
        smartFitAdvice: const SmartFitAdvice(
          sizeRecommendation: 'Phù hợp nhất với Size L chuẩn (Áo sơ mi 40-41)',
          bodyProportionTip:
              'Với vóc dáng 1m72 / 65kg cân đối, nên sơ vin áo sơ mi trong quần tây và khoác hờ blazer vai đứng để tôn vóc dáng vai rộng, eo gọn.',
          fitWarnings: [
            'Quần tây slim fit phom vừa vặn, không nên mang kèm thắt lưng bản quá to.',
          ],
          bmi: 22.0,
          bodyFrame: 'Cân đối (Fit / Standard)',
          userHeight: 172,
          userWeight: 65,
        ),
      ),
      OutfitModel(
        id: 'o002',
        name: 'Weekend Casual Nam Năng Động',
        occasion: OutfitOccasion.casual,
        weatherSuitable: ['Nắng', 'Ấm áp'],
        aiScore: 9.1,
        eleganceScore: 9.0,
        colorScore: 9.3,
        aiReason:
            'T-shirt xám đơn giản tinh tế đi cùng quần jeans navy slim fit. Đôi sneaker trắng vừa tạo điểm nhấn vừa thoải mái vận động cả ngày.',
        itemIds: ['w005', 'w006', 'w008'],
        coverImageUrl:
            'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?q=80&w=600&auto=format&fit=crop',
        smartFitAdvice: const SmartFitAdvice(
          sizeRecommendation: 'Phù hợp nhất với Size L (T-shirt Regular Fit)',
          bodyProportionTip:
              'Ống quần jean nên xắn 1 gấu nhỏ trên mắt cá chân 1-2cm khi đi cùng sneakers cổ thấp để tạo cảm giác chân dài và năng động.',
          fitWarnings: [],
          bmi: 22.0,
          bodyFrame: 'Cân đối (Fit / Standard)',
          userHeight: 172,
          userWeight: 65,
        ),
      ),
      OutfitModel(
        id: 'o003',
        name: 'Smart Casual Thuyết Trình Nam',
        occasion: OutfitOccasion.formal,
        weatherSuitable: ['Mọi thời tiết'],
        aiScore: 9.3,
        eleganceScore: 9.4,
        colorScore: 9.2,
        aiReason:
            'Áo polo trắng lịch sự không quá cứng nhắc, phối cùng quần tây đen chỉn chu và điểm nhấn đồng hồ dây da nâu cuốn hút.',
        itemIds: ['w007', 'w002', 'w009'],
        coverImageUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=600&auto=format&fit=crop',
        smartFitAdvice: const SmartFitAdvice(
          sizeRecommendation: 'Phù hợp nhất với Size L (Polo Slim Fit)',
          bodyProportionTip:
              'Cài 2 trên 3 cúc áo polo, phối cùng đồng hồ dây da tương phản giúp thu hút ánh nhìn lên nửa thân trên khi đứng thuyết trình.',
          fitWarnings: [
            'Lưu ý chọn quần tây có độ co giãn nhẹ để thoải mái khi di chuyển trên bục thuyết trình.',
          ],
          bmi: 22.0,
          bodyFrame: 'Cân đối (Fit / Standard)',
          userHeight: 172,
          userWeight: 65,
        ),
      ),
      OutfitModel(
        id: 'o004',
        name: 'Street Style Denim Nam Cực Chất',
        occasion: OutfitOccasion.casual,
        weatherSuitable: ['Mát mẻ', 'Nhẹ lạnh'],
        aiScore: 8.8,
        eleganceScore: 8.9,
        colorScore: 9.0,
        aiReason:
            'Áo khoác denim nam layering cùng T-shirt xám và quần jeans navy. Combo phối màu xanh & xám nam tính chuẩn phong cách dạo phố.',
        itemIds: ['w010', 'w005', 'w006', 'w008'],
        coverImageUrl:
            'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=600&auto=format&fit=crop',
        smartFitAdvice: const SmartFitAdvice(
          sizeRecommendation: 'Áo trong Size L, Áo khoác Denim ngoài Size XL',
          bodyProportionTip:
              'Quy tắc Layering: Áo khoác denim form hơi boxy bên ngoài kết hợp áo phông xám bên trong tạo độ dày ngực và vai cực kỳ nam tính.',
          fitWarnings: [
            'Không cài cúc áo khoác ngoài để giữ nét tự nhiên và thoáng mắt cho tổng thể outfit.',
          ],
          bmi: 22.0,
          bodyFrame: 'Cân đối (Fit / Standard)',
          userHeight: 172,
          userWeight: 65,
        ),
      ),
      OutfitModel(
        id: 'o005',
        name: 'Summer Date Night Nam Thanh Lịch',
        occasion: OutfitOccasion.evening,
        weatherSuitable: ['Mùa hè', 'Nắng nóng'],
        aiScore: 9.6,
        eleganceScore: 9.5,
        colorScore: 9.6,
        aiReason:
            'Áo sơ mi trắng lụa nam xắn tay nhẹ kết hợp quần short khaki be thoáng mát. Giày sneaker trắng cùng balo da tạo diện mạo trẻ trung, cuốn hút.',
        itemIds: ['w001', 'w011', 'w008', 'w012'],
        coverImageUrl:
            'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?q=80&w=600&auto=format&fit=crop',
        smartFitAdvice: const SmartFitAdvice(
          sizeRecommendation: 'Áo sơ mi Size L, Quần short Size 31-32',
          bodyProportionTip:
              'Quần short khaki be nên có độ dài trên đầu gối khoảng 3-5cm để đôi chân trông dài và thanh thoát nhất trong các buổi hẹn tối.',
          fitWarnings: [],
          bmi: 22.0,
          bodyFrame: 'Cân đối (Fit / Standard)',
          userHeight: 172,
          userWeight: 65,
        ),
      ),
    ];
  }

  // ─── Weather Mock ───────────────────────────────────────────────────────────

  static Map<String, dynamic> getMockWeather() {
    return {
      'temperature': 28,
      'condition': 'Nắng nhẹ',
      'icon': '☀️',
      'humidity': 65,
      'suggestion': 'Thời tiết đẹp, phù hợp mặc trang phục thoáng mát.',
    };
  }
}
