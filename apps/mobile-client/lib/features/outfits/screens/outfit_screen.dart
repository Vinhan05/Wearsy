import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/outfit_model.dart';
import 'ai_stylist_chat_screen.dart';
import 'outfit_detail_screen.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/language_provider.dart';

class OutfitScreen extends StatefulWidget {
  const OutfitScreen({super.key});

  @override
  State<OutfitScreen> createState() => _OutfitScreenState();
}

class _OutfitScreenState extends State<OutfitScreen> {
  // 1. Ngữ cảnh
  String _selectedContext = 'Đi làm';

  // 2. Thời tiết
  String _selectedWeather = 'Nắng';

  // 3. Phong cách
  String _selectedStyle = 'Tối giản';

  bool _isGenerating = false;

  void _generateOutfit() async {
    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isGenerating = false);

    final newOutfit = OutfitModel(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      name: '$_selectedStyle • $_selectedContext',
      aiReason: 'Gọn gàng, hiện đại và phù hợp cho thời tiết $_selectedWeather.',
      occasion: OutfitOccasion.casual,
      weatherSuitable: [_selectedWeather],
      aiScore: 9.8,
      coverImageUrl: 'assets/images/outfit_detail_mannequin.jpg',
      itemIds: [],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OutfitDetailScreen(outfit: newOutfit),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Step Indicator & History Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Step Indicator Dots
                  Row(
                    children: [
                      _buildStepDot(isActive: false, isCompleted: true),
                      _buildStepLine(),
                      _buildStepDot(isActive: false, isCompleted: true),
                      _buildStepLine(),
                      _buildStepDot(isActive: true, isCompleted: false),
                    ],
                  ),
                  // History Button
                  Builder(
                    builder: (ctx) {
                      final isEn = Provider.of<LanguageProvider>(ctx).isEnglish;
                      return GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEn
                                  ? '🕒 Showing recent outfit history'
                                  : '🕒 Đang hiển thị lịch sử phối đồ gần nhất'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 14, color: Color(0xFF374151)),
                              const SizedBox(width: 6),
                              Text(
                                isEn ? 'History' : 'Lịch sử',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Header Row: Title & 3D Mannequin in Arch Showcase
              Builder(
                builder: (context) {
                  final isEn = Provider.of<LanguageProvider>(context).isEnglish;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEn ? 'Style with\nAI' : 'Phối đồ\ncùng AI',
                              style: GoogleFonts.outfit(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isEn ? 'Where are you going?' : 'Bạn sắp đi đâu?',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/mannequin_arch.jpg',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Section 1: Chọn ngữ cảnh
              Builder(
                builder: (context) {
                  final isEn = Provider.of<LanguageProvider>(context).isEnglish;
                  final displayContexts = [
                    {'label': isEn ? 'Work' : 'Đi làm', 'raw': 'Đi làm', 'icon': Icons.work_outline_rounded},
                    {'label': isEn ? 'Casual' : 'Đi chơi', 'raw': 'Đi chơi', 'icon': Icons.local_cafe_outlined},
                    {'label': isEn ? 'Date' : 'Hẹn hò', 'raw': 'Hẹn hò', 'icon': Icons.favorite_border_rounded},
                    {'label': isEn ? 'Travel' : 'Du lịch', 'raw': 'Du lịch', 'icon': Icons.luggage_outlined},
                  ];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEn ? 'Select Occasion' : 'Chọn ngữ cảnh',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: displayContexts.map((c) {
                          final isSelected = _selectedContext == c['raw'] || _selectedContext == c['label'];
                          return Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedContext = c['raw'] as String),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryLight.withOpacity(0.08)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryLight
                                        : const Color(0xFFE5E7EB),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      c['icon'] as IconData,
                                      size: 24,
                                      color: isSelected
                                          ? AppTheme.primaryLight
                                          : const Color(0xFF4B5563),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      c['label'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppTheme.primaryLight
                                            : const Color(0xFF374151),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // Section 2: Thời tiết
              Builder(
                builder: (context) {
                  final isEn = Provider.of<LanguageProvider>(context).isEnglish;
                  final displayWeathers = [
                    {'label': isEn ? 'Sunny' : 'Nắng', 'raw': 'Nắng', 'icon': Icons.wb_sunny_outlined},
                    {'label': isEn ? 'Cloudy' : 'Nhiều mây', 'raw': 'Nhiều mây', 'icon': Icons.cloud_outlined},
                    {'label': isEn ? 'Rainy' : 'Mưa nhẹ', 'raw': 'Mưa nhẹ', 'icon': Icons.grain_rounded},
                    {'label': isEn ? 'Cool' : 'Mát mẻ', 'raw': 'Mát mẻ', 'icon': Icons.air_rounded},
                    {'label': isEn ? 'Cold' : 'Lạnh', 'raw': 'Lạnh', 'icon': Icons.ac_unit_rounded},
                  ];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEn ? 'Weather' : 'Thời tiết',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: displayWeathers.map((w) {
                          final isSelected = _selectedWeather == w['raw'] || _selectedWeather == w['label'];
                          return Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedWeather = w['raw'] as String),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryLight.withOpacity(0.08)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryLight
                                        : const Color(0xFFE5E7EB),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      w['icon'] as IconData,
                                      size: 20,
                                      color: isSelected
                                          ? AppTheme.primaryLight
                                          : const Color(0xFF4B5563),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      w['label'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppTheme.primaryLight
                                            : const Color(0xFF374151),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // Section 3: Phong cách
              Builder(
                builder: (context) {
                  final isEn = Provider.of<LanguageProvider>(context).isEnglish;
                  final displayStyles = [
                    {'label': isEn ? 'Minimalist' : 'Tối giản', 'raw': 'Tối giản'},
                    {'label': isEn ? 'Smart casual' : 'Smart casual', 'raw': 'Smart casual'},
                    {'label': isEn ? 'Elegant' : 'Thanh lịch', 'raw': 'Thanh lịch'},
                    {'label': isEn ? 'Active' : 'Năng động', 'raw': 'Năng động'},
                  ];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEn ? 'Style' : 'Phong cách',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: displayStyles.map((s) {
                            final isSelected = _selectedStyle == s['raw'] || _selectedStyle == s['label'];
                            return GestureDetector(
                              onTap: () => setState(() => _selectedStyle = s['raw']!),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryLight.withOpacity(0.08)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryLight
                                        : const Color(0xFFE5E7EB),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_off,
                                      size: 16,
                                      color: isSelected
                                          ? AppTheme.primaryLight
                                          : const Color(0xFF9CA3AF),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      s['label']!,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppTheme.primaryLight
                                            : const Color(0xFF374151),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              // Action Button 1: "Tạo outfit"
              Builder(
                builder: (context) {
                  final isEn = Provider.of<LanguageProvider>(context).isEnglish;
                  return GestureDetector(
                    onTap: _isGenerating ? null : _generateOutfit,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF27272A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: _isGenerating
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.auto_awesome,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    isEn ? 'Create Outfit' : 'Tạo outfit',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Action Button 2: "Trò chuyện với wearsy AI"
              Builder(
                builder: (context) {
                  final isEn = Provider.of<LanguageProvider>(context).isEnglish;
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AiStylistChatScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF27272A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('AI',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isEn ? 'Chat with Wearsy AI' : 'Trò chuyện với wearsy AI',
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepDot({required bool isActive, required bool isCompleted}) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primaryLight
            : (isCompleted ? const Color(0xFF9CA3AF) : const Color(0xFFE5E7EB)),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 24,
      height: 2,
      color: const Color(0xFFE5E7EB),
    );
  }
}
