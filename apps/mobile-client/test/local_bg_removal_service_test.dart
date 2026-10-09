import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:wearsy_mobile/core/services/local_bg_removal_service.dart';

void main() {
  group('LocalBgRemovalService Unit Tests', () {
    late File tempInputFile;

    setUp(() async {
      // Tạo một ảnh mẫu 200x200 màu trắng với hình chữ nhật màu đen ở giữa
      final testImg = img.Image(width: 200, height: 200);
      img.fill(testImg, color: img.ColorRgb8(255, 255, 255)); // Phông nền trắng
      img.fillRect(testImg, x1: 50, y1: 50, x2: 150, y2: 150, color: img.ColorRgb8(0, 0, 0)); // Trang phục đen

      final pngBytes = img.encodePng(testImg);
      tempInputFile = File('${Directory.systemTemp.path}/test_item_input.png');
      await tempInputFile.writeAsBytes(pngBytes);
    });

    tearDown(() async {
      if (await tempInputFile.exists()) {
        await tempInputFile.delete();
      }
    });

    test('processImage returns a valid cutout PNG path for existing file', () async {
      final cutoutPath = await LocalBgRemovalService.processImage(tempInputFile.path);

      expect(cutoutPath, isNotNull);
      expect(cutoutPath, endsWith('_cutout.png'));

      final cutoutFile = File(cutoutPath!);
      expect(await cutoutFile.exists(), isTrue);

      final resultBytes = await cutoutFile.readAsBytes();
      expect(resultBytes.isNotEmpty, isTrue);
      final resultImg = img.decodeImage(resultBytes);
      expect(resultImg, isNotNull);

      if (await cutoutFile.exists()) {
        await cutoutFile.delete();
      }
    });

    test('processImage returns null for non-existent file path', () async {
      final result = await LocalBgRemovalService.processImage('/invalid/path/non_existent.png');
      expect(result, isNull);
    });
  });
}
