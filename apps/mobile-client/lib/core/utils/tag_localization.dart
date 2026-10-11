import '../../features/wardrobe/models/wardrobe_item_model.dart';

class TagLocalization {
  /// Chuyển đổi nhãn phong cách / thẻ gợi ý sang 100% Tiếng Việt hoặc 100% Tiếng Anh
  static String getLocalizedTag(String tag, bool isEn) {
    final clean = tag.trim();
    if (clean.isEmpty) return tag;

    if (isEn) {
      switch (clean.toLowerCase()) {
        case 'smart casual':
        case 'thanh lịch năng động':
          return 'Smart Casual';
        case 'công sở':
        case 'office':
        case 'workwear':
          return 'Office';
        case 'streetwear':
        case 'đường phố':
        case 'phong cách đường phố':
          return 'Streetwear';
        case 'tối giản':
        case 'minimalist':
        case 'minimalism':
          return 'Minimalist';
        case 'năng động':
        case 'active':
        case 'sporty':
          return 'Active';
        case 'thể thao':
        case 'sport':
        case 'sports':
          return 'Sport';
        case 'dự tiệc':
        case 'party':
          return 'Party';
        case 'vintage':
        case 'cổ điển':
          return 'Vintage';
        case 'thanh lịch':
        case 'elegant':
          return 'Elegant';
        case 'hàn quốc':
        case 'korean':
          return 'Korean';
        case 'cá tính':
        case 'edgy':
          return 'Edgy';
        case 'dạo phố':
        case 'casual':
          return 'Casual';
        case 'đi học':
        case 'school':
          return 'School';
        default:
          return tag;
      }
    } else {
      switch (clean.toLowerCase()) {
        case 'smart casual':
        case 'thanh lịch năng động':
          return 'Thanh lịch năng động';
        case 'công sở':
        case 'office':
        case 'workwear':
          return 'Công sở';
        case 'streetwear':
        case 'đường phố':
        case 'phong cách đường phố':
          return 'Đường phố';
        case 'tối giản':
        case 'minimalist':
        case 'minimalism':
          return 'Tối giản';
        case 'năng động':
        case 'active':
        case 'sporty':
          return 'Năng động';
        case 'thể thao':
        case 'sport':
        case 'sports':
          return 'Thể thao';
        case 'dự tiệc':
        case 'party':
          return 'Dự tiệc';
        case 'vintage':
        case 'cổ điển':
          return 'Cổ điển';
        case 'thanh lịch':
        case 'elegant':
          return 'Thanh lịch';
        case 'hàn quốc':
        case 'korean':
          return 'Hàn Quốc';
        case 'cá tính':
        case 'edgy':
          return 'Cá tính';
        case 'dạo phố':
        case 'casual':
          return 'Dạo phố';
        case 'đi học':
        case 'school':
          return 'Đi học';
        default:
          return tag;
      }
    }
  }

  /// Trả về danh sách thẻ phổ biến chuẩn 100% theo ngôn ngữ được chọn
  static List<String> getPopularTags(bool isEn) {
    if (isEn) {
      return [
        'Smart Casual',
        'Office',
        'Streetwear',
        'Minimalist',
        'Active',
        'Party',
        'Vintage',
      ];
    } else {
      return [
        'Thanh lịch năng động',
        'Công sở',
        'Đường phố',
        'Tối giản',
        'Năng động',
        'Dự tiệc',
        'Cổ điển',
      ];
    }
  }

  /// Dịch màu sắc chuẩn 100%
  static String getColorName(String color, bool isEn) {
    if (!isEn) return color;
    switch (color.trim().toLowerCase()) {
      case 'trắng': return 'White';
      case 'trắng trơn': return 'Solid White';
      case 'trắng da': return 'White Leather';
      case 'trắng ngà': return 'Off-White';
      case 'đen': return 'Black';
      case 'đen da': return 'Black Leather';
      case 'đen xám': return 'Charcoal Grey';
      case 'xanh navy': return 'Navy Blue';
      case 'xám': return 'Grey';
      case 'nâu': return 'Brown';
      case 'đỏ': return 'Red';
      case 'xanh lá': return 'Green';
      case 'vàng': return 'Yellow';
      case 'be': return 'Beige';
      case 'be sữa': return 'Milk Beige';
      case 'pastel': return 'Pastel';
      default: return color;
    }
  }

  /// Dịch danh mục chuẩn 100%
  static String getCategoryName(WardrobeCategory cat, bool isEn) {
    if (!isEn) return cat.displayName;
    switch (cat) {
      case WardrobeCategory.tops: return 'Tops';
      case WardrobeCategory.bottoms: return 'Bottoms';
      case WardrobeCategory.dresses: return 'Dresses';
      case WardrobeCategory.outerwear: return 'Outerwear';
      case WardrobeCategory.shoes: return 'Shoes';
      case WardrobeCategory.accessories: return 'Accessories';
    }
  }

  /// Dịch tên tủ đồ chuẩn 100%
  static String getLocalizedWardrobeName(String name, bool isEn) {
    final clean = name.trim();
    if (clean == 'Tủ Đồ Hàng Ngày' || clean == 'Daily Wardrobe') {
      return isEn ? 'Daily Wardrobe' : 'Tủ Đồ Hàng Ngày';
    }
    if (clean == 'Tủ Đồ Công Sở' || clean == 'Office Wardrobe') {
      return isEn ? 'Office Wardrobe' : 'Tủ Đồ Công Sở';
    }
    if (clean == 'Tủ Đồ Dự Tiệc' || clean == 'Party Wardrobe') {
      return isEn ? 'Party Wardrobe' : 'Tủ Đồ Dự Tiệc';
    }
    if (clean == 'Tủ Đồ Thể Thao' || clean == 'Sport Wardrobe') {
      return isEn ? 'Sport Wardrobe' : 'Tủ Đồ Thể Thao';
    }
    return name;
  }

