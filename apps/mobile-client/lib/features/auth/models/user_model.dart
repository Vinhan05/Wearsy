class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final List<String> preferredStyles;
  final Map<String, dynamic>? colorPreferences;
  final Map<String, dynamic>? budgetRange;
  final Map<String, dynamic>? bodyMeasurements;
  final bool isVip;
  final DateTime? vipExpiresAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.preferredStyles = const [],
    this.colorPreferences,
    this.budgetRange,
    this.bodyMeasurements,
    this.isVip = false,
    this.vipExpiresAt,
  });

  /// Kiểm tra trạng thái VIP còn hiệu lực hay không
  bool get hasActiveVip {
    if (vipExpiresAt != null) {
      return vipExpiresAt!.isAfter(DateTime.now());
    }
    return isVip;
  }

  /// Số ngày VIP còn lại
  int get vipDaysRemaining {
    if (vipExpiresAt == null) return isVip ? 7 : 0;
    final diff = vipExpiresAt!.difference(DateTime.now()).inDays;
    return diff >= 0 ? diff + 1 : 0;
  }

  /// Tên nhãn hiển thị cho gói thành viên
  String get vipStatusLabel {
    return hasActiveVip ? 'VIP Fashionista' : 'Thành viên Thường';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedVipExpiry;
    final rawExpiry = json['vip_expires_at'] ?? json['vipExpiresAt'];
    if (rawExpiry != null) {
      parsedVipExpiry = DateTime.tryParse(rawExpiry.toString());
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName:
          json['full_name']?.toString() ?? json['fullName']?.toString() ?? '',
      avatarUrl:
          json['avatar_url']?.toString() ?? json['avatarUrl']?.toString(),
      preferredStyles: (json['preferred_styles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      colorPreferences: json['color_preferences'] is Map<String, dynamic>
          ? json['color_preferences']
          : null,
      budgetRange: json['budget_range'] is Map<String, dynamic>
          ? json['budget_range']
          : null,
      bodyMeasurements: json['body_measurements'] is Map<String, dynamic>
          ? json['body_measurements']
          : null,
      isVip: json['is_vip'] == true || json['isVip'] == true,
      vipExpiresAt: parsedVipExpiry,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'preferred_styles': preferredStyles,
      'color_preferences': colorPreferences,
      'budget_range': budgetRange,
      'body_measurements': bodyMeasurements,
      'is_vip': isVip,
      'vip_expires_at': vipExpiresAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    List<String>? preferredStyles,
    Map<String, dynamic>? colorPreferences,
    Map<String, dynamic>? budgetRange,
    Map<String, dynamic>? bodyMeasurements,
    bool? isVip,
    DateTime? vipExpiresAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      preferredStyles: preferredStyles ?? this.preferredStyles,
      colorPreferences: colorPreferences ?? this.colorPreferences,
      budgetRange: budgetRange ?? this.budgetRange,
      bodyMeasurements: bodyMeasurements ?? this.bodyMeasurements,
      isVip: isVip ?? this.isVip,
      vipExpiresAt: vipExpiresAt ?? this.vipExpiresAt,
    );
  }
}

class AuthSuccessData {
  final String token;
  final int expiresIn;
  final UserModel user;

  AuthSuccessData({
    required this.token,
    required this.expiresIn,
    required this.user,
  });

  factory AuthSuccessData.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] is Map<String, dynamic>
        ? json['user']
        : <String, dynamic>{};
    return AuthSuccessData(
      token: json['token']?.toString() ?? '',
      expiresIn: json['expires_in'] is int ? json['expires_in'] : 86400,
      user: UserModel.fromJson(userData),
    );
  }
}
