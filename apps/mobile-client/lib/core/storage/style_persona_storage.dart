import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/user_style_persona_model.dart';
import 'token_storage.dart';

/// Dịch vụ quản lý file cục bộ lưu trữ "Phong cách, sở thích, thói quen phối đồ" của người dùng.
/// File được lưu trực tiếp vào thư mục data của ứng dụng trên thiết bị (ApplicationDocumentsDirectory).
/// Phục vụ cho tính năng Cá nhân hóa AI (On-Device Personalization Memory & Context Injection).
/// Kết hợp cơ chế Đồng bộ ngầm (Background Cloud Sync) lên PostgreSQL Database.
class StylePersonaStorage {
  static const String _fileName = 'user_style_persona.json';
  static const String _prefBackupKey = 'wearsy_style_persona_cache';

  static UserStylePersonaModel? _cachedPersona;

  /// Lấy đường dẫn file cục bộ trong thư mục data của app trên thiết bị
  static Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  /// Tải thông tin phong cách người dùng từ file data trên máy
  static Future<UserStylePersonaModel> loadPersona() async {
    if (_cachedPersona != null) {
      return _cachedPersona!;
    }

    try {
      final file = await _getLocalFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final jsonMap = jsonDecode(content) as Map<String, dynamic>;
          _cachedPersona = UserStylePersonaModel.fromJson(jsonMap);
          return _cachedPersona!;
        }
      }
    } catch (e) {
      debugPrint('[StylePersonaStorage] Error reading local file: $e');
    }

    // Dự phòng qua SharedPreferences nếu đọc file gặp sự cố
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupStr = prefs.getString(_prefBackupKey);
      if (backupStr != null && backupStr.isNotEmpty) {
        final jsonMap = jsonDecode(backupStr) as Map<String, dynamic>;
        _cachedPersona = UserStylePersonaModel.fromJson(jsonMap);
        return _cachedPersona!;
      }
    } catch (_) {}

    // Lấy thông tin user hiện tại nếu là lần đầu tiên khởi tạo
    final email = await TokenStorage.getUserEmail() ?? 'local_user';
    final initialPersona = UserStylePersonaModel(userId: email);
    await savePersona(initialPersona);
    return initialPersona;
  }

  /// Lưu đối tượng Style Persona vào file JSON cục bộ VÀ đồng bộ ngầm lên Cloud
  static Future<void> savePersona(UserStylePersonaModel persona) async {
    _cachedPersona = persona;

    final jsonStr =
        const JsonEncoder.withIndent('  ').convert(persona.toJson());

    // 1. Ghi vào file trong bộ nhớ data của app (Bản chạy chính Local Storage)
    try {
      final file = await _getLocalFile();
      await file.writeAsString(jsonStr, flush: true);
      debugPrint('[StylePersonaStorage] Saved persona to file: ${file.path}');
    } catch (e) {
      debugPrint('[StylePersonaStorage] Failed to write to local file: $e');
    }

    // 2. Ghi một bản sao dự phòng vào SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefBackupKey, jsonStr);
    } catch (_) {}

    // 3. Đồng bộ ngầm lên PostgreSQL Cloud Database (Không làm gián đoạn UI)
    _syncToCloudSilently(persona);
  }

  /// Đồng bộ hồ sơ phong cách lên Cloud Database chạy ngầm trong nền
  static void _syncToCloudSilently(UserStylePersonaModel persona) async {
    try {
      final email = await TokenStorage.getUserEmail();
      if (email == null || email.trim().isEmpty) return;

      final url = Uri.parse('${ApiConstants.baseUrl}/users/sync-profile');
      final token = await TokenStorage.getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final payload = {
        'email': email.trim().toLowerCase(),
        'preferred_styles': persona.primaryStyles,
        'color_preferences': {
          'favorite': persona.favoriteColors,
          'avoided': persona.avoidedColors,
        },
        'budget_range': {'tier': 'medium'},
        'body_measurements': {
          'gender': persona.gender,
          'height_cm': persona.heightCm,
          'weight_kg': persona.weightKg,
          'bmi': persona.bmi,
          'body_frame': persona.bodyFrame,
          'estimated_size': persona.estimatedSize,
        },
        'ai_learning_data': {
          'liked_outfit_ids': persona.likedOutfitIds,
          'frequent_occasions': persona.frequentOccasions,
          'favorite_combinations': persona.favoriteCombinations,
          'fit_preference': persona.fitPreference,
        },
      };

      final response = await http
          .post(url, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 6));
      debugPrint(
          '[StylePersonaStorage] Background cloud sync response: ${response.statusCode}');
    } catch (e) {
      debugPrint('[StylePersonaStorage] Background cloud sync skipped: $e');
    }
  }

  /// Ghi nhận khi người dùng thích hoặc lưu một Outfit (tự học hỏi thói quen)
  static Future<void> recordLikedOutfit(
    String outfitId, {
    List<String>? occasionTags,
    List<String>? colors,
    Map<String, dynamic>? combination,
  }) async {
    try {
      final current = await loadPersona();
      final updatedLiked = List<String>.from(current.likedOutfitIds);
      if (!updatedLiked.contains(outfitId)) {
        updatedLiked.add(outfitId);
      }

      final updatedCombos =
          List<Map<String, dynamic>>.from(current.favoriteCombinations);
      if (combination != null) {
        updatedCombos.add(combination);
        if (updatedCombos.length > 20) {
          updatedCombos.removeAt(0); // Giữ tối đa 20 combo gần nhất
        }
      }

      final updatedOccasions = List<String>.from(current.frequentOccasions);
      if (occasionTags != null) {
        for (final occ in occasionTags) {
          if (!updatedOccasions.contains(occ)) {
            updatedOccasions.add(occ);
          }
        }
      }

      final updatedPersona = current.copyWith(
        likedOutfitIds: updatedLiked,
        favoriteCombinations: updatedCombos,
        frequentOccasions: updatedOccasions,
      );

      await savePersona(updatedPersona);
    } catch (e) {
      debugPrint('[StylePersonaStorage] Error recording liked outfit: $e');
    }
  }

  /// Đồng bộ từ màn hình Cập nhật Hồ sơ Phong cách (EditStyleProfileScreen)
  static Future<void> syncFromUserProfile({
    List<String>? styles,
    List<String>? favoriteColors,
    List<String>? avoidedColors,
    String? fitPreference,
    List<String>? materials,
    double? heightCm,
    double? weightKg,
    String? gender,
    String? bodyFrame,
  }) async {
    try {
      final current = await loadPersona();
      final updated = current.copyWith(
        primaryStyles: styles ?? current.primaryStyles,
        favoriteColors: favoriteColors ?? current.favoriteColors,
        avoidedColors: avoidedColors ?? current.avoidedColors,
        fitPreference: fitPreference ?? current.fitPreference,
        preferredMaterials: materials ?? current.preferredMaterials,
        heightCm: heightCm ?? current.heightCm,
        weightKg: weightKg ?? current.weightKg,
        gender: gender ?? current.gender,
        bodyFrame: bodyFrame ?? current.bodyFrame,
      );
      await savePersona(updated);
    } catch (e) {
      debugPrint('[StylePersonaStorage] Error syncing from user profile: $e');
    }
  }

  /// Trích xuất chuỗi gợi ý ngữ cảnh thời trang nhúng vào AI
  static Future<String> getAiContextPrompt() async {
    final persona = await loadPersona();
    return persona.toPromptContext();
  }
}
