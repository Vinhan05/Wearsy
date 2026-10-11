import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/local_bg_removal_service.dart';
import '../../../core/storage/token_storage.dart';
import '../models/wardrobe_item_model.dart';

class WardrobeService {
  final ApiClient _apiClient = ApiClient();

  /// Tải toàn bộ danh sách trang phục từ PostgreSQL Server Database
  Future<List<WardrobeItemModel>> getWardrobeItems({String? email}) async {
    final userEmail = email ?? (await TokenStorage.getUserEmail()) ?? '';
    final cleanEmail = userEmail.trim().toLowerCase();

    try {
      final response = await _apiClient.get(
        ApiConstants.wardrobeItems,
        queryParameters: {'email': cleanEmail},
      );

      if (response is List) {
        return response
            .map((item) =>
                WardrobeItemModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[WardrobeService] Lỗi khi tải trang phục từ Server DB: $e');
    }
    return [];
  }

  /// Lưu món đồ mới vào PostgreSQL Server Database
  Future<WardrobeItemModel?> createItem(
    WardrobeItemModel item, {
    String? email,
  }) async {
    final userEmail = email ?? (await TokenStorage.getUserEmail()) ?? '';
    final cleanEmail = userEmail.trim().toLowerCase();

    try {
      final body = item.toJson();
      body['email'] = cleanEmail;

      final response = await _apiClient.post(
        ApiConstants.wardrobeItems,
        body: body,
      );

      if (response is Map<String, dynamic>) {
        return WardrobeItemModel.fromJson(response);
      }
    } catch (e) {
      debugPrint('[WardrobeService] Lỗi khi tạo món đồ trên Server DB: $e');
    }
    return null;
  }

  /// Cập nhật món đồ trên PostgreSQL Server Database
  Future<bool> updateItem(WardrobeItemModel item) async {
    try {
      await _apiClient.put(
        '${ApiConstants.wardrobeItems}/${item.id}',
        body: item.toJson(),
      );
      return true;
    } catch (e) {
      debugPrint(
          '[WardrobeService] Lỗi khi cập nhật món đồ trên Server DB: $e');
      return false;
    }
  }

  /// Xóa món đồ khỏi PostgreSQL Server Database
  Future<bool> deleteItem(String itemId) async {
    try {
      await _apiClient.delete('${ApiConstants.wardrobeItems}/$itemId');
      return true;
    } catch (e) {
      debugPrint('[WardrobeService] Lỗi khi xóa món đồ trên Server DB: $e');
      return false;
    }
  }

  /// Xóa toàn bộ trang phục của người dùng trên PostgreSQL Server Database
  Future<bool> clearAllItems({String? email}) async {
    final userEmail = email ?? (await TokenStorage.getUserEmail()) ?? '';
    final cleanEmail = userEmail.trim().toLowerCase();

    try {
      await _apiClient.delete(
        ApiConstants.wardrobeItems,
        queryParameters: {'email': cleanEmail},
      );
      return true;
    } catch (e) {
      debugPrint(
          '[WardrobeService] Lỗi khi reset toàn bộ tủ đồ trên Server DB: $e');
      return false;
    }
  }

  /// Xử lý tách phông nền AI từ URL hình ảnh
  Future<String?> removeBackgroundFromUrl(String imageUrl) async {
    try {
      if (imageUrl.contains('e_background_removal') ||
          (imageUrl.endsWith('.png') && imageUrl.contains('cloudinary'))) {
        return imageUrl;
      }
      final res = await _apiClient.post(
        ApiConstants.removeBackground,
        body: {'image_url': imageUrl},
      );
      if (res is Map<String, dynamic> && res['bg_removed_url'] != null) {
        return res['bg_removed_url'].toString();
      }
    } catch (e) {
      debugPrint('[WardrobeService] Lỗi khi tách nền từ URL qua API: $e');
    }
    return imageUrl;
  }

  /// Tải ảnh tệp cục bộ và tự động bóc tách phông nền bằng AI Deep Learning
  Future<String?> uploadImageWithBgRemoval(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      // 1. Tải lên máy chủ WEARSY để tách nền chuẩn xác bằng deep learning AI
      try {
        final res =
            await _apiClient.postMultipart('/wardrobe/analyze-image', file);
        if (res is Map<String, dynamic> && res['bg_removed_url'] != null) {
          final url = res['bg_removed_url'].toString();
          if (url.isNotEmpty) return url;
        }
      } catch (e) {
        debugPrint('[WardrobeService] Upload tách nền qua server gặp lỗi: $e');
      }

      // 2. Fallback sang client-side image processing nếu offline
      return await LocalBgRemovalService.processImage(filePath);
    } catch (e) {
      debugPrint('[WardrobeService] Lỗi khi tách nền ảnh cục bộ: $e');
    }
    return null;
  }

  /// Tân trang trang phục bằng AI (Premium Studio Lookbook)
  Future<Map<String, dynamic>?> enhanceGarment({
    required String imageUrl,
    String? name,
    String? category,
    String? color,
  }) async {
    try {
      String? imageBase64;
      String finalImageUrl = imageUrl;

      // Nếu là ảnh cục bộ trên điện thoại (chụp/chọn từ thư viện), chuyển sang Base64
      if (!imageUrl.startsWith('http://') &&
          !imageUrl.startsWith('https://') &&
          !imageUrl.startsWith('data:')) {
        try {
          final file = File(imageUrl);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            imageBase64 = 'data:image/png;base64,${base64Encode(bytes)}';
          }
        } catch (e) {
          debugPrint('[WardrobeService] Lỗi đọc file cục bộ sang base64: $e');
        }
      }

      final res = await _apiClient.post(
        '/wardrobe/enhance-garment',
        body: {
          'image_url': finalImageUrl,
          'image_base64': imageBase64,
          'name': name ?? 'Trang phục',
          'category': category ?? 'Khác',
          'color': color ?? 'Đa sắc',
        },
      );
      if (res is Map<String, dynamic>) {
        return res;
      }
    } catch (e) {
      debugPrint('[WardrobeService] Lỗi khi tân trang trang phục bằng AI: $e');
    }
    return null;
  }
}
