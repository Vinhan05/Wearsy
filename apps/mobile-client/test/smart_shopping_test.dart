import 'package:flutter_test/flutter_test.dart';
import 'package:wearsy_mobile/core/services/smart_shopping_ai_service.dart';
import 'package:wearsy_mobile/features/wardrobe/models/wardrobe_item_model.dart';

void main() {
  group('SmartShoppingAiService URL Parsing Tests', () {
    test('Correctly parses Shopee Sweater Frozen Shark', () {
      const url =
          'https://shopee.vn/%C3%81o-Sweater-Frozen-Shark-N%E1%BB%89-N%E1%BB%89-B%C3%B4ng-Cotton-100-Unisex-Local-Brand-i.564687320.26261149077?extraParams=%7B%22display_modACel_id%22%3A217850061955%2C%22model_selection_logic%22%3A3%7D';
      final product = SmartShoppingAiService.parseProductFromUrl(url);

      expect(product.platform, 'Shopee');
      expect(product.title, contains('Sweater'));
      expect(product.title, contains('Frozen Shark'));
      expect(product.category, WardrobeCategory.tops);
      expect(product.brand, 'Frozen Shark');
      expect(product.tags, contains('Sweater'));
      expect(product.tags, contains('Cotton'));
      expect(product.tags, contains('Unisex'));
    });

    test('Correctly parses Shopee Áo 3 lỗ nam Cotton trắng', () {
      const url =
          'https://shopee.vn/%C3%81o-3-l%E1%BB%97-nam-Cotton-tr%E1%BA%AFng-tr%C6%A1n-m%E1%BA%B7c-l%C3%B3t-trong-s%C6%A1-mi-trung-ni%C3%AAn-LEDATEX-%C4%91%C3%B4ng-xu%C3%A2n-cao-c%E1%BA%A5p-LOTNAM-i.317269974.7756281788?extraParams=%7B%22display_model_id%22%3A73305385054%2C%22model_selection_logic%22%3A3%7D';
      final product = SmartShoppingAiService.parseProductFromUrl(url);

      expect(product.platform, 'Shopee');
      expect(product.title, contains('Áo 3 lỗ'));
      expect(product.category, WardrobeCategory.tops);
      expect(product.color, 'Trắng');
      expect(product.brand, 'LEDATEX');
      expect(product.tags, contains('Áo 3 Lỗ'));
      expect(product.tags, contains('Cotton'));
    });

    test('The two products are completely distinct', () {
      const url1 =
          'https://shopee.vn/%C3%81o-Sweater-Frozen-Shark-N%E1%BB%89-N%E1%BB%89-B%C3%B4ng-Cotton-100-Unisex-Local-Brand-i.564687320.26261149077?extraParams=%7B%22display_modACel_id%22%3A217850061955%2C%22model_selection_logic%22%3A3%7D';
      const url2 =
          'https://shopee.vn/%C3%81o-3-l%E1%BB%97-nam-Cotton-tr%E1%BA%AFng-tr%C6%A1n-m%E1%BA%B7c-l%C3%B3t-trong-s%C6%A1-mi-trung-ni%C3%AAn-LEDATEX-%C4%91%C3%B4ng-xu%C3%A2n-cao-c%E1%BA%A5p-LOTNAM-i.317269974.7756281788?extraParams=%7B%22display_model_id%22%3A73305385054%2C%22model_selection_logic%22%3A3%7D';

      final p1 = SmartShoppingAiService.parseProductFromUrl(url1);
      final p2 = SmartShoppingAiService.parseProductFromUrl(url2);

      expect(p1.title, isNot(equals(p2.title)));
      expect(p1.brand, isNot(equals(p2.brand)));
      expect(p1.price, isNot(equals(p2.price)));
      expect(p1.color, isNot(equals(p2.color)));
    });

    test('enrichProductFromUrl extracts real Shopee image URL', () async {
      const url =
          'https://shopee.vn/%C3%81o-Sweater-Frozen-Shark-N%E1%BB%89-N%E1%BB%89-B%C3%B4ng-Cotton-100-Unisex-Local-Brand-i.564687320.26261149077';
      final initialProduct = SmartShoppingAiService.parseProductFromUrl(url);
      final enrichedProduct =
          await SmartShoppingAiService.enrichProductFromUrl(initialProduct);

      // Verify that enriched product has the real Shopee image from susercontent
      expect(enrichedProduct.imageUrl, contains('susercontent.com'));
      expect(enrichedProduct.title, contains('Sweater'));
    });

    test('enrichProductFromUrl with Shopee Fan URL', () async {
      const fanUrl =
          'https://shopee.vn/Qu%E1%BA%A1t-c%E1%BA%A7m-tay-M2-N68-5000mAh-di-%C4%91%E1%BB%99ng-c%C3%B3-th%E1%BB%83-s%E1%BA%A1c-gi%C3%B3-m%E1%BA%A1nh-100-t%E1%BB%91c-%C4%91%E1%BB%99-turbo-ph%E1%BA%A3n-l%E1%BB%B1c-m%C3%A0n-h%C3%ACnh-hi%E1%BB%83n-th%E1%BB%8B-pin-T%E1%BA%B7ng-d%C3%A2y-%C4%91eo-i.1025928968.24143959658?extraParams=%7B%22display_model_id%22%3A258164864058%2C%22model_selection_logic%22%3A3%7D';
      final initialProduct = SmartShoppingAiService.parseProductFromUrl(fanUrl);

      expect(initialProduct.category, WardrobeCategory.accessories);
      expect(initialProduct.category, isNot(WardrobeCategory.tops));
      expect(initialProduct.title, contains('Quạt'));
      expect(initialProduct.color, 'Trắng');
      expect(initialProduct.price, 48500);
      expect(initialProduct.imageUrl, contains('susercontent.com'));

      final enrichedProduct =
          await SmartShoppingAiService.enrichProductFromUrl(initialProduct);

      expect(enrichedProduct.category, WardrobeCategory.accessories);
      expect(enrichedProduct.title, contains('Quạt'));
      expect(enrichedProduct.imageUrl, contains('susercontent.com'));
    });
  });
}
