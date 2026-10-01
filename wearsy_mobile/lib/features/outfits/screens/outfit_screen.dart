import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/outfit_model.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/outfit_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../wardrobe/providers/wardrobe_provider.dart';
import 'outfit_detail_screen.dart';

class OutfitScreen extends StatelessWidget {
  const OutfitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _OutfitBody();
  }
}

class _OutfitBody extends StatelessWidget {
  const _OutfitBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildOccasionFilter(context),
            Expanded(child: _buildOutfitList(context)),
          ],
        ),
      ),
      floatingActionButton: _buildGenerateFAB(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Outfit Gợi Ý',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Phối đồ thông minh với Gemini AI',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.darkTextSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Gemini AI',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOccasionFilter(BuildContext context) {
    final provider = Provider.of<OutfitProvider>(context);
    final occasions = [null, ...OutfitOccasion.values];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: occasions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final occ = occasions[index];
          final isSelected = provider.selectedOccasion == occ;
          final label = occ == null ? 'Tất cả' : occ.displayName;
          final icon = occ == null ? '✨' : occ.icon;

          return GestureDetector(
            onTap: () => provider.setOccasion(occ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.primaryGradient : null,
                color: isSelected ? null : AppTheme.darkCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : AppTheme.darkTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOutfitList(BuildContext context) {
    final provider = Provider.of<OutfitProvider>(context);

    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryLight),
      );
    }

    if (provider.isGenerating) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryLight),
            const SizedBox(height: 20),
            Text(
              '✨ Gemini AI đang phân tích tủ đồ...',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đang tìm kiếm tổ hợp màu sắc tối ưu',
              style: GoogleFonts.inter(
                color: AppTheme.darkTextSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final outfits = provider.filteredOutfits;
    if (outfits.isEmpty) {
      final isWardrobeEmpty =
          Provider.of<WardrobeProvider>(context).allItems.isEmpty;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.secondaryColor.withOpacity(0.25)),
                ),
                child: const Icon(Icons.auto_awesome_outlined,
                    color: AppTheme.secondaryColor, size: 40),
              ),
              const SizedBox(height: 18),
              Text(
                isWardrobeEmpty
                    ? 'Chưa có outfit AI nào'
                    : 'Chưa có outfit cho dịp này',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isWardrobeEmpty
                    ? 'Tài khoản mới bắt đầu từ tủ đồ trống. Hãy thêm các món đồ yêu thích để AI tự động phối outfit!'
                    : 'Nhấn "Tạo Outfit Mới" để AI phân tích và đề xuất set đồ phù hợp ngay!',
                style: GoogleFonts.inter(
                    color: AppTheme.darkTextSecondary,
                    fontSize: 13,
                    height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: outfits.length,
      itemBuilder: (context, index) => _OutfitCard(outfit: outfits[index]),
    );
  }

  Widget _buildGenerateFAB(BuildContext context) {
    final provider = Provider.of<OutfitProvider>(context);

    return FloatingActionButton.extended(
      onPressed: provider.isGenerating
          ? null
          : () {
              final wardrobe =
                  Provider.of<WardrobeProvider>(context, listen: false);
              if (wardrobe.allItems.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Tủ đồ của bạn đang trống! Hãy thêm quần áo vào tủ để AI phối outfit nhé.',
                      style: GoogleFonts.inter(),
                    ),
                    backgroundColor: AppTheme.warningColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
                return;
              }

              final auth = Provider.of<AuthProvider>(context, listen: false);
              final bm = auth.user?.bodyMeasurements;
              final h = (bm?['height'] as num?)?.toDouble() ?? 172.0;
              final w = (bm?['weight'] as num?)?.toDouble() ?? 65.0;

              provider.generateNewOutfit(
                availableItems: wardrobe.allItems,
                heightCm: h,
                weightKg: w,
                gender: auth.user?.fullName.toLowerCase().contains('nữ') == true
                    ? 'Nữ'
                    : 'Nam',
              );
            },
      backgroundColor: provider.isGenerating ? AppTheme.darkSurface : null,
      icon: provider.isGenerating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
          : const Icon(Icons.auto_fix_high_rounded, color: Colors.white),
      label: Text(
        provider.isGenerating
            ? 'Đang phân tích Smart Fit...'
            : 'Tạo Outfit Smart Fit',
        style: GoogleFonts.outfit(
            color: Colors.white, fontWeight: FontWeight.bold),
      ),
      extendedIconLabelSpacing: 8,
    );
  }
}

class _OutfitCard extends StatelessWidget {
  final OutfitModel outfit;
  const _OutfitCard({required this.outfit});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OutfitProvider>(context, listen: false);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: provider,
            child: OutfitDetailScreen(outfit: outfit),
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Cover image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: Stack(
                children: [
                  Image.network(
                    outfit.coverImageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: AppTheme.darkSurface,
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: AppTheme.primaryLight, size: 48),
                    ),
                  ),
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppTheme.darkCard.withOpacity(0.95),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Occasion & 2D Canvas badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(outfit.occasion.icon,
                                  style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 4),
                              Text(
                                outfit.occasion.displayName,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.primaryColor,
                                AppTheme.accentColor
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.layers_rounded,
                                  color: Colors.white, size: 12),
                              const SizedBox(width: 3),
                              Text(
                                '2D Canvas',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Favorite button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Consumer<OutfitProvider>(
                      builder: (_, prov, __) {
                        final isFav = prov.outfits
                            .firstWhere((o) => o.id == outfit.id,
                                orElse: () => outfit)
                            .isFavorite;
                        return GestureDetector(
                          onTap: () => prov.toggleFavorite(outfit.id),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color:
                                  isFav ? AppTheme.accentColor : Colors.white,
                              size: 18,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // AI score badge
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            outfit.aiScore.toStringAsFixed(1),
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    outfit.name,
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (outfit.smartFitAdvice != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppTheme.primaryLight.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🏷️', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              outfit.smartFitAdvice!.sizeRecommendation,
                              style: GoogleFonts.inter(
                                color: AppTheme.primaryLight,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Text(
                    outfit.aiReason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.darkTextSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.wb_sunny_outlined,
                          color: AppTheme.warningColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        outfit.weatherSuitable.join(', '),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.warningColor,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${outfit.itemIds.length} món',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.primaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: AppTheme.primaryLight, size: 12),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
