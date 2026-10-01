import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wearsy_mobile/core/mock/mock_data_service.dart';
import '../../../core/services/smart_fit_ai_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../wardrobe/models/wardrobe_item_model.dart';
import '../models/outfit_model.dart';

class OutfitProvider with ChangeNotifier {
  List<OutfitModel> _outfits = [];
  OutfitOccasion? _selectedOccasion;
  bool _isLoading = false;
  bool _isGenerating = false;

  List<OutfitModel> get outfits => _outfits;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  OutfitOccasion? get selectedOccasion => _selectedOccasion;

  List<OutfitModel> get filteredOutfits {
    if (_selectedOccasion == null) return _outfits;
    return _outfits
        .where((outfit) => outfit.occasion == _selectedOccasion)
        .toList();
  }

  List<OutfitModel> get favoriteOutfits {
    return _outfits.where((outfit) => outfit.isFavorite).toList();
  }

  String _getStorageKey(String email) {
    if (email.isEmpty) return 'custom_outfits';
    return 'custom_outfits_$email';
  }

  OutfitProvider() {
    loadOutfits();
  }

  Future<void> loadOutfits() async {
    _isLoading = true;
    notifyListeners();

    List<OutfitModel> customOutfits = [];

    try {
      final prefs = await SharedPreferences.getInstance();
      final email =
          (await TokenStorage.getUserEmail())?.trim().toLowerCase() ?? '';

      final storageKey = _getStorageKey(email);
      final customJson = prefs.getStringList(storageKey) ?? [];
      customOutfits = customJson
          .map((str) =>
              OutfitModel.fromJson(jsonDecode(str) as Map<String, dynamic>))
          .toList();
    } catch (_) {}

    _outfits = customOutfits;
    _isLoading = false;
    notifyListeners();
  }

  void reset() {
    _outfits = [];
    _selectedOccasion = null;
    _isLoading = false;
    _isGenerating = false;
    notifyListeners();
  }

  void setOccasion(OutfitOccasion? occasion) {
    _selectedOccasion = occasion;
    notifyListeners();
  }

  /// Sinh gợi ý outfit mới tích hợp Smart Fit (Chiều cao & Cân nặng) + 2D Layering
  Future<void> generateNewOutfit({
    List<WardrobeItemModel>? availableItems,
    double? heightCm,
    double? weightKg,
    String? gender,
    String? occasionPrompt,
  }) async {
    _isGenerating = true;
    notifyListeners();

    try {
      final itemsToUse = availableItems ?? [];

      final occasionText =
          occasionPrompt ?? _selectedOccasion?.displayName ?? 'Công sở';

      final newOutfit = await SmartFitAiService.generateSmartFitOutfit(
        wardrobeItems: itemsToUse,
        heightCm: heightCm ?? 172.0,
        weightKg: weightKg ?? 65.0,
        gender: gender ?? 'Nam',
        occasion: occasionText,
      );

      _outfits = [newOutfit, ..._outfits];

      final prefs = await SharedPreferences.getInstance();
      final email =
          (await TokenStorage.getUserEmail())?.trim().toLowerCase() ?? '';
      final storageKey = _getStorageKey(email);
      final customJson = prefs.getStringList(storageKey) ?? [];
      final updatedJson = [jsonEncode(newOutfit.toJson()), ...customJson];
      await prefs.setStringList(storageKey, updatedJson);
    } catch (e) {
      debugPrint('[OutfitProvider] generateNewOutfit error: $e');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void toggleFavorite(String outfitId) {
    final index = _outfits.indexWhere((o) => o.id == outfitId);
    if (index != -1) {
      _outfits[index].isFavorite = !_outfits[index].isFavorite;
      notifyListeners();

      _persistFavorites();
    }
  }

  Future<void> _persistFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email =
          (await TokenStorage.getUserEmail())?.trim().toLowerCase() ?? '';
      final storageKey = _getStorageKey(email);
      final customJson = prefs.getStringList(storageKey) ?? [];
      final updatedJson = customJson.map((str) {
        final decoded = jsonDecode(str) as Map<String, dynamic>;
        final match = _outfits.firstWhere((o) => o.id == decoded['id'],
            orElse: () => OutfitModel.fromJson(decoded));
        decoded['is_favorite'] = match.isFavorite;
        return jsonEncode(decoded);
      }).toList();
      await prefs.setStringList(storageKey, updatedJson);
    } catch (_) {}
  }

  /// Thêm outfit được tạo từ màn hình chat AI Stylist
  Future<void> addOutfitFromChat(OutfitModel outfit) async {
    // Tránh trùng lặp
    if (_outfits.any((o) => o.id == outfit.id)) return;
    _outfits = [outfit, ..._outfits];
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final email =
          (await TokenStorage.getUserEmail())?.trim().toLowerCase() ?? '';
      final storageKey = _getStorageKey(email);
      final customJson = prefs.getStringList(storageKey) ?? [];
      final updatedJson = [jsonEncode(outfit.toJson()), ...customJson];
      await prefs.setStringList(storageKey, updatedJson);
    } catch (e) {
      debugPrint('[OutfitProvider] addOutfitFromChat error: $e');
    }
  }

  /// Lấy danh sách các món đồ cho một outfit từ tủ đồ người dùng
  List<WardrobeItemModel> getItemsForOutfit(OutfitModel outfit,
      [List<WardrobeItemModel>? userWardrobeItems]) {
    final available = userWardrobeItems ?? [];
    final mockItems = MockDataService.getMockWardrobeItems();

    final matched = <WardrobeItemModel>[];
    for (final id in outfit.itemIds) {
      final found = available.firstWhere(
        (i) => i.id == id,
        orElse: () => mockItems.firstWhere(
          (m) => m.id == id,
          orElse: () => WardrobeItemModel(
            id: id,
            name: 'Trang phục #$id',
            category: WardrobeCategory.tops,
            color: 'Đen',
            brand: 'WEARSY',
            imageUrl:
                'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?q=80&w=600&auto=format&fit=crop',
          ),
        ),
      );
      if (!matched.any((m) => m.id == found.id)) {
        matched.add(found);
      }
    }
    return matched;
  }
}
