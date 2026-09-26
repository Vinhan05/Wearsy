import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wearsy_mobile/core/mock/mock_data_service.dart';
import '../../../core/storage/token_storage.dart';
import '../models/wardrobe_item_model.dart';

class WardrobeProvider with ChangeNotifier {
  List<WardrobeItemModel> _allItems = [];
  WardrobeCategory? _selectedCategory;
  bool _isLoading = false;

  List<WardrobeItemModel> get allItems => _allItems;
  bool get isLoading => _isLoading;
  WardrobeCategory? get selectedCategory => _selectedCategory;

  List<WardrobeItemModel> get filteredItems {
    if (_selectedCategory == null) return _allItems;
    return _allItems.where((item) => item.category == _selectedCategory).toList();
  }

  Map<WardrobeCategory, int> get itemCountByCategory {
    final counts = <WardrobeCategory, int>{};
    for (final cat in WardrobeCategory.values) {
      counts[cat] = _allItems.where((i) => i.category == cat).length;
    }
    return counts;
  }

  String _getStorageKey(String email) {
    if (email.isEmpty) return 'custom_wardrobe_items';
    return 'custom_wardrobe_items_$email';
  }

  /// Only test/demo accounts provided for testing have pre-seeded clothes.
  /// Newly registered or real user accounts start with an empty wardrobe.
  static bool isPreSeededDemoAccount(String? email, SharedPreferences prefs) {
    if (email == null || email.trim().isEmpty) return false;
    final clean = email.trim().toLowerCase();

    // If account was created/registered on this device, it's a new account -> empty wardrobe
    final isNewAccount = prefs.getBool('is_new_account_$clean') ?? false;
    if (isNewAccount) return false;

    // Official test/demo accounts (from docs/demo account)
    const testAccounts = {
      'demo@wearsy.app',
      'test@wearsy.app',
      'admin.demo@wearsy.app',
      'user.test@gmail.com',
      'nguyenvana@example.com',
    };

    if (testAccounts.contains(clean)) return true;

    // Any demo/test account under wearsy.app domain
    if (clean.endsWith('@wearsy.app') && (clean.contains('demo') || clean.contains('test'))) {
      return true;
    }

    return false;
  }

  WardrobeProvider() {
    loadItems();
  }

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();

    List<WardrobeItemModel> baseItems = [];
    List<WardrobeItemModel> customItems = [];

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = (await TokenStorage.getUserEmail())?.trim().toLowerCase() ?? '';

      // Check if current user is an authorized test account
      final isDemo = isPreSeededDemoAccount(email, prefs);
      if (isDemo) {
        baseItems = MockDataService.getMockWardrobeItems();
      } else {
        baseItems = []; // Tài khoản tạo mới: tủ quần áo trắng 100%!
      }

      final storageKey = _getStorageKey(email);
      final customJson = prefs.getStringList(storageKey) ?? [];
      customItems = customJson
          .map((str) => WardrobeItemModel.fromJson(jsonDecode(str) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[WardrobeProvider] loadItems error: $e');
    }

    _allItems = [...customItems, ...baseItems];
    _isLoading = false;
    notifyListeners();
  }

  void reset() {
    _allItems = [];
    _selectedCategory = null;
    _isLoading = false;
    notifyListeners();
  }

  void setCategory(WardrobeCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> addItem(WardrobeItemModel item) async {
    _allItems = [item, ..._allItems];
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = (await TokenStorage.getUserEmail())?.trim().toLowerCase() ?? '';
      final storageKey = _getStorageKey(email);
      final customJson = prefs.getStringList(storageKey) ?? [];
      final updatedJson = [jsonEncode(item.toJson()), ...customJson];
      await prefs.setStringList(storageKey, updatedJson);
    } catch (_) {}
  }

  Future<void> updateItem(WardrobeItemModel updatedItem) async {
    final index = _allItems.indexWhere((i) => i.id == updatedItem.id);
    if (index != -1) {
      _allItems[index] = updatedItem;
      notifyListeners();

      try {
        final prefs = await SharedPreferences.getInstance();
        final email = (await TokenStorage.getUserEmail())?.trim().toLowerCase() ?? '';
        final storageKey = _getStorageKey(email);
        final customJson = prefs.getStringList(storageKey) ?? [];
        final updatedJson = customJson.map((str) {
          final decoded = jsonDecode(str) as Map<String, dynamic>;
          if (decoded['id'] == updatedItem.id) {
            return jsonEncode(updatedItem.toJson());
          }
          return str;
        }).toList();
        await prefs.setStringList(storageKey, updatedJson);
      } catch (_) {}
    }
  }

  Future<void> removeItem(String itemId) async {
    _allItems = _allItems.where((i) => i.id != itemId).toList();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = (await TokenStorage.getUserEmail())?.trim().toLowerCase() ?? '';
      final storageKey = _getStorageKey(email);
      final customJson = prefs.getStringList(storageKey) ?? [];
      final updatedJson = customJson.where((str) {
        final decoded = jsonDecode(str) as Map<String, dynamic>;
        return decoded['id'] != itemId;
      }).toList();
      await prefs.setStringList(storageKey, updatedJson);
    } catch (_) {}
  }
}

