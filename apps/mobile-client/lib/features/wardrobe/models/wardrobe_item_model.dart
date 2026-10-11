enum WardrobeCategory {
  tops,
  bottoms,
  dresses,
  outerwear,
  shoes,
  accessories,
}

extension WardrobeCategoryExtension on WardrobeCategory {
  String get displayName {
    switch (this) {
      case WardrobeCategory.tops:
        return 'Áo';
      case WardrobeCategory.bottoms:
        return 'Quần';
      case WardrobeCategory.dresses:
        return 'Đầm/Váy';
      case WardrobeCategory.outerwear:
        return 'Áo khoác';
      case WardrobeCategory.shoes:
        return 'Giày';
      case WardrobeCategory.accessories:
        return 'Phụ kiện';
    }
  }

  String get icon {
    switch (this) {
      case WardrobeCategory.tops:
        return '👕';
      case WardrobeCategory.bottoms:
        return '👖';
      case WardrobeCategory.dresses:
        return '👗';
      case WardrobeCategory.outerwear:
        return '🧥';
      case WardrobeCategory.shoes:
        return '👟';
      case WardrobeCategory.accessories:
        return '👜';
    }
  }

  /// Thứ tự xếp lớp hiển thị trên 2D Layering Canvas
  /// Layer 1: Lớp nền (Áo thun, sơ mi, quần, chân váy, đầm)
  /// Layer 2: Lớp ngoài (Áo khoác, Blazer, Cardigan, Trench coat)
  /// Layer 3: Giày/Dép
  /// Layer 4: Phụ kiện (Mũ, túi xách, thắt lưng, kính)
  int get defaultLayerOrder {
    switch (this) {
      case WardrobeCategory.tops:
      case WardrobeCategory.bottoms:
      case WardrobeCategory.dresses:
        return 1;
      case WardrobeCategory.outerwear:
        return 2;
      case WardrobeCategory.shoes:
        return 3;
      case WardrobeCategory.accessories:
        return 4;
    }
  }
}

class WardrobeItemModel {
  final String id;
  final String name;
  final WardrobeCategory category;
  final String color;
  final String brand;
  final String imageUrl;
  final List<String> tags;
  final double aiMatchScore;
  final int layerOrder;
  final String wardrobeId;

  static String sanitizeImageUrl(String url, {String name = '', WardrobeCategory? category}) {
    final clean = url.trim();
    if (clean.isEmpty) {
      return _getCategoryPngFallback(name, category);
    }

    // 1. If already explicit transparent PNG or background-removed asset on trusted CDN, keep it
    if (clean.contains('pngimg.com') ||
        clean.contains('e_background_removal') ||
        (clean.contains('cloudinary') && clean.endsWith('.png'))) {
      return clean;
    }

    // 2. Known sample Unsplash / Shopee URLs mapped to Cloudinary transparent background-removed asset
    if (clean.contains('photo-1541099649105-f69ad21f3246') ||
        clean.contains('photo-1618354691373') ||
        clean.contains('photo-1595777457583') ||
        clean.contains('photo-1544441893') ||
        clean.contains('photo-1595950653106') ||
        clean.contains('photo-1584917865442') ||
        clean.contains('mtjanmyn2adj03') ||
        clean.contains('m8310ffh8t8516') ||
        clean.contains('lxk0s90z8x0665') ||
        clean.contains('vn-11134207') ||
        clean.contains('sg-11134201')) {
      return 'https://res.cloudinary.com/bvxcghig/image/upload/e_background_removal/v1/wearsy/wardrobe_items/yek4pytbpifbaihhg4ql.png';
    }

    // 3. For Cloudinary upload URLs without transformation, inject e_background_removal/f_png to isolate the user's actual clothing photo
    if (clean.contains('cloudinary.com') && clean.contains('/upload/')) {
      return clean.replaceFirst('/upload/', '/upload/e_background_removal/f_png/');
    }

    // 4. Preserve the user's actual image (local file path or custom photo URL)
    return clean;
  }

