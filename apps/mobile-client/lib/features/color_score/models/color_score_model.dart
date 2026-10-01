import 'package:flutter/material.dart';

enum ColorHarmonyType {
  monochromatic,
  analogous,
  complementary,
  triadic,
  neutral,
  contrast,
}

enum PersonalSeason {
  springWarm, // Xuân Ấm Áp - Tươi sáng, rực rỡ
  summerCool, // Hạ Dịu Dàng - Pastel, thanh nhã
  autumnDeep, // Thu Trầm Ấm - Tone đất, vintage
  winterVivid, // Đông Sắc Nét - Tương phản cao, sang trọng
}

class ColorHarmonyResult {
  final double score;
  final String harmonyType;
  final String ruleApplied;
  final String feedback;
  final String colorRatioEvaluation;
  final List<String> stylingTips;
  final List<Color> dominantColors;
  final Color? accentColor;

  const ColorHarmonyResult({
    required this.score,
    required this.harmonyType,
    required this.ruleApplied,
    required this.feedback,
    required this.colorRatioEvaluation,
    required this.stylingTips,
    required this.dominantColors,
    this.accentColor,
  });

  factory ColorHarmonyResult.fromJson(Map<String, dynamic> json) {
    return ColorHarmonyResult(
      score: (json['score'] as num?)?.toDouble() ?? 9.2,
      harmonyType: json['harmony_type']?.toString() ?? 'ANALOGOUS',
      ruleApplied: json['rule_applied']?.toString() ??
          'Quy tắc phối màu tương đồng & cân bằng tỷ lệ 60-30-10',
      feedback: json['feedback']?.toString() ??
          'Sự kết hợp màu sắc thanh thoát, hài hòa và tôn dáng.',
      colorRatioEvaluation: json['color_ratio_evaluation']?.toString() ??
          '60% Màu nền chính + 30% Màu bổ trợ + 10% Điểm nhấn.',
      stylingTips: (json['styling_tips'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [
            'Phối cùng phụ kiện ánh kim hoặc da trung tính để tăng điểm nhấn.',
            'Giữ tối đa 3 tông màu chủ đạo trong cùng một set đồ.'
          ],
      dominantColors: const [
        Color(0xFF1E293B),
        Color(0xFFF1F5F9),
        Color(0xFF6366F1),
      ],
      accentColor: const Color(0xFFF59E0B),
    );
  }
}

class ColorChallenge {
  final String id;
  final String title;
  final String category;
  final String description;
  final String rewardBadge;
  final int rewardPoints;
  final String status; // 'AVAILABLE', 'IN_PROGRESS', 'COMPLETED'
  final String progressText;
  final double progressPercent;
  final List<Color> palettePreview;

  const ColorChallenge({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.rewardBadge,
    required this.rewardPoints,
    required this.status,
    required this.progressText,
    required this.progressPercent,
    required this.palettePreview,
  });
}

class SeasonalColorProfile {
  final PersonalSeason season;
  final String seasonName;
  final String subtitle;
  final String description;
  final String undertone;
  final List<ColorItem> bestColors;
  final List<ColorItem> avoidColors;
  final List<String> stylingRules;

  const SeasonalColorProfile({
    required this.season,
    required this.seasonName,
    required this.subtitle,
    required this.description,
    required this.undertone,
    required this.bestColors,
    required this.avoidColors,
    required this.stylingRules,
  });
}

class ColorItem {
  final String name;
  final Color color;
  final String hex;
  final String usageTip;

  const ColorItem({
    required this.name,
    required this.color,
    required this.hex,
    required this.usageTip,
  });
}
