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

class SmartFitAdvice {
  final String sizeRecommendation;
  final String bodyProportionTip;
  final List<String> fitWarnings;
  final double? bmi;
  final String? bodyFrame;
  final double? userHeight;
  final double? userWeight;

  const SmartFitAdvice({
    required this.sizeRecommendation,
    required this.bodyProportionTip,
    required this.fitWarnings,
    this.bmi,
    this.bodyFrame,
    this.userHeight,
    this.userWeight,
  });

  factory SmartFitAdvice.fromJson(Map<String, dynamic> json) {
    return SmartFitAdvice(
      sizeRecommendation: json['size_recommendation']?.toString() ??
          'Phù hợp với Size tiêu chuẩn',
      bodyProportionTip: json['body_proportion_tip']?.toString() ??
          'Sơ vin áo gọn gàng trong quần để tỷ lệ thân trên và thân dưới hài hòa hơn.',
      fitWarnings: (json['fit_warnings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      bmi: (json['bmi'] as num?)?.toDouble(),
      bodyFrame: json['body_frame']?.toString(),
      userHeight: (json['user_height'] as num?)?.toDouble(),
      userWeight: (json['user_weight'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'size_recommendation': sizeRecommendation,
      'body_proportion_tip': bodyProportionTip,
      'fit_warnings': fitWarnings,
      if (bmi != null) 'bmi': bmi,
      if (bodyFrame != null) 'body_frame': bodyFrame,
      if (userHeight != null) 'user_height': userHeight,
      if (userWeight != null) 'user_weight': userWeight,
    };
  }
}

class OutfitModel {
  final String id;
  final String name;
  final OutfitOccasion occasion;
  final List<String> weatherSuitable;
  final double aiScore;
  final double eleganceScore;
  final double colorScore;
  final String aiReason;
  final List<String> itemIds;
  final String coverImageUrl;
  final SmartFitAdvice? smartFitAdvice;
  bool isFavorite;

  OutfitModel({
    required this.id,
    required this.name,
    required this.occasion,
    required this.weatherSuitable,
    required this.aiScore,
    double? eleganceScore,
    double? colorScore,
    required this.aiReason,
    required this.itemIds,
    required this.coverImageUrl,
    this.smartFitAdvice,
    this.isFavorite = false,
  })  : eleganceScore = eleganceScore ?? aiScore,
        colorScore = colorScore ?? ((aiScore * 0.95).clamp(8.0, 9.8));

  factory OutfitModel.fromJson(Map<String, dynamic> json) {
    final rawAiScore = (json['ai_score'] as num?)?.toDouble() ?? 9.0;
    final elegance = (json['elegance_score'] as num?)?.toDouble() ?? rawAiScore;
    final color =
        (json['color_score'] as num?)?.toDouble() ?? (rawAiScore * 0.95);

    SmartFitAdvice? advice;
    if (json['smart_fit_advice'] is Map<String, dynamic>) {
      advice = SmartFitAdvice.fromJson(
          json['smart_fit_advice'] as Map<String, dynamic>);
    }

    return OutfitModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      occasion: OutfitOccasion.values.firstWhere(
        (e) => e.name == json['occasion'],
        orElse: () => OutfitOccasion.casual,
      ),
      weatherSuitable: (json['weather_suitable'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Mọi thời tiết'],
      aiScore: rawAiScore,
      eleganceScore: double.parse(elegance.toStringAsFixed(1)),
      colorScore: double.parse(color.toStringAsFixed(1)),
      aiReason: json['ai_reason']?.toString() ??
          json['stylist_reasoning']?.toString() ??
          '',
      itemIds: (json['item_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (json['selected_item_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      coverImageUrl: json['cover_image_url']?.toString() ??
          json['image_url']?.toString() ??
          json['image_base64']?.toString() ??
          '',
      smartFitAdvice: advice,
      isFavorite: json['is_favorite'] == true,
    );
  }

  OutfitModel copyWith({
    String? id,
    String? name,
    OutfitOccasion? occasion,
    List<String>? weatherSuitable,
    double? aiScore,
    double? eleganceScore,
    double? colorScore,
    String? aiReason,
    List<String>? itemIds,
    String? coverImageUrl,
    SmartFitAdvice? smartFitAdvice,
    bool? isFavorite,
  }) {
    return OutfitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      occasion: occasion ?? this.occasion,
      weatherSuitable: weatherSuitable ?? this.weatherSuitable,
      aiScore: aiScore ?? this.aiScore,
      eleganceScore: eleganceScore ?? this.eleganceScore,
      colorScore: colorScore ?? this.colorScore,
      aiReason: aiReason ?? this.aiReason,
      itemIds: itemIds ?? this.itemIds,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      smartFitAdvice: smartFitAdvice ?? this.smartFitAdvice,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'occasion': occasion.name,
      'weather_suitable': weatherSuitable,
      'ai_score': aiScore,
      'elegance_score': eleganceScore,
      'color_score': colorScore,
      'ai_reason': aiReason,
      'item_ids': itemIds,
      'cover_image_url': coverImageUrl,
      if (smartFitAdvice != null) 'smart_fit_advice': smartFitAdvice!.toJson(),
      'is_favorite': isFavorite,
    };
  }
}
