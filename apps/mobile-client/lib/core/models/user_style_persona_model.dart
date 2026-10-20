/// Mô hình lưu trữ Hồ sơ & Phong cách người dùng cá nhân hóa trên thiết bị (On-Device Style Persona)
/// Dùng để lưu trực tiếp vào file JSON cục bộ trong app data directory
class UserStylePersonaModel {
  final String userId;
  final String version;
  final DateTime lastUpdated;

  // Style DNA
  final List<String> primaryStyles;
  final List<String> favoriteColors;
  final List<String> avoidedColors;
  final String fitPreference;
  final List<String> preferredMaterials;

  // Body & Sizing
  final double? heightCm;
  final double? weightKg;
  final String? gender;
  final String? bodyFrame;

  // Behavioral Memory
  final List<String> frequentOccasions;
  final List<Map<String, dynamic>> favoriteCombinations;
  final List<String> likedOutfitIds;

  // AI Prompt Tuning
  final String? customAiNote;

  UserStylePersonaModel({
    this.userId = 'local_user',
    this.version = '1.0',
    DateTime? lastUpdated,
    this.primaryStyles = const ['Minimalism', 'Casual', 'Thanh lịch'],
    this.favoriteColors = const ['Trắng', 'Đen', 'Xanh navy', 'Be'],
    this.avoidedColors = const [],
    this.fitPreference = 'Vừa vặn thoải mái (Regular / Relaxed fit)',
    this.preferredMaterials = const ['Cotton', 'Linen', 'Denim'],
    this.heightCm,
    this.weightKg,
    this.gender,
    this.bodyFrame,
    this.frequentOccasions = const ['Đi làm', 'Dạo phố', 'Cà phê cuối tuần'],
    this.favoriteCombinations = const [],
    this.likedOutfitIds = const [],
    this.customAiNote,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory UserStylePersonaModel.fromJson(Map<String, dynamic> json) {
    return UserStylePersonaModel(
      userId: json['user_id']?.toString() ?? 'local_user',
      version: json['version']?.toString() ?? '1.0',
      lastUpdated: json['last_updated'] != null
          ? DateTime.tryParse(json['last_updated'].toString()) ?? DateTime.now()
          : DateTime.now(),
      primaryStyles: _toStringList(json['style_dna']?['primary_styles']),
      favoriteColors: _toStringList(json['style_dna']?['favorite_colors']),
      avoidedColors: _toStringList(json['style_dna']?['avoided_colors']),
      fitPreference: json['style_dna']?['fit_preference']?.toString() ??
          'Vừa vặn thoải mái (Regular / Relaxed fit)',
      preferredMaterials:
          _toStringList(json['style_dna']?['preferred_materials']),
      heightCm: (json['body_and_sizing']?['height_cm'] as num?)?.toDouble(),
      weightKg: (json['body_and_sizing']?['weight_kg'] as num?)?.toDouble(),
      gender: json['body_and_sizing']?['gender']?.toString(),
      bodyFrame: json['body_and_sizing']?['body_frame']?.toString(),
      frequentOccasions:
          _toStringList(json['behavioral_habits']?['frequent_occasions']),
      favoriteCombinations: (json['behavioral_habits']?['favorite_combinations']
                  as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      likedOutfitIds:
          _toStringList(json['behavioral_habits']?['liked_outfit_ids']),
      customAiNote: json['ai_tuning_prompt']?.toString(),
    );
  }

  static List<String> _toStringList(dynamic val) {
    if (val is List) {
      return val.map((e) => e.toString()).toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'version': version,
      'last_updated': lastUpdated.toIso8601String(),
      'style_dna': {
        'primary_styles': primaryStyles,
        'favorite_colors': favoriteColors,
        'avoided_colors': avoidedColors,
        'fit_preference': fitPreference,
        'preferred_materials': preferredMaterials,
      },
      'body_and_sizing': {
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'gender': gender,
        'body_frame': bodyFrame,
      },
      'behavioral_habits': {
        'frequent_occasions': frequentOccasions,
        'favorite_combinations': favoriteCombinations,
        'liked_outfit_ids': likedOutfitIds,
      },
      'ai_tuning_prompt': toPromptContext(),
    };
  }

  /// Xuất chuỗi ngữ cảnh nhúng trực tiếp vào prompt cho AI Stylist (Context Injection)
  String toPromptContext() {
    final buffer = StringBuffer();
    if (primaryStyles.isNotEmpty) {
      buffer.write('Gu thời trang ưu tiên: ${primaryStyles.join(', ')}. ');
    }
    if (favoriteColors.isNotEmpty) {
      buffer.write('Màu sắc yêu thích: ${favoriteColors.join(', ')}. ');
    }
    if (avoidedColors.isNotEmpty) {
      buffer.write('Màu nên hạn chế/tránh: ${avoidedColors.join(', ')}. ');
    }
    if (fitPreference.isNotEmpty) {
      buffer.write('Form dáng ưa chuộng: $fitPreference. ');
    }
    if (preferredMaterials.isNotEmpty) {
      buffer.write('Chất liệu ưa thích: ${preferredMaterials.join(', ')}. ');
    }
    if (customAiNote != null && customAiNote!.isNotEmpty) {
      buffer.write('$customAiNote. ');
    }
    return buffer.toString().trim();
  }

  UserStylePersonaModel copyWith({
    String? userId,
    String? version,
    DateTime? lastUpdated,
    List<String>? primaryStyles,
    List<String>? favoriteColors,
    List<String>? avoidedColors,
    String? fitPreference,
    List<String>? preferredMaterials,
    double? heightCm,
    double? weightKg,
    String? gender,
    String? bodyFrame,
    List<String>? frequentOccasions,
    List<Map<String, dynamic>>? favoriteCombinations,
    List<String>? likedOutfitIds,
    String? customAiNote,
  }) {
    return UserStylePersonaModel(
      userId: userId ?? this.userId,
      version: version ?? this.version,
      lastUpdated: lastUpdated ?? DateTime.now(),
      primaryStyles: primaryStyles ?? this.primaryStyles,
      favoriteColors: favoriteColors ?? this.favoriteColors,
      avoidedColors: avoidedColors ?? this.avoidedColors,
      fitPreference: fitPreference ?? this.fitPreference,
      preferredMaterials: preferredMaterials ?? this.preferredMaterials,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      gender: gender ?? this.gender,
      bodyFrame: bodyFrame ?? this.bodyFrame,
      frequentOccasions: frequentOccasions ?? this.frequentOccasions,
      favoriteCombinations: favoriteCombinations ?? this.favoriteCombinations,
      likedOutfitIds: likedOutfitIds ?? this.likedOutfitIds,
      customAiNote: customAiNote ?? this.customAiNote,
    );
  }
}
