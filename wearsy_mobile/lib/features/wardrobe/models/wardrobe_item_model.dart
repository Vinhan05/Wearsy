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

  const WardrobeItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    required this.brand,
    required this.imageUrl,
    required this.tags,
    required this.aiMatchScore,
  });

  factory WardrobeItemModel.fromJson(Map<String, dynamic> json) {
    return WardrobeItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: WardrobeCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => WardrobeCategory.tops,
      ),
      color: json['color']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      aiMatchScore: (json['ai_match_score'] as num?)?.toDouble() ?? 0.0,
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
  }) {
    return WardrobeItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      color: color ?? this.color,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      aiMatchScore: aiMatchScore ?? this.aiMatchScore,
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
    };
  }
}

