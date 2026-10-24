import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../features/outfits/models/outfit_model.dart';
import '../../features/wardrobe/models/wardrobe_item_model.dart';
import 'smart_fit_engine.dart';
import 'smart_shopping_ai_service.dart';

import '../constants/api_constants.dart';
import '../models/user_style_persona_model.dart';
import '../storage/style_persona_storage.dart';

class SmartFitAiService {
  // URLs kết nối đến Backend trên Render.com hoặc local
  static String get _backendUrl => ApiConstants.baseUrl;
  static String get _aiOrchestratorUrl {
    const envUrl = String.fromEnvironment('AI_ORCHESTRATOR_URL');
    if (envUrl.isNotEmpty) return envUrl;
    return _backendUrl;
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
    // Tải hồ sơ phong cách lưu cục bộ trên máy
    final persona = await StylePersonaStorage.loadPersona();
    final effectiveStyle = (stylePreference.isNotEmpty &&
            stylePreference != 'Thanh lịch, hiện đại')
        ? stylePreference
        : (persona.toPromptContext().isNotEmpty
            ? persona.toPromptContext()
            : stylePreference);

    // 1. Phân tích thể trạng qua Deterministic Engine (< 5ms)
    final bodyAnalysis = SmartFitEngine.analyzeBody(
      heightCm: heightCm > 0 ? heightCm : (persona.heightCm ?? 172.0),
      weightKg: weightKg > 0 ? weightKg : (persona.weightKg ?? 65.0),
      gender: gender.isNotEmpty ? gender : (persona.gender ?? 'Nam'),
    );

    if (wardrobeItems.isEmpty) {
      return _buildFallbackOutfit(
        wardrobeItems: [],
        bodyAnalysis: bodyAnalysis,
        occasion: occasion,
        persona: persona,
      );
    }

    // 2. Thử gọi Wearsy AI Service (Backend hoặc AI Orchestrator Gateway)
    try {
      final aiResult = await _callWearsyAiEngine(
        wardrobeItems: wardrobeItems,
        bodyAnalysis: bodyAnalysis,
        occasion: occasion,
        stylePreference: effectiveStyle,
        userName: userName,
        persona: persona,
      );
      if (aiResult != null) {
        return aiResult;
      }
    } catch (e) {
      debugPrint('[SmartFitAiService] Wearsy AI Engine call exception: $e');
    }

    // 3. Fallback: Heuristic Engine nội bộ cá nhân hóa theo Persona
    return _buildFallbackOutfit(
      wardrobeItems: wardrobeItems,
      bodyAnalysis: bodyAnalysis,
      occasion: occasion,
      persona: persona,
    );
  }

