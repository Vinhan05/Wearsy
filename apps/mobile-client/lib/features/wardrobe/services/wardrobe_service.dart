import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
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

  /// Gửi URL hình ảnh lên server để xóa nền AI và nhận về URL PNG trong suốt
  Future<String?> removeBackgroundFromUrl(String imageUrl) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.removeBackground,
        body: {'image_url': imageUrl},
      );
      if (response is Map<String, dynamic> &&
          response['bg_removed_url'] != null) {
        return response['bg_removed_url'].toString();
      }
    } catch (e) {
      debugPrint('[WardrobeService] Lỗi khi tách nền từ URL: $e');
    }
    return null;
  }

  /// Gửi ảnh tệp cục bộ lên server để Cloudinary AI tách nền và trả về URL PNG trong suốt
  Future<String?> uploadImageWithBgRemoval(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      final response = await _apiClient.postMultipart(
        ApiConstants.uploadWardrobeImage,
        file,
      );
      if (response is Map<String, dynamic> &&
          response['bg_removed_url'] != null) {
        return response['bg_removed_url'].toString();
      }
    } catch (e) {
      debugPrint('[WardrobeService] Lỗi khi upload và tách nền ảnh: $e');
    }
    return null;
  }
}
