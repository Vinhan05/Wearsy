/// Deterministic Engine cho tính năng Smart Fit
/// Tính chỉ số BMI, phân loại thể trạng Asian Standard, ánh xạ Size và cảnh báo độ dài
class BodyAnalysisResult {
  final double heightCm;
  final double weightKg;
  final String gender;
  final double bmi;
  final String bodyFrame;
  final String bodyFrameCode; // 'slim', 'fit', 'plump', 'plus_size'
  final String estimatedSize;
  final List<String> lengthHazardFlags;
  final List<String> fitWarnings;
  final String defaultProportionTip;

  const BodyAnalysisResult({
    required this.heightCm,
    required this.weightKg,
    required this.gender,
    required this.bmi,
    required this.bodyFrame,
    required this.bodyFrameCode,
    required this.estimatedSize,
    required this.lengthHazardFlags,
    required this.fitWarnings,
    required this.defaultProportionTip,
  });

  Map<String, dynamic> toJson() {
    return {
      'gender': gender,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'bmi': bmi,
      'body_frame': bodyFrame,
      'body_frame_code': bodyFrameCode,
      'estimated_size': estimatedSize,
      'length_hazard_flags': lengthHazardFlags,
      'fit_warnings': fitWarnings,
      'default_proportion_tip': defaultProportionTip,
    };
  }
}

class SmartFitEngine {
  /// Chuẩn chiều cao tham chiếu (165 cm) dùng để tính Scale Ratio cho 2D Canvas
  static const double referenceHeightCm = 165.0;

  /// Tính tỷ lệ phóng thu hiển thị trên Layering Canvas 2D
  static double calculateScaleRatio(double heightCm) {
    if (heightCm <= 0) return 1.0;
    final ratio = heightCm / referenceHeightCm;
    // Giới hạn tỷ lệ co giãn từ 0.85 đến 1.18 để đảm bảo tính mỹ thuật trên màn hình điện thoại
    return ratio.clamp(0.85, 1.18);
  }

  /// Phân tích thể trạng chuẩn Asian Standard Body Frame
  static BodyAnalysisResult analyzeBody({
    required double heightCm,
    required double weightKg,
    String gender = 'Nữ',
  }) {
    final effectiveHeight = heightCm > 50 ? heightCm : 160.0;
    final effectiveWeight = weightKg > 20 ? weightKg : 50.0;
    final heightM = effectiveHeight / 100.0;

    // 1. Chỉ số BMI
    final rawBmi = effectiveWeight / (heightM * heightM);
    final bmi = double.parse(rawBmi.toStringAsFixed(1));

    // 2. Phân loại vóc dáng cơ bản (Asian Standard Body Frame)
    String bodyFrame;
    String bodyFrameCode;
    String proportionTip;

    if (bmi < 18.5) {
      bodyFrame = 'Gầy (Slim / Petite)';
      bodyFrameCode = 'slim';
      proportionTip =
          'Vóc dáng thanh mảnh: Ưu tiên trang phục sáng màu, sơ mi phom regular hoặc phối layering nhiều lớp (như khoác thêm blazer/cardigan) để tạo độ dày cơ thể và khí chất tự tin.';
    } else if (bmi < 23.0) {
      bodyFrame = 'Cân đối (Fit / Standard)';
      bodyFrameCode = 'fit';
      proportionTip =
          'Vóc dáng chuẩn tỷ lệ vàng: Rất tôn dáng khi sơ vin gọn gàng, có thể tự tin phối đa dạng phong cách từ tối giản đến phá cách hiện đại.';
    } else if (bmi < 25.0) {
      bodyFrame = 'Hơi thừa cân (Overweight / Plump)';
      bodyFrameCode = 'plump';
      proportionTip =
          'Ưu tiên phối màu đơn sắc (Monochrome) hoặc các gam màu trung tính trầm (Đen, Xanh Navy) cùng quần cạp cao để kéo dài tỷ lệ thân hình thanh thoát.';
    } else {
      bodyFrame = 'Đầy đặn (Plus-size)';
      bodyFrameCode = 'plus_size';
      proportionTip =
          'Nên chọn phom áo suông vừa vặn (Regular Fit), cổ chữ V hoặc mở cúc trên, kết hợp áo khoác dáng đứng mở khóa để tạo đường sọc dọc đánh lừa thị giác thon gọn.';
    }

    // 3. Ánh xạ khung Size chuẩn (Lookup Table Matrix)
    final isFemale = gender.toLowerCase().contains('fe') ||
        gender.toLowerCase().contains('nữ') ||
        gender.toLowerCase().contains('gái');

    String estimatedSize;
    if (isFemale) {
      if (effectiveHeight < 150 || effectiveWeight < 40) {
        estimatedSize = 'Size XS';
      } else if (effectiveHeight <= 158 && effectiveWeight <= 47) {
        estimatedSize = 'Size S';
      } else if (effectiveHeight <= 165 && effectiveWeight <= 54) {
        estimatedSize = 'Size M';
      } else if (effectiveHeight <= 170 && effectiveWeight <= 62) {
        estimatedSize = 'Size L';
      } else {
        estimatedSize = 'Size XL';
      }
    } else {
      if (effectiveHeight < 160 || effectiveWeight < 50) {
        estimatedSize = 'Size S';
      } else if (effectiveHeight <= 168 && effectiveWeight <= 60) {
        estimatedSize = 'Size M';
      } else if (effectiveHeight <= 178 && effectiveWeight <= 72) {
        estimatedSize = 'Size L';
      } else if (effectiveHeight <= 185 && effectiveWeight <= 82) {
        estimatedSize = 'Size XL';
      } else {
        estimatedSize = 'Size XXL';
      }
    }

    // 4. Cảnh báo tỷ lệ chiều dài (Length Hazard Detection)
    final flags = <String>[];
    final warnings = <String>[];

    if (isFemale && effectiveHeight < 155) {
      flags.add('FLAG_MAY_BE_LONG');
      warnings.add(
          'Với chiều cao khiêm tốn (<155cm), quần ống suông dài hoặc đầm maxi có nguy cơ quệt gót; nên sơ vin và mang giày độn đế 3-5cm.');
    } else if (effectiveHeight < 158) {
      warnings.add(
          'Nên sơ vin áo trong quần/chân váy cạp cao để tạo hiệu ứng thị giác nâng eo và kéo dài đôi chân.');
    }

    if (!isFemale && effectiveHeight > 180) {
      flags.add('FLAG_MAY_BE_SHORT');
      warnings.add(
          'Chiều cao lý tưởng (>180cm), chú ý quần âu dáng thông thường có thể bị cộc ống trên mắt cá chân, nên ưu tiên dáng Regular/Tall.');
    }

    return BodyAnalysisResult(
      heightCm: effectiveHeight,
      weightKg: effectiveWeight,
      gender: isFemale ? 'Nữ' : 'Nam',
      bmi: bmi,
      bodyFrame: bodyFrame,
      bodyFrameCode: bodyFrameCode,
      estimatedSize: estimatedSize,
      lengthHazardFlags: flags,
      fitWarnings: warnings,
      defaultProportionTip: proportionTip,
    );
  }
}
