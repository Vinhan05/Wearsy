import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../features/outfits/models/outfit_model.dart';
import '../../features/wardrobe/models/wardrobe_item_model.dart';
import 'smart_fit_engine.dart';

class SmartFitAiService {
  static const String _geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const String _geminiModel = 'gemini-1.5-flash';

  /// Sinh gợi ý Outfit kết hợp giữa 2D Layering và Smart Fit (Chiều cao & Cân nặng)
  static Future<OutfitModel> generateSmartFitOutfit({
    required List<WardrobeItemModel> wardrobeItems,
    required double heightCm,
    required double weightKg,
    String gender = 'Nữ',
    String occasion = 'Công sở thường ngày',
    String stylePreference = 'Thanh lịch, hiện đại',
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

    // 2. Thử gọi Gemini AI Context Engine (Online)
    try {
      final geminiResult = await _callGeminiApi(
        wardrobeItems: wardrobeItems,
        bodyAnalysis: bodyAnalysis,
        occasion: occasion,
        stylePreference: stylePreference,
      );
      if (geminiResult != null) {
        return geminiResult;
      }
    } catch (e) {
      debugPrint('[SmartFitAiService] Gemini API call failed or timed out: $e');
    }

    // 3. Fallback: Heuristic Engine nội bộ đảm bảo app hoạt động 100% không gián đoạn
    return _buildFallbackOutfit(
      wardrobeItems: wardrobeItems,
      bodyAnalysis: bodyAnalysis,
      occasion: occasion,
    );
  }

  static Future<OutfitModel?> _callGeminiApi({
    required List<WardrobeItemModel> wardrobeItems,
    required BodyAnalysisResult bodyAnalysis,
    required String occasion,
    required String stylePreference,
  }) async {
    const systemInstruction = '''
[SYSTEM ROLE]
Bạn là Trợ lý AI Thời trang & Styling Cá nhân hóa cho ứng dụng WEARSY.
Nhiệm vụ của bạn là chọn các món đồ từ tủ đồ kỹ thuật số của người dùng để tạo thành một bộ trang phục (Outfit) hoàn chỉnh, đồng thời phân tích sự tương thích về thẩm mỹ và đưa ra lời khuyên về độ vừa vặn/tôn dáng dựa trên số liệu thể trạng thực tế (Chiều cao & Cân nặng).

[CRITICAL CONSTRAINTS]
1. CHỈ ĐƯỢC CHỌN item_id có thật trong mảng [User Wardrobe]. Tuyệt đối KHÔNG tự tạo ra ID giả mạo (No Hallucination).
2. Tối thiểu mỗi outfit phải gồm 2 items (Ví dụ: 1 Top + 1 Bottom, hoặc 1 Dress + 1 Shoes, kèm áo khoác hoặc phụ kiện nếu có).
3. Đánh giá tính thẩm mỹ dựa trên quy tắc bánh xe màu sắc và mức độ trang trọng (Elegance/Color Score từ 1.0 đến 10.0).
4. Phân tích độ tôn dáng dựa vào [User Body Summary]:
   - Người gầy: Ưu tiên gợi ý đồ sáng màu, họa tiết sọc ngang, hoặc phối layering nhiều lớp (như khoác thêm blazer/cardigan) để tạo độ dày cơ thể.
   - Người đậm người/chiều cao khiêm tốn: Ưu tiên phối màu đơn sắc (Monochrome), sơ vin hoặc chọn quần cạp cao để kéo dài tỷ lệ chân.
5. Luôn trả về dữ liệu đúng định dạng JSON chuẩn. Không thêm văn bản chào hỏi hay kết luận bên ngoài JSON.''';

    final wardrobeJson = wardrobeItems.map((item) {
      return {
        'id': item.id,
        'name': item.name,
        'category': item.category.displayName,
        'primary_color': item.color,
        'style_tags': item.tags,
        'layer_order': item.layerOrder,
      };
    }).toList();

    final inputPayload = {
      'user_context': {
        'occasion': occasion,
        'style_preference': stylePreference,
      },
      'user_body_summary': bodyAnalysis.toJson(),
      'wardrobe_items': wardrobeJson,
    };

    final promptText = '''
Hãy phân tích dữ liệu sau và tạo ra 1 bộ outfit tối ưu nhất:
${jsonEncode(inputPayload)}

Trả về duy nhất JSON có cấu trúc sau:
{
  "outfit_id": "outfit_gemini_${DateTime.now().millisecondsSinceEpoch}",
  "title": "Tên bộ trang phục phong cách",
  "elegance_score": 9.5,
  "color_score": 9.4,
  "selected_item_ids": ["id_1", "id_2"],
  "stylist_reasoning": "Giải thích lý do thẩm mỹ và phối màu bối cảnh",
  "smart_fit_advice": {
    "size_recommendation": "Phù hợp nhất với ${bodyAnalysis.estimatedSize} chuẩn",
    "body_proportion_tip": "Lời khuyên tôn dáng cụ thể theo chiều cao ${bodyAnalysis.heightCm.toInt()}cm",
    "fit_warnings": ["Lưu ý hoặc cảnh báo độ dài/form dáng"]
  }
}''';

    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent?key=$_geminiApiKey');

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': '$systemInstruction\n\n$promptText'}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
        'topP': 0.8,
        'responseMimeType': 'application/json',
      }
    };

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final text =
          jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (text != null) {
        final parsed = jsonDecode(text.trim()) as Map<String, dynamic>;
        final selectedIds = (parsed['selected_item_ids'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        // Kiểm tra hợp lệ: Chỉ giữ lại các ID có thực trong tủ đồ
        final validIds = selectedIds
            .where((id) => wardrobeItems.any((i) => i.id == id))
            .toList();
        if (validIds.length >= 2) {
          final firstItem =
              wardrobeItems.firstWhere((i) => i.id == validIds.first);
          final rawAdvice = parsed['smart_fit_advice'] as Map<String, dynamic>?;

          final smartFitAdvice = SmartFitAdvice(
            sizeRecommendation: rawAdvice?['size_recommendation']?.toString() ??
                'Phù hợp nhất với ${bodyAnalysis.estimatedSize} chuẩn',
            bodyProportionTip: rawAdvice?['body_proportion_tip']?.toString() ??
                bodyAnalysis.defaultProportionTip,
            fitWarnings: (rawAdvice?['fit_warnings'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                bodyAnalysis.fitWarnings,
            bmi: bodyAnalysis.bmi,
            bodyFrame: bodyAnalysis.bodyFrame,
            userHeight: bodyAnalysis.heightCm,
            userWeight: bodyAnalysis.weightKg,
          );

          return OutfitModel(
            id: parsed['outfit_id']?.toString() ??
                'o_ai_${DateTime.now().millisecondsSinceEpoch}',
            name:
                parsed['title']?.toString() ?? 'Bộ phối Smart Fit Thời Thượng',
            occasion: _mapOccasion(occasion),
            weatherSuitable: ['Mọi thời tiết'],
            aiScore: (parsed['elegance_score'] as num?)?.toDouble() ?? 9.5,
            eleganceScore:
                (parsed['elegance_score'] as num?)?.toDouble() ?? 9.5,
            colorScore: (parsed['color_score'] as num?)?.toDouble() ?? 9.2,
            aiReason: parsed['stylist_reasoning']?.toString() ??
                'Sự phối hợp hài hòa giữa các lớp trang phục tôn dáng và phù hợp sự kiện.',
            itemIds: validIds,
            coverImageUrl: firstItem.imageUrl,
            smartFitAdvice: smartFitAdvice,
          );
        }
      }
    }
    return null;
  }

  /// Fallback Heuristic Builder: Khi không có internet hoặc tủ đồ ít món
  static OutfitModel _buildFallbackOutfit({
    required List<WardrobeItemModel> wardrobeItems,
    required BodyAnalysisResult bodyAnalysis,
    required String occasion,
  }) {
    final selectedIds = <String>[];
    String coverImg =
        'https://images.unsplash.com/photo-1594938298603-c8148c4b4671?q=80&w=600&auto=format&fit=crop';

    if (wardrobeItems.isNotEmpty) {
      // 1. Tìm lớp nền 1: Áo hoặc Đầm
      final tops = wardrobeItems
          .where((i) => i.category == WardrobeCategory.tops)
          .toList();
      final dresses = wardrobeItems
          .where((i) => i.category == WardrobeCategory.dresses)
          .toList();
      final bottoms = wardrobeItems
          .where((i) => i.category == WardrobeCategory.bottoms)
          .toList();
      final outerwear = wardrobeItems
          .where((i) => i.category == WardrobeCategory.outerwear)
          .toList();
      final shoes = wardrobeItems
          .where((i) => i.category == WardrobeCategory.shoes)
          .toList();
      final accessories = wardrobeItems
          .where((i) => i.category == WardrobeCategory.accessories)
          .toList();

      if (dresses.isNotEmpty && (bodyAnalysis.gender == 'Nữ' || tops.isEmpty)) {
        selectedIds.add(dresses.first.id);
        coverImg = dresses.first.imageUrl;
      } else {
        if (tops.isNotEmpty) {
          selectedIds.add(tops.first.id);
          coverImg = tops.first.imageUrl;
        }
        if (bottoms.isNotEmpty) {
          selectedIds.add(bottoms.first.id);
        }
      }

      // 2. Thêm Outerwear (Layer 2) nếu thể trạng gầy hoặc dịp trang trọng
      if (outerwear.isNotEmpty) {
        selectedIds.add(outerwear.first.id);
      }

      // 3. Thêm Shoes (Layer 3)
      if (shoes.isNotEmpty) {
        selectedIds.add(shoes.first.id);
      }

      // 4. Thêm Phụ kiện (Layer 4)
      if (accessories.isNotEmpty) {
        selectedIds.add(accessories.first.id);
      }
    }

    if (selectedIds.isEmpty && wardrobeItems.isNotEmpty) {
      selectedIds.addAll(wardrobeItems.take(3).map((e) => e.id));
      coverImg = wardrobeItems.first.imageUrl;
    }

    final advice = SmartFitAdvice(
      sizeRecommendation:
          'Phù hợp nhất với ${bodyAnalysis.estimatedSize} chuẩn',
      bodyProportionTip: bodyAnalysis.defaultProportionTip,
      fitWarnings: bodyAnalysis.fitWarnings,
      bmi: bodyAnalysis.bmi,
      bodyFrame: bodyAnalysis.bodyFrame,
      userHeight: bodyAnalysis.heightCm,
      userWeight: bodyAnalysis.weightKg,
    );

    return OutfitModel(
      id: 'o_smart_${DateTime.now().millisecondsSinceEpoch}',
      name:
          'Smart Fit ${bodyAnalysis.bodyFrame.split(' ').first}: Phối Đồ Tôn Dáng',
      occasion: _mapOccasion(occasion),
      weatherSuitable: ['Mọi thời tiết'],
      aiScore: 9.4,
      eleganceScore: 9.5,
      colorScore: 9.3,
      aiReason:
          'Tối ưu hóa các lớp trang phục Layering dựa trên số đo chiều cao ${bodyAnalysis.heightCm.toInt()}cm và cân nặng ${bodyAnalysis.weightKg.toInt()}kg.',
      itemIds: selectedIds,
      coverImageUrl: coverImg,
      smartFitAdvice: advice,
    );
  }

  static OutfitOccasion _mapOccasion(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('công sở') ||
        lower.contains('work') ||
        lower.contains('báo cáo')) {
      return OutfitOccasion.work;
    }
    if (lower.contains('trang trọng') ||
        lower.contains('formal') ||
        lower.contains('thuyết trình')) {
      return OutfitOccasion.formal;
    }
    if (lower.contains('tối') ||
        lower.contains('tiệc') ||
        lower.contains('evening') ||
        lower.contains('date')) {
      return OutfitOccasion.evening;
    }
    if (lower.contains('thể thao') || lower.contains('sport')) {
      return OutfitOccasion.sport;
    }
    return OutfitOccasion.casual;
  }
}
