import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../features/outfits/models/outfit_model.dart';
import '../../features/wardrobe/models/wardrobe_item_model.dart';
import 'smart_fit_engine.dart';

import '../constants/api_constants.dart';

class SmartFitAiService {
  // URLs kết nối đến Backend trên Render.com hoặc local
  static String get _backendUrl => ApiConstants.baseUrl;
  static String get _aiOrchestratorUrl {
    const envUrl = String.fromEnvironment('AI_ORCHESTRATOR_URL');
    if (envUrl.isNotEmpty) return envUrl;
    return 'http://10.30.1.50:8000';
  }

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
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return _parseOutfitFromJson(
            data, wardrobeItems, bodyAnalysis, occasion);
      }
    } catch (e) {
      debugPrint(
          '[SmartFitAiService] Backend failed, trying direct AI Orchestrator: $e');
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
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return _parseOutfitFromJson(
            data, wardrobeItems, bodyAnalysis, occasion);
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
      id: data['outfit_id']?.toString() ??
          'ai_outfit_${DateTime.now().millisecondsSinceEpoch}',
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
    if (lower.contains('tiệc') ||
        lower.contains('cưới') ||
        lower.contains('sang')) {
      return OutfitOccasion.formal;
    } else if (lower.contains('làm') ||
        lower.contains('sở') ||
        lower.contains('họp')) {
      return OutfitOccasion.work;
    } else if (lower.contains('tối') ||
        lower.contains('bar') ||
        lower.contains('date')) {
      return OutfitOccasion.evening;
    } else if (lower.contains('thao') ||
        lower.contains('chạy') ||
        lower.contains('gym')) {
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
      coverImageUrl:
          selectedItems.isNotEmpty ? selectedItems.first.imageUrl : '',
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

  /// Trò chuyện tương tác với AI Stylist (đối thoại, hỏi thăm hoàn cảnh, kiểm tra vóc dáng, chốt đồ mới tạo ảnh)
  static Future<Map<String, dynamic>> chatWithStylist({
    required List<Map<String, String>> messages,
    required List<WardrobeItemModel> wardrobeItems,
    required double heightCm,
    required double weightKg,
    String gender = 'Nữ',
    String userName = 'Bạn',
    bool forceFinalize = false,
  }) async {
    final bodyAnalysis = SmartFitEngine.analyzeBody(
      heightCm: heightCm,
      weightKg: weightKg,
      gender: gender,
    );

    final wardrobeJson = wardrobeItems.map((item) {
      return {
        'id': item.id,
        'name': item.name,
        'category': item.category.displayName,
        'primary_color': item.color,
        'style_tags': item.tags,
        'image_url': item.imageUrl,
      };
    }).toList();

    final payload = {
      'messages': messages,
      'user_name': userName,
      'user_profile': {
        'gender': gender,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'bmi': bodyAnalysis.bmi,
        'body_frame': bodyAnalysis.bodyFrame,
        'estimated_size': bodyAnalysis.estimatedSize,
      },
      'wardrobe_items': wardrobeJson,
      'force_finalize': forceFinalize,
    };

    // 1st attempt: Call Backend /outfits/stylist-chat
    try {
      final uri = Uri.parse('$_backendUrl/outfits/stylist-chat');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(minutes: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final replyText = (data['reply']?.toString() ?? '').trim();
        final safeReply = replyText.isNotEmpty
            ? replyText
            : 'Chào bạn! Stylist rất sẵn lòng hỗ trợ. Bạn muốn diện trang phục cho dịp nào thế ạ?';

        if (data['action'] == 'FINALIZE_OUTFIT') {
          final outfit = _parseOutfitFromJson(
            data,
            wardrobeItems,
            bodyAnalysis,
            messages.isNotEmpty
                ? messages.last['content'] ?? 'Đi chơi'
                : 'Đi chơi',
          );
          return {
            'action': 'FINALIZE_OUTFIT',
            'reply': safeReply,
            'outfit': outfit,
          };
        } else {
          return {
            'action': 'CONVERSATION',
            'reply': safeReply,
          };
        }
      }
    } catch (e) {
      debugPrint('[SmartFitAiService] Backend stylist-chat error: $e');
    }

    // 2nd attempt: Call direct Orchestrator /api/v1/stylist/chat (for local emulator or direct IP)
    try {
      final cleanBase = _aiOrchestratorUrl.replaceAll(RegExp(r'/v1/?$'), '');
      final uri = Uri.parse('$cleanBase/api/v1/stylist/chat');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final replyText = (data['reply']?.toString() ?? '').trim();
        final safeReply = replyText.isNotEmpty
            ? replyText
            : 'Chào bạn! Stylist đã sẵn sàng hỗ trợ bạn phối đồ.';

        if (data['action'] == 'FINALIZE_OUTFIT') {
          final outfit = _parseOutfitFromJson(
            data,
            wardrobeItems,
            bodyAnalysis,
            messages.isNotEmpty
                ? messages.last['content'] ?? 'Đi chơi'
                : 'Đi chơi',
          );
          return {
            'action': 'FINALIZE_OUTFIT',
            'reply': safeReply,
            'outfit': outfit,
          };
        } else {
          return {
            'action': 'CONVERSATION',
            'reply': safeReply,
          };
        }
      }
    } catch (e) {
      debugPrint('[SmartFitAiService] Orchestrator direct chat error: $e');
    }

    // Fallback if offline
    if (forceFinalize) {
      final outfit = _buildFallbackOutfit(
        wardrobeItems: wardrobeItems,
        bodyAnalysis: bodyAnalysis,
        occasion: messages.isNotEmpty
            ? messages.last['content'] ?? 'Đi chơi'
            : 'Đi chơi',
      );
      return {
        'action': 'FINALIZE_OUTFIT',
        'reply': outfit.aiReason,
        'outfit': outfit,
      };
    }

    final salutation = gender.toLowerCase().contains('nam')
        ? 'anh'
        : (gender.toLowerCase().contains('nữ') ? 'chị' : 'bạn');
    final sampleItem = wardrobeItems.isNotEmpty ? wardrobeItems.first.name : null;
    final hint = sampleItem != null
        ? 'Chào $salutation $userName! Em thấy tủ đồ của $salutation có "$sampleItem", mình có thể mix thêm cùng quần/váy phù hợp để tạo nên phong cách rất ấn tượng. $salutation muốn diện set này vào dịp nào thế ạ?'
        : 'Chào $salutation $userName! Stylist rất vui được hỗ trợ bạn. Hôm nay $salutation muốn tìm một phong cách năng động, thanh lịch hay cho dịp đặc biệt nào thế ạ?';
    return {
      'action': 'CONVERSATION',
      'reply': hint,
    };
  }
}
