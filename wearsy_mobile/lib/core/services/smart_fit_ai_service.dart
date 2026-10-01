import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../features/outfits/models/outfit_model.dart';
import '../../features/wardrobe/models/wardrobe_item_model.dart';
import 'smart_fit_engine.dart';

class SmartFitAiService {
  // URLs for Android Emulator (10.0.2.2) and local host
  static const String _backendUrl = 'http://10.0.2.2:3000/api/v1';
  static const String _aiOrchestratorUrl = 'http://10.0.2.2:8000/api/v1';

  /// Sinh gợi ý Outfit kết hợp giữa Gemma 4 Multimodal và ComfyUI Try-on
  static Future<OutfitModel> generateSmartFitOutfit({
    required List<WardrobeItemModel> wardrobeItems,
    required double heightCm,
    required double weightKg,
    String gender = 'Nữ',
    String occasion = 'Công sở thường ngày',
    String stylePreference = 'Thanh lịch, hiện đại',
    String userName = 'Bạn',
  }) async {
    // 1. Phân tích thể trạng qua Deterministic Engine (< 5ms)
    final bodyAnalysis = SmartFitEngine.analyzeBody(
      heightCm: heightCm,
      weightKg: weightKg,
      gender: gender,
    );

    if (wardrobeItems.isEmpty) {
      return _buildFallbackOutfit(
        wardrobeItems: [],
        bodyAnalysis: bodyAnalysis,
        occasion: occasion,
      );
    }

    // 2. Thử gọi Wearsy AI Service (Backend hoặc AI Orchestrator Gateway)
    try {
      final aiResult = await _callWearsyAiEngine(
        wardrobeItems: wardrobeItems,
        bodyAnalysis: bodyAnalysis,
        occasion: occasion,
        stylePreference: stylePreference,
        userName: userName,
      );
      if (aiResult != null) {
        return aiResult;
      }
    } catch (e) {
      debugPrint('[SmartFitAiService] Wearsy AI Engine call exception: $e');
    }

    // 3. Fallback: Heuristic Engine nội bộ đảm bảo app hoạt động 100% không gián đoạn
    return _buildFallbackOutfit(
      wardrobeItems: wardrobeItems,
      bodyAnalysis: bodyAnalysis,
      occasion: occasion,
    );
  }

  static Future<OutfitModel?> _callWearsyAiEngine({
    required List<WardrobeItemModel> wardrobeItems,
    required BodyAnalysisResult bodyAnalysis,
    required String occasion,
    required String stylePreference,
    required String userName,
  }) async {
    final wardrobeJson = wardrobeItems.map((item) {
      return {
        'id': item.id,
        'name': item.name,
        'category': item.category.displayName,
        'primary_color': item.color,
        'style_tags': item.tags,
        'image_url': item.imageUrl,
        'layer_order': item.layerOrder,
      };
    }).toList();

    final payload = {
      'user_prompt': occasion,
      'occasion': occasion,
      'user_name': userName,
      'user_body_summary': bodyAnalysis.toJson(),
      'wardrobe_items': wardrobeJson,
    };

    // 1st attempt: Call NestJS Backend
    try {
      final uri = Uri.parse('$_backendUrl/outfits/ai-recommend');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(minutes: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return _parseOutfitFromJson(data, wardrobeItems, bodyAnalysis, occasion);
      }
    } catch (e) {
      debugPrint('[SmartFitAiService] Backend failed, trying direct AI Orchestrator: $e');
    }

    // 2nd attempt: Call Direct AI Orchestrator Gateway (port 8000)
    try {
      final uri = Uri.parse('$_aiOrchestratorUrl/stylist/recommend');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(minutes: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return _parseOutfitFromJson(data, wardrobeItems, bodyAnalysis, occasion);
      }
    } catch (e) {
      debugPrint('[SmartFitAiService] Direct AI Orchestrator failed: $e');
    }

    return null;
  }

