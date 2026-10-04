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

  static String sanitizeImageUrl(String url) {
    if (url.trim().isEmpty) return url;

    // Ảnh mẫu polo nam hoặc các mẫu Shopee polo chưa tách nền
    if (url.contains('mtjanmyn2adj03') ||
        url.contains('m8310ffh8t8516') ||
        url.contains('lxk0s90z8x0665') ||
        url.contains('vn-11134207-7ras8-m0vmtrp190x9f2') ||
        url.contains('sg-11134201-824g8-mptkw6sgly4r4c')) {
      return 'https://res.cloudinary.com/bvxcghig/image/upload/e_background_removal/v1/wearsy/wardrobe_items/yek4pytbpifbaihhg4ql.png';
    }

    // Nếu là URL Cloudinary nhưng chưa có e_background_removal
    if (url.contains('res.cloudinary.com') &&
        url.contains('/image/upload/') &&
        !url.contains('e_background_removal')) {
      return url.replaceFirst(
          '/image/upload/', '/image/upload/e_background_removal/');
    }

    // Nếu là URL web bên ngoài (Shopee, Unsplash...) chưa được tách nền
    if (url.startsWith('http') &&
        !url.contains('e_background_removal') &&
        !url.contains('cloudinary.com/bvxcghig/image/fetch/')) {
      return 'https://res.cloudinary.com/bvxcghig/image/fetch/f_png,e_background_removal/$url';
    }

    return url;
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
  })  : imageUrl = sanitizeImageUrl(imageUrl),
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

    return WardrobeItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: cat,
      color: json['color']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      imageUrl: sanitizeImageUrl(rawImg),
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
