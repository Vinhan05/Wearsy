import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/storage/token_storage.dart';
import '../models/wardrobe_collection_model.dart';
import '../models/wardrobe_item_model.dart';
import '../services/wardrobe_service.dart';

class WardrobeProvider with ChangeNotifier {
  final WardrobeService _wardrobeService = WardrobeService();
  List<WardrobeItemModel> _allItems = [];
  List<WardrobeCollectionModel> _collections = [
    WardrobeCollectionModel.defaultWardrobe(),
  ];
  String _activeWardrobeId = 'default';
  WardrobeCategory? _selectedCategory;
  String? _selectedColor;
  String _sortBy = 'default'; // 'default', 'ai_score', 'name'
  bool _isLoading = false;

  /// Danh sách tất cả các tủ đồ của người dùng
  List<WardrobeCollectionModel> get collections => _collections;

  /// ID của tủ đồ đang được chọn hiển thị
  String get activeWardrobeId => _activeWardrobeId;

  /// Thông tin chi tiết của tủ đồ hiện tại
  WardrobeCollectionModel get activeWardrobe {
    return _collections.firstWhere(
      (c) => c.id == _activeWardrobeId,
      orElse: () => _collections.isNotEmpty
          ? _collections.first
          : WardrobeCollectionModel.defaultWardrobe(),
    );
  }

  /// Tất cả các món đồ thuộc tủ đồ hiện tại đang mở
  List<WardrobeItemModel> get allItems {
    return _allItems
        .where((item) =>
            (item.wardrobeId.isEmpty ? 'default' : item.wardrobeId) ==
            _activeWardrobeId)
        .toList();
  }

  /// Toàn bộ món đồ trên toàn bộ tất cả tủ đồ (cho tính năng AI phối tổng thể)
  List<WardrobeItemModel> get allItemsAcrossAllWardrobes => _allItems;

  bool get isLoading => _isLoading;
  WardrobeCategory? get selectedCategory => _selectedCategory;
  String? get selectedColor => _selectedColor;
  String get sortBy => _sortBy;
  bool get hasActiveFilter =>
      _selectedCategory != null || _selectedColor != null || _sortBy != 'default';

  /// Danh sách món đồ trong tủ đồ hiện tại sau khi áp dụng bộ lọc phân loại (Áo, Quần, Màu sắc, Sắp xếp)
  List<WardrobeItemModel> get filteredItems {
    var items = List<WardrobeItemModel>.from(allItems);
    if (_selectedCategory != null) {
      items = items.where((item) => item.category == _selectedCategory).toList();
    }
    if (_selectedColor != null && _selectedColor!.isNotEmpty) {
      items = items
          .where((item) =>
              item.color.toLowerCase().contains(_selectedColor!.toLowerCase()))
          .toList();
    }
    if (_sortBy == 'ai_score') {
      items.sort((a, b) => b.aiMatchScore.compareTo(a.aiMatchScore));
    } else if (_sortBy == 'name') {
      items.sort((a, b) => a.name.compareTo(b.name));
    }
    return items;
  }

  /// Đếm số lượng món đồ theo danh mục trong tủ đồ hiện tại
  Map<WardrobeCategory, int> get itemCountByCategory {
    final counts = <WardrobeCategory, int>{};
    final currentClosetItems = allItems;
    for (final cat in WardrobeCategory.values) {
      counts[cat] = currentClosetItems.where((i) => i.category == cat).length;
    }
    return counts;
  }

  /// Đếm số lượng món đồ trong 1 tủ đồ bất kỳ
  int getItemCountForWardrobe(String wardrobeId) {
    final targetId = wardrobeId.isEmpty ? 'default' : wardrobeId;
    return _allItems
        .where((item) =>
            (item.wardrobeId.isEmpty ? 'default' : item.wardrobeId) == targetId)
        .length;
  }

  String _getItemsStorageKey(String email) {
    if (email.isEmpty) return 'custom_wardrobe_items';
    return 'custom_wardrobe_items_$email';
  }

  String _getCollectionsStorageKey(String email) {
    if (email.isEmpty) return 'custom_wardrobe_collections';
    return 'custom_wardrobe_collections_$email';
  }

  String _getActiveWardrobeStorageKey(String email) {
    if (email.isEmpty) return 'active_wardrobe_id';
    return 'active_wardrobe_id_$email';
  }

  static bool isPreSeededDemoAccount(String? email, SharedPreferences prefs) =>
      false;

  /// Tài khoản mới tạo luôn là tủ đồ trắng hoàn toàn (0 món đồ)
  static List<WardrobeItemModel> get defaultSampleItems => [];

  WardrobeProvider() {
    loadItems();
  }

  /// Tải dữ liệu các tủ đồ và trang phục từ SharedPreferences
  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();

    List<WardrobeItemModel> customItems = [];
    List<WardrobeCollectionModel> loadedCollections = [
      WardrobeCollectionModel.defaultWardrobe(),
    ];
    String activeId = 'default';