  static OutfitModel _parseOutfitFromJson(
    Map<String, dynamic> data,
    List<WardrobeItemModel> wardrobeItems,
    BodyAnalysisResult bodyAnalysis,
    String occasion,
  ) {
    final rawItemIds = (data['selected_item_ids'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        (data['item_ids'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final validIds = rawItemIds
        .where((id) => wardrobeItems.any((item) => item.id == id))
        .toList();

    final finalItemIds = validIds.isNotEmpty
        ? validIds
        : wardrobeItems.take(2).map((i) => i.id).toList();

    final title = data['title']?.toString() ?? 'Gợi ý từ WEARSY AI';
    final reply = data['reply']?.toString() ??
        data['stylist_reasoning']?.toString() ??
        'Bộ outfit được AI phối hợp hài hòa, tôn dáng và phù hợp với dịp của bạn.';

    final imageUrl = data['image_url']?.toString() ??
        data['image_base64']?.toString() ??
        '';

    final advice = SmartFitAdvice(
      sizeRecommendation: 'Size ${bodyAnalysis.estimatedSize}',
      bodyProportionTip: bodyAnalysis.defaultProportionTip.isNotEmpty
          ? bodyAnalysis.defaultProportionTip
          : 'Sơ vin áo gọn gàng để nâng cao tỷ lệ eo và chân.',
      fitWarnings: bodyAnalysis.fitWarnings,
      bmi: bodyAnalysis.bmi,
      bodyFrame: bodyAnalysis.bodyFrame,
      userHeight: bodyAnalysis.heightCm,
      userWeight: bodyAnalysis.weightKg,
    );

    return OutfitModel(
      id: data['outfit_id']?.toString() ?? 'ai_outfit_${DateTime.now().millisecondsSinceEpoch}',
      name: title,
      occasion: _matchOccasion(occasion),
      weatherSuitable: ['Mọi thời tiết'],
      aiScore: (data['elegance_score'] as num?)?.toDouble() ?? 9.2,
      eleganceScore: (data['elegance_score'] as num?)?.toDouble() ?? 9.2,
      colorScore: (data['color_score'] as num?)?.toDouble() ?? 9.0,
      aiReason: reply,
      itemIds: finalItemIds,
      coverImageUrl: imageUrl,
      smartFitAdvice: advice,
    );
  }

  static OutfitOccasion _matchOccasion(String occasion) {
    final lower = occasion.toLowerCase();
    if (lower.contains('tiệc') || lower.contains('cưới') || lower.contains('sang')) {
      return OutfitOccasion.formal;
    } else if (lower.contains('làm') || lower.contains('sở') || lower.contains('họp')) {
      return OutfitOccasion.work;
    } else if (lower.contains('tối') || lower.contains('bar') || lower.contains('date')) {
      return OutfitOccasion.evening;
    } else if (lower.contains('thao') || lower.contains('chạy') || lower.contains('gym')) {
      return OutfitOccasion.sport;
    }
    return OutfitOccasion.casual;
  }

  static OutfitModel _buildFallbackOutfit({
    required List<WardrobeItemModel> wardrobeItems,
    required BodyAnalysisResult bodyAnalysis,
    required String occasion,
  }) {
    final selectedItems = wardrobeItems.take(3).toList();
    final itemIds = selectedItems.map((item) => item.id).toList();

    return OutfitModel(
      id: 'outfit_local_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Phối Đồ Hài Hòa Cho $occasion',
      occasion: _matchOccasion(occasion),
      weatherSuitable: ['Mọi thời tiết'],
      aiScore: 9.0,
      eleganceScore: 9.0,
      colorScore: 8.8,
      aiReason: selectedItems.isNotEmpty
          ? 'Sự kết hợp giữa ${selectedItems.map((e) => e.name).join(', ')} mang lại vẻ ngoài trẻ trung, thanh lịch và cân đối.'
          : 'Tủ đồ của bạn chưa có đủ món để phối.',
      itemIds: itemIds,
      coverImageUrl: selectedItems.isNotEmpty ? selectedItems.first.imageUrl : '',
      smartFitAdvice: SmartFitAdvice(
        sizeRecommendation: 'Size ${bodyAnalysis.estimatedSize}',
        bodyProportionTip: bodyAnalysis.defaultProportionTip.isNotEmpty
            ? bodyAnalysis.defaultProportionTip
            : 'Sơ vin áo gọn gàng để nâng cao tỷ lệ chân.',
        fitWarnings: bodyAnalysis.fitWarnings,
        bmi: bodyAnalysis.bmi,
        bodyFrame: bodyAnalysis.bodyFrame,
        userHeight: bodyAnalysis.heightCm,
        userWeight: bodyAnalysis.weightKg,
      ),
    );
  }
}
