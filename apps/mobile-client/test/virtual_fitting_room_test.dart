import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wearsy_mobile/features/fitting_room/screens/virtual_fitting_room_screen.dart';
import 'package:wearsy_mobile/features/fitting_room/widgets/mannequin_2d_widget.dart';
import 'package:wearsy_mobile/features/wardrobe/models/wardrobe_item_model.dart';
import 'package:wearsy_mobile/features/wardrobe/providers/wardrobe_provider.dart';
import 'package:wearsy_mobile/features/outfits/providers/outfit_provider.dart';

void main() {
  group('Virtual Fitting Room & Mannequin Tests', () {
    testWidgets('Mannequin2DWidget renders correctly for both genders',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Mannequin2DWidget(gender: MannequinGender.female),
          ),
        ),
      );
      expect(find.byType(Mannequin2DWidget), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Mannequin2DWidget(gender: MannequinGender.male),
          ),
        ),
      );
      expect(find.byType(Mannequin2DWidget), findsOneWidget);
    });

    testWidgets('VirtualFittingRoomScreen loads with providers and equips initial product',
        (tester) async {
      final sampleTop = WardrobeItemModel(
        id: 'top_001',
        name: 'Áo Polo Trắng',
        category: WardrobeCategory.tops,
        color: 'Trắng',
        brand: 'Zara',
        imageUrl: 'https://example.com/polo.png',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => WardrobeProvider()),
            ChangeNotifierProvider(create: (_) => OutfitProvider()),
          ],
          child: MaterialApp(
            home: VirtualFittingRoomScreen(initialProduct: sampleTop),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Phòng Thử Đồ Ảo 👗'), findsOneWidget);
      expect(find.text('Áo (Tops)'), findsOneWidget);
      expect(find.text('Quần/Váy'), findsOneWidget);
      expect(find.text('Xáo Trộn'), findsOneWidget);
      expect(find.text('Lưu Bộ Này Thành Outfit'), findsOneWidget);
    });
  });
}
