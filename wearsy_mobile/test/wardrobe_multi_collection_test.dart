import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wearsy_mobile/features/wardrobe/models/wardrobe_collection_model.dart';
import 'package:wearsy_mobile/features/wardrobe/models/wardrobe_item_model.dart';
import 'package:wearsy_mobile/features/wardrobe/providers/wardrobe_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WardrobeCollectionModel Tests', () {
    test('Default wardrobe initializes correctly', () {
      final defaultCol = WardrobeCollectionModel.defaultWardrobe();
      expect(defaultCol.id, 'default');
      expect(defaultCol.isDefault, true);
      expect(defaultCol.name, 'Tủ Đồ Hàng Ngày');
      expect(defaultCol.icon, '🏠');
    });

    test('Json serialization and deserialization works', () {
      final custom = WardrobeCollectionModel(
        id: 'office_123',
        name: 'Tủ Đồ Công Sở',
        icon: '💼',
        description: 'Trang phục đi làm',
        isDefault: false,
      );

      final json = custom.toJson();
      final fromJson = WardrobeCollectionModel.fromJson(json);

      expect(fromJson.id, 'office_123');
      expect(fromJson.name, 'Tủ Đồ Công Sở');
      expect(fromJson.icon, '💼');
      expect(fromJson.description, 'Trang phục đi làm');
      expect(fromJson.isDefault, false);
    });
  });

  group('WardrobeProvider Multi-Wardrobe Tests', () {
    test('Provider creates, switches, and filters items per wardrobe', () async {
      final provider = WardrobeProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.collections.length, 1);
      expect(provider.activeWardrobeId, 'default');

      // 1. Thêm đồ vào tủ mặc định
      final item1 = WardrobeItemModel(
        id: 'item_1',
        name: 'Áo thun trắng',
        category: WardrobeCategory.tops,
        color: 'Trắng',
        brand: 'Zara',
        imageUrl: 'https://example.com/item1.jpg',
        wardrobeId: 'default',
      );
      await provider.addItem(item1);

      expect(provider.allItems.length, 1);
      expect(provider.getItemCountForWardrobe('default'), 1);

      // 2. Tạo tủ đồ mới "Tủ Đồ Đi Biển"
      final newCol = await provider.createWardrobe(
        name: 'Tủ Đồ Đi Biển',
        icon: '🏖️',
        description: 'Đồ bơi & dạo biển',
      );

      expect(provider.collections.length, 2);
      expect(provider.activeWardrobeId, newCol.id);
      // Tủ mới tạo chưa có đồ
      expect(provider.allItems.length, 0);

      // 3. Thêm đồ vào tủ đi biển
      final item2 = WardrobeItemModel(
        id: 'item_2',
        name: 'Quần short hoa',
        category: WardrobeCategory.bottoms,
        color: 'Xanh',
        brand: 'H&M',
        imageUrl: 'https://example.com/item2.jpg',
      );
      await provider.addItem(item2);

      expect(provider.allItems.length, 1);
      expect(provider.allItems.first.name, 'Quần short hoa');
      expect(provider.allItems.first.wardrobeId, newCol.id);
      expect(provider.getItemCountForWardrobe(newCol.id), 1);
      expect(provider.getItemCountForWardrobe('default'), 1);

      // 4. Chuyển lại tủ mặc định
      await provider.switchWardrobe('default');
      expect(provider.activeWardrobeId, 'default');
      expect(provider.allItems.length, 1);
      expect(provider.allItems.first.name, 'Áo thun trắng');

      // 5. Di chuyển item2 từ tủ đi biển sang tủ mặc định
      await provider.moveItemToWardrobe('item_2', 'default');
      expect(provider.allItems.length, 2);
      expect(provider.getItemCountForWardrobe('default'), 2);
      expect(provider.getItemCountForWardrobe(newCol.id), 0);

      // 6. Xóa tủ đi biển (không làm mất đồ)
      await provider.deleteWardrobe(newCol.id);
      expect(provider.collections.length, 1);
      expect(provider.activeWardrobeId, 'default');
    });
  });
}
