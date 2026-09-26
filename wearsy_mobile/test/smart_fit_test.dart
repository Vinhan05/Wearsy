import 'package:flutter_test/flutter_test.dart';
import 'package:wearsy_mobile/core/services/smart_fit_engine.dart';
import 'package:wearsy_mobile/features/wardrobe/models/wardrobe_item_model.dart';
import 'package:wearsy_mobile/features/outfits/models/outfit_model.dart';

void main() {
  group('SmartFitEngine Tests', () {
    test('Asian Standard BMI & Sizing for Female (158cm, 46kg)', () {
      final res = SmartFitEngine.analyzeBody(
        heightCm: 158,
        weightKg: 46,
        gender: 'Nữ',
      );

      expect(res.bmi, 18.4);
      expect(res.bodyFrameCode, 'slim');
      expect(res.estimatedSize, 'Size S');
    });

    test('Asian Standard BMI & Sizing for Male (172cm, 65kg)', () {
      final res = SmartFitEngine.analyzeBody(
        heightCm: 172,
        weightKg: 65,
        gender: 'Nam',
      );

      expect(res.bmi, 22.0);
      expect(res.bodyFrameCode, 'fit');
      expect(res.estimatedSize, 'Size L');
    });

    test('Length Hazard Detection for Petite Female (<155cm)', () {
      final res = SmartFitEngine.analyzeBody(
        heightCm: 152,
        weightKg: 42,
        gender: 'Nữ',
      );

      expect(res.lengthHazardFlags.contains('FLAG_MAY_BE_LONG'), isTrue);
    });

    test('Length Hazard Detection for Tall Male (>180cm)', () {
      final res = SmartFitEngine.analyzeBody(
        heightCm: 184,
        weightKg: 75,
        gender: 'Nam',
      );

      expect(res.lengthHazardFlags.contains('FLAG_MAY_BE_SHORT'), isTrue);
    });

    test('Scale Ratio calculation', () {
      final scale165 = SmartFitEngine.calculateScaleRatio(165);
      expect(scale165, 1.0);

      final scale158 = SmartFitEngine.calculateScaleRatio(158);
      expect(scale158, closeTo(0.957, 0.01));

      final scale180 = SmartFitEngine.calculateScaleRatio(180);
      expect(scale180, closeTo(1.09, 0.01));
    });
  });

  group('2D Layering Order Tests', () {
    test('Default layer orders match specification', () {
      expect(WardrobeCategory.tops.defaultLayerOrder, 1);
      expect(WardrobeCategory.bottoms.defaultLayerOrder, 1);
      expect(WardrobeCategory.dresses.defaultLayerOrder, 1);
      expect(WardrobeCategory.outerwear.defaultLayerOrder, 2);
      expect(WardrobeCategory.shoes.defaultLayerOrder, 3);
      expect(WardrobeCategory.accessories.defaultLayerOrder, 4);
    });
  });
}
