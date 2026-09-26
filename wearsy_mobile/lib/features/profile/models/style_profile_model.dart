class StyleProfileModel {
  final List<String> preferredStyles;
  final List<String> favoriteColors;
  final List<String> avoidColors;
  final double minBudget;
  final double maxBudget;
  final int? height;
  final int? weight;
  final String? bodyShape;

  StyleProfileModel({
    this.preferredStyles = const ['Thanh lịch', 'Minimalism'],
    this.favoriteColors = const ['White', 'Navy', 'Beige'],
    this.avoidColors = const [],
    this.minBudget = 200000,
    this.maxBudget = 1500000,
    this.height,
    this.weight,
    this.bodyShape,
  });

  factory StyleProfileModel.fromJson(Map<String, dynamic> json) {
    final styles = (json['preferred_styles'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ['Thanh lịch', 'Minimalism'];

    List<String> favs = ['Trắng', 'Xanh Navy', 'Beige'];
    List<String> avoids = [];
    if (json['color_preferences'] is Map) {
      final cp = json['color_preferences'] as Map;
      if (cp['favorites'] is List) {
        favs = (cp['favorites'] as List).map((e) => e.toString()).toList();
      }
      if (cp['avoid'] is List) {
        avoids = (cp['avoid'] as List).map((e) => e.toString()).toList();
      }
    }

    double minB = 200000;
    double maxB = 1500000;
    if (json['budget_range'] is Map) {
      final br = json['budget_range'] as Map;
      minB = (br['min'] as num?)?.toDouble() ?? 200000;
      maxB = (br['max'] as num?)?.toDouble() ?? 1500000;
    }

    int? h;
    int? w;
    String? shape;
    if (json['body_measurements'] is Map) {
      final bm = json['body_measurements'] as Map;
      h = (bm['height'] as num?)?.toInt();
      w = (bm['weight'] as num?)?.toInt();
      shape = bm['body_shape']?.toString();
    }

    return StyleProfileModel(
      preferredStyles: styles,
      favoriteColors: favs,
      avoidColors: avoids,
      minBudget: minB,
      maxBudget: maxB,
      height: h,
      weight: w,
      bodyShape: shape,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preferred_styles': preferredStyles,
      'color_preferences': {
        'favorites': favoriteColors,
        'avoid': avoidColors,
      },
      'budget_range': {
        'min': minBudget,
        'max': maxBudget,
        'currency': 'VND',
      },
      'body_measurements': {
        if (height != null) 'height': height,
        if (weight != null) 'weight': weight,
        if (bodyShape != null) 'body_shape': bodyShape,
      },
    };
  }
}
