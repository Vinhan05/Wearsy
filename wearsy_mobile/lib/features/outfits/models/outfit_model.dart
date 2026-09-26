enum OutfitOccasion {
  work,
  casual,
  formal,
  evening,
  sport,
}

extension OutfitOccasionExtension on OutfitOccasion {
  String get displayName {
    switch (this) {
      case OutfitOccasion.work:
        return 'Công sở';
      case OutfitOccasion.casual:
        return 'Đi chơi';
      case OutfitOccasion.formal:
        return 'Trang trọng';
      case OutfitOccasion.evening:
        return 'Buổi tối';
      case OutfitOccasion.sport:
        return 'Thể thao';
    }
  }

  String get icon {
    switch (this) {
      case OutfitOccasion.work:
        return '💼';
      case OutfitOccasion.casual:
        return '☀️';
      case OutfitOccasion.formal:
        return '🎩';
      case OutfitOccasion.evening:
        return '🌙';
      case OutfitOccasion.sport:
        return '🏃';
    }
  }
}

class OutfitModel {
  final String id;
  final String name;
  final OutfitOccasion occasion;
  final List<String> weatherSuitable;
  final double aiScore;
  final String aiReason;
  final List<String> itemIds;
  final String coverImageUrl;
  bool isFavorite;

  OutfitModel({
    required this.id,
    required this.name,
    required this.occasion,
    required this.weatherSuitable,
    required this.aiScore,
    required this.aiReason,
    required this.itemIds,
    required this.coverImageUrl,
    this.isFavorite = false,
  });

  factory OutfitModel.fromJson(Map<String, dynamic> json) {
    return OutfitModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      occasion: OutfitOccasion.values.firstWhere(
        (e) => e.name == json['occasion'],
        orElse: () => OutfitOccasion.casual,
      ),
      weatherSuitable: (json['weather_suitable'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      aiScore: (json['ai_score'] as num?)?.toDouble() ?? 9.0,
      aiReason: json['ai_reason']?.toString() ?? '',
      itemIds: (json['item_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      coverImageUrl: json['cover_image_url']?.toString() ?? '',
      isFavorite: json['is_favorite'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'occasion': occasion.name,
      'weather_suitable': weatherSuitable,
      'ai_score': aiScore,
      'ai_reason': aiReason,
      'item_ids': itemIds,
      'cover_image_url': coverImageUrl,
      'is_favorite': isFavorite,
    };
  }
}
