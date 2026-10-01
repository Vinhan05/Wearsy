import 'package:flutter/material.dart';
import 'wardrobe_item_model.dart';

class DetectedClothingItem {
  String name;
  final String categoryCode;
  final int categoryId;
  final String categoryName;
  final String subCategory;
  final String primaryColor;
  final List<int> box2d; // [ymin, xmin, ymax, xmax] in 0..1000 scale
  final double confidence;
  final String season;
  final List<String> styleTags;
  bool isSelected;

  DetectedClothingItem({
    required this.name,
    required this.categoryCode,
    required this.categoryId,
    required this.categoryName,
    required this.subCategory,
    required this.primaryColor,
    required this.box2d,
    required this.confidence,
    required this.season,
    required this.styleTags,
    this.isSelected = true,
  });

  factory DetectedClothingItem.fromJson(Map<String, dynamic> json) {
    final rawBox = json['box2d'] ?? json['box_2d'];
    List<int> parsedBox = [0, 0, 1000, 1000];
    if (rawBox is List && rawBox.length == 4) {
      parsedBox = rawBox.map((e) => (e as num).toInt()).toList();
    }

    return DetectedClothingItem(
      name: json['name']?.toString() ?? 'Trang phục',
      categoryCode: (json['categoryCode'] ?? json['category_code'] ?? 'TOPS')
          .toString()
          .toUpperCase(),
      categoryId: (json['categoryId'] ?? json['category_id'] ?? 1) as int,
      categoryName: json['categoryName']?.toString() ??
          json['category_name']?.toString() ??
          'Áo',
      subCategory: json['subCategory']?.toString() ??
          json['sub_category']?.toString() ??
          'Trang phục',
      primaryColor: json['primaryColor']?.toString() ??
          json['primary_color']?.toString() ??
          'Đa sắc',
      box2d: parsedBox,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.9,
      season: json['season']?.toString() ?? 'ALL',
      styleTags: (json['styleTags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (json['style_tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Casual'],
      isSelected: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category_code': categoryCode,
      'category_id': categoryId,
      'category_name': categoryName,
      'sub_category': subCategory,
      'primary_color': primaryColor,
      'box_2d': box2d,
      'confidence': confidence,
      'season': season,
      'style_tags': styleTags,
    };
  }

  WardrobeCategory get wardrobeCategory {
    final lowerSub = subCategory.toLowerCase();
    if (lowerSub.contains('đầm') ||
        lowerSub.contains('váy') ||
        lowerSub.contains('dress')) {
      return WardrobeCategory.dresses;
    }

    switch (categoryCode) {
      case 'TOPS':
        return WardrobeCategory.tops;
      case 'BOTTOMS':
        return WardrobeCategory.bottoms;
      case 'OUTERWEAR':
        return WardrobeCategory.outerwear;
      case 'FOOTWEAR':
        return WardrobeCategory.shoes;
      case 'ACCESSORIES':
        return WardrobeCategory.accessories;
      default:
        return WardrobeCategory.tops;
    }
  }

  WardrobeItemModel toWardrobeItemModel({
    required String itemId,
    required String fallbackImageUrl,
  }) {
    return WardrobeItemModel(
      id: itemId,
      name: name,
      category: wardrobeCategory,
      color: primaryColor,
      brand: 'Tủ đồ của tôi',
      imageUrl: fallbackImageUrl,
      tags: styleTags,
      aiMatchScore: (confidence * 10).clamp(7.5, 9.9),
      layerOrder: wardrobeCategory.defaultLayerOrder,
    );
  }

  Color get tagColor {
    switch (categoryCode) {
      case 'TOPS':
        return const Color(0xFF6C63FF); // Tím neon
      case 'BOTTOMS':
        return const Color(0xFF00D2FC); // Xanh biển
      case 'OUTERWEAR':
        return const Color(0xFFFF9F43); // Cam đất
      case 'FOOTWEAR':
        return const Color(0xFF10AC84); // Xanh ngọc
      case 'ACCESSORIES':
        return const Color(0xFFFF6B6B); // Hồng đào
      default:
        return Colors.indigoAccent;
    }
  }
}

class BulkScanSummary {
  final int topsCount;
  final int bottomsCount;
  final int outerwearCount;
  final int footwearCount;
  final int accessoriesCount;
  final Map<String, int> bySubCategory;

  BulkScanSummary({
    required this.topsCount,
    required this.bottomsCount,
    required this.outerwearCount,
    required this.footwearCount,
    required this.accessoriesCount,
    required this.bySubCategory,
  });

  factory BulkScanSummary.fromJson(Map<String, dynamic> json) {
    final rawSub = json['bySubCategory'] ?? json['by_sub_category'] ?? {};
    final subMap = <String, int>{};
    if (rawSub is Map) {
      rawSub.forEach((key, val) {
        subMap[key.toString()] = (val as num).toInt();
      });
    }

    return BulkScanSummary(
      topsCount: (json['topsCount'] ?? json['tops_count'] ?? 0) as int,
      bottomsCount: (json['bottomsCount'] ?? json['bottoms_count'] ?? 0) as int,
      outerwearCount:
          (json['outerwearCount'] ?? json['outerwear_count'] ?? 0) as int,
      footwearCount:
          (json['footwearCount'] ?? json['footwear_count'] ?? 0) as int,
      accessoriesCount:
          (json['accessoriesCount'] ?? json['accessories_count'] ?? 0) as int,
      bySubCategory: subMap,
    );
  }
}

class BulkScanResponse {
  final bool success;
  final String message;
  final String imageUrl;
  final int totalDetected;
  final BulkScanSummary summary;
  final List<DetectedClothingItem> items;

  BulkScanResponse({
    required this.success,
    required this.message,
    required this.imageUrl,
    required this.totalDetected,
    required this.summary,
    required this.items,
  });

  factory BulkScanResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? [];
    final itemsList = rawItems
        .map((e) => DetectedClothingItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return BulkScanResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      imageUrl:
          json['imageUrl']?.toString() ?? json['image_url']?.toString() ?? '',
      totalDetected: (json['totalDetected'] ??
          json['total_detected'] ??
          itemsList.length) as int,
      summary: BulkScanSummary.fromJson(
        (json['summary'] as Map<String, dynamic>?) ?? {},
      ),
      items: itemsList,
    );
  }
}