  static String _getCategoryPngFallback(String name, WardrobeCategory? category) {
    final lower = name.toLowerCase();

    // Quần (Jeans / Shorts / Trousers / Bottoms)
    if (lower.contains('jean') ||
        lower.contains('quần') ||
        lower.contains('pant') ||
        lower.contains('short') ||
        lower.contains('trouser') ||
        category == WardrobeCategory.bottoms) {
      return 'https://pngimg.com/uploads/jeans/jeans_PNG5775.png';
    }

    // Áo thun (T-shirt / Polo / Tanktop)
    if (lower.contains('thun') ||
        lower.contains('t-shirt') ||
        lower.contains('tshirt') ||
        lower.contains('polo') ||
        lower.contains('ba lỗ') ||
        lower.contains('3 lỗ')) {
      return 'https://pngimg.com/uploads/tshirt/tshirt_PNG5448.png';
    }

    // Áo sơ mi / Tops
    if (lower.contains('sơ mi') ||
        lower.contains('shirt') ||
        category == WardrobeCategory.tops) {
      return 'https://pngimg.com/uploads/dress_shirt/dress_shirt_PNG8117.png';
    }

    // Áo khoác (Blazer / Jacket / Coat / Hoodie / Outerwear)
    if (lower.contains('khoác') ||
        lower.contains('blazer') ||
        lower.contains('jacket') ||
        lower.contains('hoodie') ||
        lower.contains('sweater') ||
        lower.contains('măng tô') ||
        category == WardrobeCategory.outerwear) {
      return 'https://pngimg.com/uploads/jacket/jacket_PNG8056.png';
    }

    // Giày / Sneakers / Shoes
    if (lower.contains('giày') ||
        lower.contains('sneaker') ||
        lower.contains('shoes') ||
        lower.contains('dép') ||
        lower.contains('oxford') ||
        lower.contains('boot') ||
        category == WardrobeCategory.shoes) {
      return 'https://pngimg.com/uploads/running_shoes/running_shoes_PNG5816.png';
    }

    // Váy / Đầm / Skirts / Dresses
    if (lower.contains('váy') ||
        lower.contains('đầm') ||
        lower.contains('skirt') ||
        lower.contains('dress') ||
        category == WardrobeCategory.dresses) {
      return 'https://pngimg.com/uploads/skirt/skirt_PNG48.png';
    }

    // Phụ kiện / Túi / Bag / Accessories
    if (lower.contains('túi') ||
        lower.contains('bag') ||
        lower.contains('mũ') ||
        lower.contains('nón') ||
        lower.contains('kính') ||
        lower.contains('đồng hồ') ||
        lower.contains('thắt lưng') ||
        category == WardrobeCategory.accessories) {
      return 'https://pngimg.com/uploads/bag/bag_PNG6413.png';
    }

    // Mặc định cho các loại đồ chưa phân loại: Áo thun trắng sạch nền
    return 'https://pngimg.com/uploads/tshirt/tshirt_PNG5448.png';
  }

  WardrobeItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    required this.brand,
    required String imageUrl,
    this.tags = const [],
    this.aiMatchScore = 9.0,
    int? layerOrder,
    this.wardrobeId = 'default',
  })  : imageUrl = sanitizeImageUrl(imageUrl, name: name, category: category),
        layerOrder = layerOrder ?? category.defaultLayerOrder;

  factory WardrobeItemModel.fromJson(Map<String, dynamic> json) {
    final cat = WardrobeCategory.values.firstWhere(
      (e) => e.name == json['category'],
      orElse: () => WardrobeCategory.tops,
    );
    final rawOrder = json['layer_order'] ?? json['layerOrder'];
    final parsedOrder = (rawOrder as num?)?.toInt() ?? cat.defaultLayerOrder;
    final wId = json['wardrobe_id']?.toString() ??
        json['wardrobeId']?.toString() ??
        'default';

    final rawImg = json['image_url']?.toString() ?? '';
    final name = json['name']?.toString() ?? '';

    return WardrobeItemModel(
      id: json['id']?.toString() ?? '',
      name: name,
      category: cat,
      color: json['color']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      imageUrl: sanitizeImageUrl(rawImg, name: name, category: cat),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              [],
      aiMatchScore: (json['ai_match_score'] as num?)?.toDouble() ?? 9.0,
      layerOrder: parsedOrder,
      wardrobeId: wId,
    );
  }

  WardrobeItemModel copyWith({
    String? id,
    String? name,
    WardrobeCategory? category,
    String? color,
    String? brand,
    String? imageUrl,
    List<String>? tags,
    double? aiMatchScore,
    int? layerOrder,
    String? wardrobeId,
  }) {
    final effectiveCategory = category ?? this.category;
    return WardrobeItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: effectiveCategory,
      color: color ?? this.color,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      aiMatchScore: aiMatchScore ?? this.aiMatchScore,
      layerOrder: layerOrder ?? this.layerOrder,
      wardrobeId: wardrobeId ?? this.wardrobeId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'color': color,
      'brand': brand,
      'image_url': imageUrl,
      'tags': tags,
      'ai_match_score': aiMatchScore,
      'layer_order': layerOrder,
      'wardrobe_id': wardrobeId,
    };
  }
}