    try {
      final prefs = await SharedPreferences.getInstance();
      final email =
          (await TokenStorage.getUserEmail())?.trim().toLowerCase() ?? '';

      // 1. Tải danh sách bộ sưu tập tủ đồ
      final collectionsKey = _getCollectionsStorageKey(email);
      final collectionsJson = prefs.getStringList(collectionsKey) ?? [];
      if (collectionsJson.isNotEmpty) {
        loadedCollections = collectionsJson
            .map((str) => WardrobeCollectionModel.fromJson(
                jsonDecode(str) as Map<String, dynamic>))
            .toList();

        // Đảm bảo tủ đồ mặc định luôn luôn tồn tại
        if (!loadedCollections.any((c) => c.id == 'default')) {
          loadedCollections.insert(
              0, WardrobeCollectionModel.defaultWardrobe());
        }
      }

      // 2. Tải ID tủ đồ đang hoạt động
      final activeKey = _getActiveWardrobeStorageKey(email);
      final savedActiveId = prefs.getString(activeKey);
      if (savedActiveId != null &&
          loadedCollections.any((c) => c.id == savedActiveId)) {
        activeId = savedActiveId;
      } else {
        activeId = loadedCollections.first.id;
      }

      // 3. Tải danh sách món đồ
      final itemsKey = _getItemsStorageKey(email);
      final itemsJson = prefs.getStringList(itemsKey) ?? [];
      if (itemsJson.isNotEmpty) {
        customItems = itemsJson
            .map((str) => WardrobeItemModel.fromJson(
                jsonDecode(str) as Map<String, dynamic>))
            .toList();
      } else {
        // Tài khoản mới tạo luôn là tủ đồ trắng hoàn toàn (0 món đồ)
        customItems = [];
      }
    } catch (e) {
      debugPrint('[WardrobeProvider] loadItems error: $e');
    }

    _collections = loadedCollections;
    _activeWardrobeId = activeId;
    _allItems = customItems;
    _isLoading = false;
    notifyListeners();
    _saveItems();