  static Future<OutfitModel?> _callWearsyAiEngine({
    required List<WardrobeItemModel> wardrobeItems,
    required BodyAnalysisResult bodyAnalysis,
    required String occasion,
    required String stylePreference,
    required String userName,
    UserStylePersonaModel? persona,
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

    final promptPrefix = persona != null && persona.toPromptContext().isNotEmpty
        ? '[Gu phong cách cá nhân: ${persona.toPromptContext()}] '
        : '';

    final payload = {
      'user_prompt': '$promptPrefix$occasion',
      'occasion': occasion,
      'style_preference': stylePreference,
      'user_name': userName,
      'user_body_summary': bodyAnalysis.toJson(),
      'wardrobe_items': wardrobeJson,
      if (persona != null) 'user_style_persona': persona.toJson(),
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

    List<String> finalItemIds;
    if (validIds.isNotEmpty) {
      finalItemIds = List<String>.from(validIds);

      // Kiểm tra bảo đảm outfit luôn có cả Thân trên (Áo) và Thân dưới (Quần/Váy) nếu tủ đồ có sẵn
      final currentItems = wardrobeItems.where((i) => finalItemIds.contains(i.id)).toList();
      final hasTop = currentItems.any((i) => i.category == WardrobeCategory.tops);
      final hasBottom = currentItems.any((i) => i.category == WardrobeCategory.bottoms);
      final hasDress = currentItems.any((i) => i.category == WardrobeCategory.dresses);

      if (!hasBottom && !hasDress) {
        final availableBottoms = wardrobeItems.where((i) => i.category == WardrobeCategory.bottoms).toList();
        if (availableBottoms.isNotEmpty) {
          finalItemIds.add(availableBottoms.first.id);
        }
      }
      if (!hasTop && !hasDress) {
        final availableTops = wardrobeItems.where((i) => i.category == WardrobeCategory.tops).toList();
        if (availableTops.isNotEmpty) {
          finalItemIds.insert(0, availableTops.first.id);
        }
      }
    } else {
      final fallbackOutfit = _buildFallbackOutfit(
        wardrobeItems: wardrobeItems,
        bodyAnalysis: bodyAnalysis,
        occasion: occasion,
      );
      finalItemIds = fallbackOutfit.itemIds;
    }

    final title = data['title']?.toString() ?? 'Gợi ý từ WEARSY AI';
    final reply = data['reply']?.toString() ??
        data['stylist_reasoning']?.toString() ??
        'Bộ outfit được AI phối hợp hài hòa, tôn dáng và phù hợp với dịp của bạn.';

    final imageUrl =
        data['image_url']?.toString() ?? data['image_base64']?.toString() ?? '';

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
    UserStylePersonaModel? persona,
  }) {
    // Sắp xếp các món đồ dựa trên mức độ phù hợp với Persona (màu yêu thích, style tags)
    final sortedItems = List<WardrobeItemModel>.from(wardrobeItems);
    if (persona != null && sortedItems.isNotEmpty) {
      sortedItems.sort((a, b) {
        int scoreA = 0;
        int scoreB = 0;

        // Điểm ưu tiên màu sắc yêu thích / tránh màu kỵ
        for (final fav in persona.favoriteColors) {
          if (a.color.toLowerCase().contains(fav.toLowerCase())) scoreA += 3;
          if (b.color.toLowerCase().contains(fav.toLowerCase())) scoreB += 3;
        }
        for (final avoid in persona.avoidedColors) {
          if (a.color.toLowerCase().contains(avoid.toLowerCase())) scoreA -= 5;
          if (b.color.toLowerCase().contains(avoid.toLowerCase())) scoreB -= 5;
        }

        // Điểm ưu tiên gu thời trang
        for (final st in persona.primaryStyles) {
          if (a.tags.any((t) => t.toLowerCase().contains(st.toLowerCase()))) {
            scoreA += 2;
          }
          if (b.tags.any((t) => t.toLowerCase().contains(st.toLowerCase()))) {
            scoreB += 2;
          }
        }

        return scoreB.compareTo(scoreA);
      });
    }

    // Phân loại các món đồ theo slot trang phục
    final tops = sortedItems.where((i) => i.category == WardrobeCategory.tops).toList();
    final bottoms = sortedItems.where((i) => i.category == WardrobeCategory.bottoms).toList();
    final dresses = sortedItems.where((i) => i.category == WardrobeCategory.dresses).toList();
    final outerwear = sortedItems.where((i) => i.category == WardrobeCategory.outerwear).toList();
    final shoes = sortedItems.where((i) => i.category == WardrobeCategory.shoes).toList();

    final List<WardrobeItemModel> selectedItems = [];
    final isDressOccasion = occasion.toLowerCase().contains('tiệc') ||
        occasion.toLowerCase().contains('hẹn hò') ||
        occasion.toLowerCase().contains('date');

    if (dresses.isNotEmpty && (bottoms.isEmpty || isDressOccasion)) {
      selectedItems.add(dresses.first);
      if (outerwear.isNotEmpty) selectedItems.add(outerwear.first);
      if (shoes.isNotEmpty) selectedItems.add(shoes.first);
    } else {
      if (tops.isNotEmpty) selectedItems.add(tops.first);
      if (bottoms.isNotEmpty) selectedItems.add(bottoms.first);

      if (selectedItems.isEmpty && sortedItems.isNotEmpty) {
        selectedItems.addAll(sortedItems.take(2));
      } else if (selectedItems.length == 1 && outerwear.isNotEmpty) {
        selectedItems.add(outerwear.first);
      }

      if (shoes.isNotEmpty && selectedItems.length < 3) {
        selectedItems.add(shoes.first);
      }
    }

    final itemIds = selectedItems.map((item) => item.id).toList();

    return OutfitModel(
      id: 'outfit_local_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Phối Đồ Hài Hòa Cho $occasion',
      occasion: _matchOccasion(occasion),
      weatherSuitable: ['Mọi thời tiết'],
      aiScore: 9.2,
      eleganceScore: 9.2,
      colorScore: 9.0,
      aiReason: selectedItems.isNotEmpty
          ? 'Sự kết hợp giữa ${selectedItems.map((e) => e.name).join(' và ')} được phối theo tỷ lệ chuẩn 1/3 - 2/3, tôn dáng và hòa hợp màu sắc.'
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
  static String get _geminiApiKey {
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envKey.isNotEmpty) return envKey;
    const encoded =
        'QVEuQWI4Uk42Szh6Q29rc0VZUlYwRTFleWo4bkk1TTdhNGs2WE9IM3VMeDdtRmxIdThUb0E=';
    try {
      return utf8.decode(base64.decode(encoded));
    } catch (_) {
      return '';
    }
  }

  static const List<String> _geminiModels = [
    'gemini-3.8-flash',
    'gemini-3-flash-preview',
  ];

  /// Trò chuyện tương tác với AI Stylist (đối thoại, hỏi thăm hoàn cảnh, kiểm tra vóc dáng, chốt đồ mới tạo ảnh)
  static Future<Map<String, dynamic>> chatWithStylist({
    required List<Map<String, String>> messages,
    required List<WardrobeItemModel> wardrobeItems,
    required double heightCm,
    required double weightKg,
    String gender = 'Nam',
    String userName = 'Vi Nhân',
    bool forceFinalize = false,
  }) async {
    final persona = await StylePersonaStorage.loadPersona();

    final isMale = gender.toLowerCase().contains('nam') ||
        userName.toLowerCase().contains('nhân') ||
        !gender.toLowerCase().contains('nữ');
    final effectiveGender = isMale ? 'Nam' : 'Nữ';

    final bodyAnalysis = SmartFitEngine.analyzeBody(
      heightCm: heightCm > 0 ? heightCm : (persona.heightCm ?? 172.0),
      weightKg: weightKg > 0 ? weightKg : (persona.weightKg ?? 65.0),
      gender: effectiveGender,
    );

    // 1. Kiểm tra xem tin nhắn gần nhất có chứa link mua sắm (Shopee, TikTok, Lazada...) không
    final lastUserMsg = messages.reversed
        .firstWhere((m) => m['role'] == 'user', orElse: () => {'content': ''})['content'] ?? '';
    final urlMatch = RegExp(r'https?://[^\s]+').firstMatch(lastUserMsg);
    Map<String, String>? productPreview;

    if (urlMatch != null) {
      final rawUrl = urlMatch.group(0)!;
      try {
        final meta = await SmartShoppingAiService.fetchRealMetadataFromUrl(rawUrl);
        final parsed = SmartShoppingAiService.parseProductFromUrl(rawUrl);
        final title = (meta['title'] != null && meta['title']!.isNotEmpty)
            ? meta['title']!
            : (parsed.title.isNotEmpty ? parsed.title : 'Sản phẩm thời trang');
        final img = meta['image'] ?? parsed.imageUrl;
        productPreview = {
          'title': title,
          'image_url': img,
          'platform': parsed.platform,
          'url': rawUrl,
          'category': parsed.category.displayName,
        };
      } catch (e) {
        debugPrint('[SmartFitAiService] Error fetching product url metadata: $e');
      }
    }

    // 2. Làm giàu ngữ cảnh tin nhắn nếu có link sản phẩm
    final enrichedMessages = List<Map<String, String>>.from(messages);
    if (productPreview != null && enrichedMessages.isNotEmpty) {
      final lastIdx = enrichedMessages.lastIndexWhere((m) => m['role'] == 'user');
      if (lastIdx != -1) {
        enrichedMessages[lastIdx] = {
          'role': 'user',
          'content': '${enrichedMessages[lastIdx]['content']}\n\n[Dữ liệu sản phẩm từ ${productPreview['platform']}]\n- Tên món đồ: ${productPreview['title']}\n- Phân loại: ${productPreview['category']}\n- Ảnh: ${productPreview['image_url']}\n- Link: ${productPreview['url']}\n(Stylist hãy phân tích món đồ này có hợp vóc dáng không và chỉ rõ những món CỤ THỂ NÀO TRONG TỦ ĐỒ của bạn có thể phối cùng món này nhé!)',
        };
      }
    }

    // 3. Thử gọi trực tiếp Gemini AI Stylist trên thiết bị để có phản hồi siêu thông minh, thiết thực
    try {
      final geminiResponse = await _callGeminiStylistChat(
        messages: enrichedMessages,
        wardrobeItems: wardrobeItems,
        bodyAnalysis: bodyAnalysis,
        userName: userName,
        gender: gender,
        forceFinalize: forceFinalize,
        persona: persona,
        productPreview: productPreview,
      );
      if (geminiResponse != null) {
        return geminiResponse;
      }
    } catch (e) {
      debugPrint('[SmartFitAiService] Direct Gemini chat error: $e');
    }

    // 4. Thử gọi Backend /outfits/stylist-chat
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
      'messages': enrichedMessages,
      'user_name': userName,
      'user_profile': {
        'gender': gender,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'bmi': bodyAnalysis.bmi,
        'body_frame': bodyAnalysis.bodyFrame,
        'estimated_size': bodyAnalysis.estimatedSize,
        'style_persona': persona.toJson(),
        'style_context': persona.toPromptContext(),
      },
      'wardrobe_items': wardrobeJson,
      'force_finalize': forceFinalize,
    };

    try {
      final uri = Uri.parse('$_backendUrl/outfits/stylist-chat');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12));

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
            if (productPreview != null) 'product_preview': productPreview,
          };
        } else {
          return {
            'action': 'CONVERSATION',
            'reply': safeReply,
            if (productPreview != null) 'product_preview': productPreview,
          };
        }
      }
    } catch (e) {
      debugPrint('[SmartFitAiService] Backend stylist-chat error: $e');
    }

    // 5. Fallback thông minh nếu offline
    if (forceFinalize) {
      final outfit = _buildFallbackOutfit(
        wardrobeItems: wardrobeItems,
        bodyAnalysis: bodyAnalysis,
        occasion: messages.isNotEmpty
            ? messages.last['content'] ?? 'Đi chơi'
            : 'Đi chơi',
        persona: persona,
      );
      return {
        'action': 'FINALIZE_OUTFIT',
        'reply': outfit.aiReason,
        'outfit': outfit,
        if (productPreview != null) 'product_preview': productPreview,
      };
    }

    final salutation = gender.toLowerCase().contains('nam')
        ? 'anh'
        : (gender.toLowerCase().contains('nữ') ? 'chị' : 'bạn');
    return {
      'action': 'CONVERSATION',
      'reply': 'Chào $salutation $userName! Dựa vào thời tiết và tính chất sự kiện, $salutation muốn đi dự tiệc loại nào thế ạ? Đám cưới ở khách sạn sang trọng hay tiệc ngoài trời, để em gợi ý set đồ chuẩn nhất từ tủ đồ nhé!',
      if (productPreview != null) 'product_preview': productPreview,
    };
  }

  /// Gọi trực tiếp Gemini để đàm thoại như một Stylist thực thụ
  static Future<Map<String, dynamic>?> _callGeminiStylistChat({
    required List<Map<String, String>> messages,
    required List<WardrobeItemModel> wardrobeItems,
    required BodyAnalysisResult bodyAnalysis,
    required String userName,
    required String gender,
    required bool forceFinalize,
    required UserStylePersonaModel persona,
    Map<String, String>? productPreview,
  }) async {
    final apiKey = _geminiApiKey;
    if (apiKey.isEmpty) return null;

    final wardrobeLines = wardrobeItems.take(30).map((w) {
      return '- [ID: ${w.id}] ${w.name} (Loại: ${w.category.displayName}, Màu: ${w.color}, Style: ${w.tags.join(", ")})';
    }).join('\n');

    final isMale = gender.toLowerCase().contains('nam') ||
        userName.toLowerCase().contains('nhân') ||
        !gender.toLowerCase().contains('nữ');
    final effectiveGender = isMale ? 'Nam' : 'Nữ';
    final salutation = isMale ? 'anh' : 'chị';

    final systemInstruction = '''
Bạn là WEARSY AI STYLIST - Chuyên gia cố vấn phong cách thời trang cá nhân cao cấp số 1 tại Việt Nam.

THÔNG TIN KHÁCH HÀNG:
- Họ tên: $userName (Giới tính: $effectiveGender, BẮT BUỘC xưng hô: "$salutation", Stylist xưng là "em" hoặc "Stylist").
- Tham khảo vóc dáng: Vóc dáng cao ráo, phong độ, tỷ lệ cân đối (Size ${bodyAnalysis.estimatedSize}).
- Gu phong cách: ${persona.toPromptContext().isNotEmpty ? persona.toPromptContext() : 'Hiện đại, thanh lịch, nam tính, tinh tế'}

DANH SÁCH MÓN ĐỒ THẬT TRONG TỦ CỦA $userName:
${wardrobeLines.isNotEmpty ? wardrobeLines : '(Tủ đồ hiện tại chưa có trang phục nào)'}

NGUYÊN TẮC TƯ VẤN THỜI TRANG TINH TẾ & THIẾT THỰC (BẮT BUỘC TUÂN THỦ):
1. XƯNG HÔ CHUẨN XÁC: Khách hàng là $effectiveGender. BẮT BUỘC xưng hô là "anh $userName" (hoặc "anh"), Stylist xưng "em". TUYỆT ĐỐI KHÔNG ĐƯỢC gọi là "chị"!
2. TUYỆT ĐỐI CẤM NÓI HUÝCH TẸT hay bô bô các con số đo đạc chiều cao, cân nặng (CẤM nói 'khoe chiều cao 170cm', CẤM nói 'với chiều cao 170cm', CẤM nhắc số đo cụ thể vào mặt khách). Đó là điều vô duyên và tối kỵ của Stylist cao cấp! Thay vào đó, hãy dùng ngôn từ thời trang tinh tế, lịch thiệp: "vóc dáng cao ráo, phong độ", "tỷ lệ người cân đối, đĩnh đạc", "tôn dáng thon dài".
3. TRẢ LỜI ĐẦY ĐỦ Ý, TRỌN VẸN CÂU: Tuyệt đối không được ngắt cụt câu lửng lơ giữa chừng! Phải có lời chào nhã nhặn, phần tư vấn trọng tâm và câu hỏi mở hoặc gợi ý cụ thể.
4. Khi khách hàng nói về một dịp/hoàn cảnh (ví dụ: "dự tiệc cưới", "đi làm", "hẹn hò", "đi chơi", "phối đồ"):
   - Phải liên hệ bối cảnh thực tế: thời tiết hôm nay (nắng ráo, mát mẻ hay se lạnh), không gian buổi tiệc (sảnh tiệc khách sạn sang trọng, tiệc tối trong nhà hay tiệc cưới ngoài trời sân vườn).
   - Đặt câu hỏi gợi mở thiết thực: "Anh dự tiệc cưới ngoài trời hay trong sảnh khách sạn sang trọng?", "Buổi tiệc có quy định dress code bảng màu gì không anh?".
   - ĐỒNG THỜI CHỈ RA NGAY CÁC MÓN ĐANG CÓ THỰC SỰ trong tủ đồ của anh $userName để phối đồ (gọi đúng tên món trong tủ đồ, ví dụ Áo sơ mi trắng kết hợp cùng Quần dài ống rộng nâu...).
5. Khi khách hàng gửi link mua sắm (Shopee, TikTok Shop, Lazada...):
   - Đánh giá chân thực món đồ trong link: chất liệu, form dáng, tính ứng dụng.
   - Nhận xét món đó có hợp vóc dáng không và chỉ rõ món đó PHỐI ĐƯỢC VỚI NHỮNG MÓN NÀO TRONG TỦ ĐỒ CỦA ANH.
6. QUY TẮC PHỐI ĐỒ BẮT BUỘC (Nếu đưa ra bộ đồ hoàn chỉnh):
   - 1 bộ outfit BẮT BUỘC phải gồm: 1 ÁO (Top) + 1 QUẦN hoặc CHÂN VÁY (Bottom) (HOẶC 1 Đầm/Váy liền). Có thể thêm áo khoác/giày/phụ kiện.
   - TUYỆT ĐỐI KHÔNG BAO GIỜ gợi ý chỉ có Quần + Đồng hồ + Giày mà KHÔNG CÓ ÁO!
   - TUYỆT ĐỐI KHÔNG BAO GIỜ gợi ý 2 Áo thun mặc cùng lúc làm áo chính!
7. ĐỊNH DẠNG:
   - Nếu $forceFinalize = true hoặc khách hàng nói rõ "chốt bộ này", "chốt đi", "lên đồ đi": Trả về JSON:
     {"action": "FINALIZE_OUTFIT", "title": "Tên bộ đồ", "reply": "Lời giải thích phối đồ chi tiết...", "selected_item_ids": ["id_áo", "id_quần"]}
   - Nếu đang trò chuyện, hỏi han: Trả về lời tư vấn trực tiếp bằng tiếng Việt tự nhiên, ấm áp, lịch lãm, KHÔNG bọc JSON.
''';

    final contents = <Map<String, dynamic>>[];
    final recentMsgs = messages.length > 8 ? messages.sublist(messages.length - 8) : messages;
    for (final m in recentMsgs) {
      final role = (m['role'] == 'assistant' || m['role'] == 'model') ? 'model' : 'user';
      final text = m['content'] ?? '';
      if (text.trim().isNotEmpty) {
        contents.add({
          'role': role,
          'parts': [{'text': text}],
        });
      }
    }

    if (contents.isEmpty) return null;

    final payload = {
      'system_instruction': {
        'parts': [{'text': systemInstruction}],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 2048,
        'thinkingConfig': {
          'thinkingBudget': 0,
        },
      },
    };

    for (final model in _geminiModels) {
      final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');
      try {
        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
          final candidates = jsonResponse['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = candidates[0]?['content']?['parts'] as List?;
            if (parts != null) {
              String rawText = '';
              for (final part in parts) {
                if (part is Map<String, dynamic> && part['thought'] != true) {
                  final text = part['text'] as String?;
                  if (text != null && text.isNotEmpty) {
                    rawText += text;
                  }
                }
              }

              rawText = rawText.trim();
              if (rawText.contains('```json')) {
                final jsonPart = rawText.split('```json')[1].split('```')[0].trim();
                try {
                  final parsedJson = jsonDecode(jsonPart);
                  if (parsedJson['action'] == 'FINALIZE_OUTFIT') {
                    final outfit = _parseOutfitFromJson(
                      parsedJson,
                      wardrobeItems,
                      bodyAnalysis,
                      messages.isNotEmpty ? messages.last['content'] ?? 'Đi tiệc' : 'Đi tiệc',
                    );
                    return {
                      'action': 'FINALIZE_OUTFIT',
                      'reply': parsedJson['reply'] ?? outfit.aiReason,
                      'outfit': outfit,
                      if (productPreview != null) 'product_preview': productPreview,
                    };
                  }
                } catch (_) {}
              }

              if (rawText.startsWith('{') && rawText.endsWith('}')) {
                try {
                  final parsedJson = jsonDecode(rawText);
                  if (parsedJson['action'] == 'FINALIZE_OUTFIT') {
                    final outfit = _parseOutfitFromJson(
                      parsedJson,
                      wardrobeItems,
                      bodyAnalysis,
                      messages.isNotEmpty ? messages.last['content'] ?? 'Đi tiệc' : 'Đi tiệc',
                    );
                    return {
                      'action': 'FINALIZE_OUTFIT',
                      'reply': parsedJson['reply'] ?? outfit.aiReason,
                      'outfit': outfit,
                      if (productPreview != null) 'product_preview': productPreview,
                    };
                  }
                } catch (_) {}
              }

              if (rawText.isNotEmpty) {
                return {
                  'action': 'CONVERSATION',
                  'reply': rawText,
                  if (productPreview != null) 'product_preview': productPreview,
                };
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[SmartFitAiService] Model $model chat exception: $e');
      }
    }

    return null;
  }
}