  /// Dịch tên thành phố chuẩn 100%
  static String getLocalizedCityName(String city, bool isEn) {
    if (!isEn) return city;
    final lower = city.trim().toLowerCase();
    if (lower.contains('hồ chí minh') || lower.contains('ho chi minh') || lower.contains('tp. hcm')) {
      return 'Ho Chi Minh City';
    }
    if (lower.contains('hà nội') || lower.contains('ha noi')) {
      return 'Hanoi';
    }
    if (lower.contains('đà lạt') || lower.contains('da lat')) {
      return 'Da Lat';
    }
    if (lower.contains('đà nẵng') || lower.contains('da nang')) {
      return 'Da Nang';
    }
    if (lower.contains('nha trang')) {
      return 'Nha Trang';
    }
    if (lower.contains('sa pa') || lower.contains('sapa')) {
      return 'Sapa';
    }
    if (lower.contains('cần thơ') || lower.contains('can tho')) {
      return 'Can Tho';
    }
    return city;
  }

  /// Dịch tên món đồ (AI nhận diện hoặc tên mẫu) sang Tiếng Anh / Tiếng Việt
  static String getLocalizedName(String name, bool isEn) {
    if (!isEn) return name;
    final lower = name.trim().toLowerCase();
    if (lower.contains('quần jean ống suông màu đen') || lower.contains('quần jean ống suông') || lower.contains('quần jean ống suông nam')) {
      return 'Black Straight-Leg Jeans';
    }
    if (lower.contains('áo overshirt')) {
      return 'Overshirt Jacket';
    }
    if (lower.contains('áo thun trắng')) {
      return 'White T-Shirt';
    }
    if (lower.contains('quần chino navy')) {
      return 'Navy Chino Pants';
    }
    if (lower.contains('sneaker trắng')) {
      return 'White Sneakers';
    }
    if (lower.contains('túi đeo chéo')) {
      return 'Crossbody Bag';
    }
    if (lower.contains('áo polo trơn tối giản')) {
      return 'Minimalist Plain Polo Shirt';
    }
    if (lower.contains('quần tây xếp ly relaxed')) {
      return 'Relaxed Pleated Trousers';
    }
    if (lower.contains('áo khoác dù nam có mũ') || lower.contains('áo khoác dù có mũ')) {
      return 'Men\'s Hooded Windbreaker Jacket';
    }
    if (lower.contains('áo polo dệt kim be')) {
      return 'Beige Knit Polo Shirt';
    }
    if (lower.contains('quần short denim')) {
      return 'Denim Shorts';
    }
    if (lower.contains('giày thể thao trắng')) {
      return 'White Sneakers';
    }
    if (lower.contains('áo sơ mi trắng')) {
      return 'White Shirt';
    }
    if (lower.contains('áo thun unisex đen')) {
      return 'Black Unisex T-Shirt';
    }
    if (lower.contains('quần jean ống rộng màu đen') || lower.contains('quần jean ống rộng')) {
      return 'Black Wide-Leg Jeans';
    }
    if (lower.contains('quần tây âu dáng suông')) {
      return 'Straight-Leg Trousers';
    }
    if (lower.contains('áo khoác dù')) {
      return 'Windbreaker Jacket';
    }
    if (lower.contains('áo khoác')) {
      return 'Outerwear Jacket';
    }
    return name;
  }

  /// Dịch đoạn mô tả AI phân tích sang Tiếng Anh / Tiếng Việt
  static String getLocalizedAiReason(String reason, bool isEn) {
    if (!isEn || reason.isEmpty) return reason;
    if (reason.contains('ống suông') || reason.contains('Quần jean') || reason.contains('trẻ trung')) {
      return 'Comfortable men\'s black straight-leg jeans, versatile for easy matching with a youthful, dynamic style.';
    }
    if (reason.contains('chống gió') || reason.contains('Áo khoác dù') || reason.contains('mũ trùm')) {
      return 'Windproof hooded jacket featuring convenient hood design and modern utility pockets, perfect for active & streetwear styles.';
    }
    if (reason.contains('dệt kim') || reason.contains('tông be')) {
      return 'Elegant beige knitwear material, optimized for styling with trousers or jeans.';
    }
    if (reason.contains('denim') || reason.contains('quần short')) {
      return 'Youthful denim shorts, versatile and easy to coordinate with t-shirts and hoodies.';
    }
    if (reason.contains('thể thao') || reason.contains('giày')) {
      return 'Dynamic white sneakers suitable for everyday activities and active outfits.';
    }
    if (reason.contains('cạp cao') || reason.contains('tôn dáng')) {
      return 'High-waisted black wide-leg jeans, streetwear style that enhances fit and easy matching.';
    }
    if (reason.contains('Gọn gàng, hiện đại') || reason.contains('phù hợp cho nhiều hoàn cảnh')) {
      return 'Neat, modern, and suitable for various occasions during the day.';
    }
    return reason;
  }
}
