import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/smart_fit_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../models/outfit_model.dart';
import '../../color_score/screens/color_score_screen.dart';

class SmartFitCard extends StatelessWidget {
  final OutfitModel outfit;
  final double currentHeightCm;
  final double currentWeightKg;
  final String gender;
  final Function(double newHeight, double newWeight)? onMeasurementsChanged;

  const SmartFitCard({
    super.key,
    required this.outfit,
    this.currentHeightCm = 165.0,
    this.currentWeightKg = 55.0,
    this.gender = 'Nữ',
    this.onMeasurementsChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Nếu outfit đã có sẵn smartFitAdvice thì dùng, nếu chưa có thì tính tức thì qua SmartFitEngine (< 5ms)
    final advice = outfit.smartFitAdvice;
    final fallbackAnalysis = SmartFitEngine.analyzeBody(
      heightCm: currentHeightCm,
      weightKg: currentWeightKg,
      gender: gender,
    );

    final displaySize = advice?.sizeRecommendation ??
        'Phù hợp nhất với ${fallbackAnalysis.estimatedSize} chuẩn';
    final displayTip =
        advice?.bodyProportionTip ?? fallbackAnalysis.defaultProportionTip;
    final displayWarnings =
        (advice?.fitWarnings != null && advice!.fitWarnings.isNotEmpty)
            ? advice.fitWarnings
            : fallbackAnalysis.fitWarnings;
    final displayBmi = advice?.bmi ?? fallbackAnalysis.bmi;
    final displayFrame = advice?.bodyFrame ?? fallbackAnalysis.bodyFrame;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.primaryLight.withOpacity(0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header: Tiêu đề Smart Fit & Nút chỉnh thông số thể trạng ───────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.accessibility_new_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tư Vấn Smart Fit & Thể Trạng',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${currentHeightCm.toInt()}cm • ${currentWeightKg.toInt()}kg • BMI $displayBmi ($displayFrame)',
                      style: GoogleFonts.inter(
                        color: AppTheme.primaryLight,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (onMeasurementsChanged != null)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.06),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.tune_rounded,
                      color: Colors.white70, size: 14),
                  label: Text(
                    'Đổi số đo',
                    style:
                        GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                  ),
                  onPressed: () => _showQuickAdjustDialog(context),
                ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 14),

          // ─── Chỉ số điểm thẩm mỹ & màu sắc ────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildScorePill(
                  label: 'Điểm Thanh Lịch',
                  score: outfit.eleganceScore,
                  icon: Icons.auto_awesome_rounded,
                  color: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildScorePill(
                  label: 'Hài Hòa Màu Sắc',
                  score: outfit.colorScore,
                  icon: Icons.palette_rounded,
                  color: AppTheme.accentColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ColorScoreScreen(
                          initialTitle: 'Phối Màu: ${outfit.name}',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ─── 1. Form Dáng & Size đề xuất ──────────────────────────────────
          _buildInfoRow(
            icon: '🏷️',
            title: 'Form dáng & Size:',
            content: displaySize,
            textColor: Colors.white,
            highlightColor: AppTheme.primaryLight,
          ),

          const SizedBox(height: 12),

          // ─── 2. Mẹo Tôn Dáng (Body Proportion Tip) ────────────────────────
          _buildInfoRow(
            icon: '💡',
            title: 'Mẹo tôn vóc dáng:',
            content: displayTip,
            textColor: const Color(0xFFE2E4F0),
            backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
            borderColor: AppTheme.primaryLight.withOpacity(0.2),
          ),

          // ─── 3. Cảnh báo tỷ lệ chiều dài (Length Hazard Warnings) ─────────
          if (displayWarnings.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...displayWarnings.map(
              (warning) => _buildInfoRow(
                icon: '⚠️',
                title: 'Lưu ý độ dài:',
                content: warning,
                textColor: const Color(0xFFFFE0B2),
                backgroundColor: Colors.amber.withOpacity(0.08),
                borderColor: Colors.amber.withOpacity(0.3),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScorePill({
    required String label,
    required double score,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                          color: Colors.white54, fontSize: 10),
                    ),
                    Text(
                      '${score.toStringAsFixed(1)} / 10',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String icon,
    required String title,
    required String content,
    required Color textColor,
    Color? highlightColor,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return Container(
      padding: backgroundColor != null
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
          : EdgeInsets.zero,
      decoration: backgroundColor != null
          ? BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor ?? Colors.transparent),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(fontSize: 12.5, height: 1.4),
                children: [
                  TextSpan(
                    text: '$title ',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: highlightColor ?? Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: content,
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickAdjustDialog(BuildContext context) {
    double h = currentHeightCm;
    double w = currentWeightKg;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final bmi = w / ((h / 100) * (h / 100));
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Điều Chỉnh Thể Trạng Thử Nghiệm',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Thử nghiệm xem Layering Canvas và Smart Fit tự động thích ứng với thể trạng:',
                    style:
                        GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  // Slider Chiều cao
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Chiều cao:',
                          style: GoogleFonts.inter(color: Colors.white)),
                      Text(
                        '${h.toInt()} cm',
                        style: GoogleFonts.outfit(
                          color: AppTheme.primaryLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: h,
                    min: 145,
                    max: 195,
                    divisions: 50,
                    activeColor: AppTheme.primaryLight,
                    onChanged: (val) => setModalState(() => h = val),
                  ),
                  // Slider Cân nặng
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cân nặng:',
                          style: GoogleFonts.inter(color: Colors.white)),
                      Text(
                        '${w.toInt()} kg (BMI: ${bmi.toStringAsFixed(1)})',
                        style: GoogleFonts.outfit(
                          color: AppTheme.accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: w,
                    min: 35,
                    max: 110,
                    divisions: 75,
                    activeColor: AppTheme.accentColor,
                    onChanged: (val) => setModalState(() => w = val),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      onMeasurementsChanged?.call(h, w);
                    },
                    child: Text(
                      'Áp Dụng Thể Trạng Mới',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
