import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wearsy_mobile/core/mock/mock_data_service.dart';
import '../../../core/storage/token_storage.dart';
import '../models/outfit_model.dart';
import '../../wardrobe/models/wardrobe_item_model.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';

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
    return _outfits.where((o) => o.occasion == _selectedOccasion).toList();
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

    List<OutfitModel> baseOutfits = [];
    List<OutfitModel> customOutfits = [];

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = (await TokenStorage.getUserEmail())?.trim().toLowerCase() ?? '';
      final isDemo = WardrobeProvider.isPreSeededDemoAccount(email, prefs);

      if (isDemo) {
        baseOutfits = MockDataService.getMockOutfits();
      } else {
        baseOutfits = []; // Tài khoản tạo mới: ban đầu chưa có outfit
      }

      final storageKey = _getStorageKey(email);
      final customJson = prefs.getStringList(storageKey) ?? [];
      customOutfits = customJson
          .map((str) => OutfitModel.fromJson(jsonDecode(str) as Map<String, dynamic>))
          .toList();
    } catch (_) {}

    _outfits = [...customOutfits, ...baseOutfits];
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

  /// Simulates AI generating a new outfit suggestion
  Future<void> generateNewOutfit() async {
    _isGenerating = true;
    notifyListeners();

    // Simulate AI thinking time
    await Future.delayed(const Duration(seconds: 2));

    final newOutfit = OutfitModel(
      id: 'o_gen_${DateTime.now().millisecondsSinceEpoch}',
      name: _getRandomOutfitName(),
      occasion: _selectedOccasion ?? OutfitOccasion.casual,
      weatherSuitable: ['Mọi thời tiết'],
      aiScore: 8.5 + (DateTime.now().millisecond % 15) / 10,
      aiReason:
          'Dựa trên lịch sử mặc đồ và xu hướng thời trang hiện tại, AI đề xuất kết hợp này phù hợp với phong cách cá nhân và dịp sử dụng của bạn.',
      itemIds: ['w001', 'w006', 'w008'],
      coverImageUrl:
          'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=600&auto=format&fit=crop',
    );

    _outfits = [newOutfit, ..._outfits];
    _isGenerating = false;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = (await TokenStorage.getUserEmail())?.trim().toLowerCase() ?? '';
      final storageKey = _getStorageKey(email);
      final customJson = prefs.getStringList(storageKey) ?? [];
      final updatedJson = [jsonEncode(newOutfit.toJson()), ...customJson];
      await prefs.setStringList(storageKey, updatedJson);
    } catch (_) {}
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
      final email = (await TokenStorage.getUserEmail())?.trim().toLowerCase() ?? '';
      final storageKey = _getStorageKey(email);
      final customJson = prefs.getStringList(storageKey) ?? [];
      final updatedJson = customJson.map((str) {
        final decoded = jsonDecode(str) as Map<String, dynamic>;
        final match = _outfits.firstWhere((o) => o.id == decoded['id'], orElse: () => OutfitModel.fromJson(decoded));
        decoded['is_favorite'] = match.isFavorite;
        return jsonEncode(decoded);
      }).toList();
      await prefs.setStringList(storageKey, updatedJson);
    } catch (_) {}
  }

  /// Get wardrobe items for a given outfit
  List<WardrobeItemModel> getItemsForOutfit(OutfitModel outfit) {
    final allItems = MockDataService.getMockWardrobeItems();
    return allItems.where((i) => outfit.itemIds.contains(i.id)).toList();
  }

  String _getRandomOutfitName() {
    final names = [
      'Minimalist Chill Look',
      'Contemporary Street Style',
      'Effortless Chic Combo',
      'Power Dressing Set',
      'Weekend Relaxed Vibe',
      'After-Work Social Look',
    ];
    return names[DateTime.now().second % names.length];
  }
}
