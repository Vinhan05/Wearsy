import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Service tách nền AI cục bộ (Client-side Image Processing)
/// Tự động phân tích màu sắc phông nền, bóc tách vùng quần áo và tạo ảnh PNG trong suốt.
class LocalBgRemovalService {
  /// Xử lý ảnh cục bộ và trả về đường dẫn file PNG đã được tách nền
  static Future<String?> processImage(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final resultBytes = await compute(_removeBackgroundIsolate, bytes);

      if (resultBytes == null) return null;

      final outPath = filePath.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '_cutout.png');
      final outFile = File(outPath);
      await outFile.writeAsBytes(resultBytes);
      return outFile.path;
    } catch (e) {
      debugPrint('[LocalBgRemovalService] Lỗi tách nền cục bộ: $e');
      return null;
    }
  }

  static Uint8List? _removeBackgroundIsolate(Uint8List inputBytes) {
    var image = img.decodeImage(inputBytes);
    if (image == null) return null;

    // Tối ưu hiệu năng: Tự động downsample nếu ảnh lớn hơn 1024px
    if (image.width > 1024 || image.height > 1024) {
      if (image.width >= image.height) {
        image = img.copyResize(image, width: 1024);
      } else {
        image = img.copyResize(image, height: 1024);
      }
    }

    final w = image.width;
    final h = image.height;

    // Lấy mẫu màu phông nền tại 4 góc và 4 cạnh biên
    final bgSamples = <img.Pixel>[];
    final samplePoints = [
      [5, 5],
      [w - 6, 5],
      [5, h - 6],
      [w - 6, h - 6],
      [w ~/ 2, 5],
      [5, h ~/ 2],
      [w - 6, h ~/ 2],
    ];

    for (final pt in samplePoints) {
      if (pt[0] >= 0 && pt[0] < w && pt[1] >= 0 && pt[1] < h) {
        bgSamples.add(image.getPixel(pt[0], pt[1]));
      }
    }

    // Loại bỏ phông nền studio / phòng ngủ / sàn nhà
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final pixel = image.getPixel(x, y);

        bool isBg = false;
        for (final bg in bgSamples) {
          final dr = (pixel.r - bg.r).abs();
          final dg = (pixel.g - bg.g).abs();
          final db = (pixel.b - bg.b).abs();

          // Khoảng cách màu với phông nền mẫu
          if (dr < 42 && dg < 42 && db < 42) {
            isBg = true;
            break;
          }
        }

        final isBorderRegion = (x < w * 0.15 || x > w * 0.85 || y < h * 0.12 || y > h * 0.88);

        if (isBorderRegion && isBg) {
          pixel.a = 0; // Đặt độ trong suốt bằng 0
        } else if (isBg && _isNeutralBgColor(pixel)) {
          pixel.a = 0;
        }
      }
    }

    return Uint8List.fromList(img.encodePng(image));
  }

  static bool _isNeutralBgColor(img.Pixel p) {
    final maxDiff = [
      (p.r - p.g).abs(),
      (p.g - p.b).abs(),
      (p.b - p.r).abs(),
    ].reduce((a, b) => a > b ? a : b);

    final isNeutral = maxDiff < 30;
    final luminance = (p.r * 0.299 + p.g * 0.587 + p.b * 0.114);
    return isNeutral && (luminance > 165 || luminance < 45);
  }
}
