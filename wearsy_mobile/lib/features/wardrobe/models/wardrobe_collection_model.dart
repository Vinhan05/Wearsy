class WardrobeCollectionModel {
  final String id;
  final String name;
  final String icon;
  final String description;
  final bool isDefault;
  final DateTime createdAt;

  WardrobeCollectionModel({
    required this.id,
    required this.name,
    this.icon = '🏠',
    this.description = '',
    this.isDefault = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory WardrobeCollectionModel.defaultWardrobe() {
    return WardrobeCollectionModel(
      id: 'default',
      name: 'Tủ Đồ Hàng Ngày',
      icon: '🏠',
      description: 'Trang phục thường nhật & dạo phố',
      isDefault: true,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  factory WardrobeCollectionModel.fromJson(Map<String, dynamic> json) {
    return WardrobeCollectionModel(
      id: json['id']?.toString() ?? 'default',
      name: json['name']?.toString() ?? 'Tủ Đồ Hàng Ngày',
      icon: json['icon']?.toString() ?? '🏠',
      description: json['description']?.toString() ?? '',
      isDefault: json['is_default'] == true || json['isDefault'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'description': description,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }

  WardrobeCollectionModel copyWith({
    String? id,
    String? name,
    String? icon,
    String? description,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return WardrobeCollectionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