    // 4. Đồng bộ 2 chiều với PostgreSQL Server Database
    try {
      final email =
          (await TokenStorage.getUserEmail())?.trim().toLowerCase() ?? '';
      if (email.isNotEmpty) {
        _wardrobeService.getWardrobeItems(email: email).then((serverItems) {
          if (serverItems.isNotEmpty) {
            _allItems = serverItems;
            _saveItems();
            notifyListeners();
          }
        });
      }
    } catch (_) {}
  }

  /// Xóa tất cả trang phục (đưa tủ đồ về trạng thái tủ đồ trắng trên cả Thiết bị & Server Database)
  Future<void> clearAllItems() async {
    _allItems = [];
    _selectedCategory = null;
    notifyListeners();
    await _saveItems();

    try {
      final email =
          (await TokenStorage.getUserEmail())?.trim().toLowerCase() ?? '';
      if (email.isNotEmpty) {
        await _wardrobeService.clearAllItems(email: email);
      }
    } catch (_) {}
  }

  /// Reset toàn bộ tủ đồ và dữ liệu trang phục về trạng thái ban đầu (trắng)
  Future<void> resetAllData() async {
    _allItems = [];
    _collections = [WardrobeCollectionModel.defaultWardrobe()];
    _activeWardrobeId = 'default';
    _selectedCategory = null;
    _isLoading = false;
    notifyListeners();
    await _saveItems();
    await _saveCollections();
    await _saveActiveWardrobe();
  }

  void reset() {
    _allItems = [];
    _collections = [WardrobeCollectionModel.defaultWardrobe()];
    _activeWardrobeId = 'default';
    _selectedCategory = null;
    _selectedColor = null;
    _sortBy = 'default';
    _isLoading = false;
    notifyListeners();
  }

  void setCategory(WardrobeCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setColorFilter(String? color) {
    _selectedColor = color;
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  void resetFilters() {
    _selectedCategory = null;
    _selectedColor = null;
    _sortBy = 'default';
    notifyListeners();
  }

  void applyFilters({
    WardrobeCategory? category,
    String? color,
    String? sortBy,
  }) {
    _selectedCategory = category;
    _selectedColor = color;
    if (sortBy != null) _sortBy = sortBy;
    notifyListeners();
  }

  /// Chuyển đổi tủ đồ đang xem
  Future<void> switchWardrobe(String wardrobeId) async {
    if (_activeWardrobeId == wardrobeId) return;
    _activeWardrobeId = wardrobeId;
    _selectedCategory = null; // Reset category filter khi chuyển tủ
    _selectedColor = null;
    _sortBy = 'default';
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final email =
          (await TokenStorage.getUserEmail())?.trim().toLowerCase() ?? '';
      await prefs.setString(_getActiveWardrobeStorageKey(email), wardrobeId);
    } catch (_) {}
  }

  /// Tạo một tủ đồ mới
  Future<WardrobeCollectionModel> createWardrobe({
    required String name,
    required String icon,
    String description = '',
  }) async {
    final newCollection = WardrobeCollectionModel(
      id: 'wardrobe_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      icon: icon.trim().isEmpty ? '👗' : icon.trim(),
      description: description.trim(),
      isDefault: false,
      createdAt: DateTime.now(),
    );

    _collections.add(newCollection);
    _activeWardrobeId = newCollection.id;
    _selectedCategory = null;
    notifyListeners();

    await _saveCollections();
    await _saveActiveWardrobe();
    return newCollection;
  }

  /// Chỉnh sửa tên / biểu tượng tủ đồ
  Future<void> updateWardrobe({
    required String id,
    required String name,
    required String icon,
    String? description,
  }) async {
    final index = _collections.indexWhere((c) => c.id == id);
    if (index != -1) {
      final old = _collections[index];
      _collections[index] = old.copyWith(
        name: name.trim(),
        icon: icon.trim(),
        description: description?.trim() ?? old.description,
      );
      notifyListeners();
      await _saveCollections();
    }
  }

  /// Xóa một tủ đồ (Chuyển toàn bộ trang phục về Tủ Đồ Mặc Định để tránh mất dữ liệu)
  Future<void> deleteWardrobe(String id) async {
    if (id == 'default') return; // Không xóa tủ mặc định

    // Chuyển trang phục về tủ đồ mặc định
    bool itemsUpdated = false;
    _allItems = _allItems.map((item) {
      if (item.wardrobeId == id) {
        itemsUpdated = true;
        return item.copyWith(wardrobeId: 'default');
      }
      return item;
    }).toList();

    _collections.removeWhere((c) => c.id == id);

    if (_activeWardrobeId == id) {
      _activeWardrobeId = 'default';
      _selectedCategory = null;
    }

    notifyListeners();

    await _saveCollections();
    await _saveActiveWardrobe();
    if (itemsUpdated) {
      await _saveItems();
    }
  }

  /// Chuyển món đồ sang một tủ đồ khác
  Future<void> moveItemToWardrobe(
      String itemId, String targetWardrobeId) async {
    final index = _allItems.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _allItems[index] =
          _allItems[index].copyWith(wardrobeId: targetWardrobeId);
      notifyListeners();
      await _saveItems();
    }
  }

  /// Thêm món đồ mới (tự động gán vào tủ đồ đang mở nếu chưa chỉ định)
  Future<void> addItem(WardrobeItemModel item) async {
    final assignedWardrobeId =
        item.wardrobeId.isEmpty || item.wardrobeId == 'default'
            ? _activeWardrobeId
            : item.wardrobeId;
    final itemToSave = item.copyWith(wardrobeId: assignedWardrobeId);

    _allItems = [itemToSave, ..._allItems];
    notifyListeners();
    await _saveItems();

    try {
      final email = await TokenStorage.getUserEmail();
      await _wardrobeService.createItem(itemToSave, email: email);
    } catch (_) {}
  }

  /// Thêm nhiều món đồ cùng lúc
  Future<void> addMultipleItems(List<WardrobeItemModel> items) async {
    if (items.isEmpty) return;
    final itemsToSave = items.map((item) {
      final assignedWardrobeId =
          item.wardrobeId.isEmpty || item.wardrobeId == 'default'
              ? _activeWardrobeId
              : item.wardrobeId;
      return item.copyWith(wardrobeId: assignedWardrobeId);
    }).toList();

    _allItems = [...itemsToSave, ..._allItems];
    notifyListeners();
    await _saveItems();

    try {
      final email = await TokenStorage.getUserEmail();
      for (final item in itemsToSave) {
        await _wardrobeService.createItem(item, email: email);
      }
    } catch (_) {}
  }

  /// Cập nhật thông tin món đồ
  Future<void> updateItem(WardrobeItemModel updatedItem) async {
    final index = _allItems.indexWhere((i) => i.id == updatedItem.id);
    if (index != -1) {
      _allItems[index] = updatedItem;
      notifyListeners();
      await _saveItems();

      try {
        await _wardrobeService.updateItem(updatedItem);
      } catch (_) {}
    }
  }

  /// Xóa món đồ khỏi tủ
  Future<void> removeItem(String itemId) async {
    _allItems = _allItems.where((i) => i.id != itemId).toList();
    notifyListeners();
    await _saveItems();

    try {
      await _wardrobeService.deleteItem(itemId);
    } catch (_) {}
  }

  // --- Helper lưu trữ ---

  Future<void> _saveCollections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email =
          (await TokenStorage.getUserEmail())?.trim().toLowerCase() ?? '';
      final collectionsKey = _getCollectionsStorageKey(email);
      final jsonList = _collections.map((c) => jsonEncode(c.toJson())).toList();
      await prefs.setStringList(collectionsKey, jsonList);
    } catch (_) {}
  }

  Future<void> _saveActiveWardrobe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email =
          (await TokenStorage.getUserEmail())?.trim().toLowerCase() ?? '';
      final activeKey = _getActiveWardrobeStorageKey(email);
      await prefs.setString(activeKey, _activeWardrobeId);
    } catch (_) {}
  }

  Future<void> _saveItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email =
          (await TokenStorage.getUserEmail())?.trim().toLowerCase() ?? '';
      final itemsKey = _getItemsStorageKey(email);
      final jsonList = _allItems.map((i) => jsonEncode(i.toJson())).toList();
      await prefs.setStringList(itemsKey, jsonList);
    } catch (_) {}
  }
}
