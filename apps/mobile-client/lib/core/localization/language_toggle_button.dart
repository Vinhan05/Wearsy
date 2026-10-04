import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import 'language_provider.dart';

enum LanguageToggleStyle {
  /// Compact pill button for Headers and AppBars (Flag + Code + swap icon)
  compact,

  /// Segmented switch showing both [ 🇻🇳 VI | 🇬🇧 EN ]
  segmented,

  /// Full width setting card matching Profile/Settings screen aesthetics
  card,
}

class LanguageToggleButton extends StatefulWidget {
  final LanguageToggleStyle style;
  final bool showFeedbackToast;

  const LanguageToggleButton({
    super.key,
    this.style = LanguageToggleStyle.compact,
    this.showFeedbackToast = true,
  });

  const LanguageToggleButton.segmented({
    super.key,
    this.showFeedbackToast = true,
  }) : style = LanguageToggleStyle.segmented;

  const LanguageToggleButton.card({
    super.key,
    this.showFeedbackToast = true,
  }) : style = LanguageToggleStyle.card;

  @override
  State<LanguageToggleButton> createState() => _LanguageToggleButtonState();
}

class _LanguageToggleButtonState extends State<LanguageToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleToggle(BuildContext context, LanguageProvider langProvider) async {
    // Play quick tap animation
    await _animController.forward();
    await _animController.reverse();

    final prevIsVi = langProvider.isVietnamese;
    await langProvider.toggleLanguage();

    if (!context.mounted) return;

    if (widget.showFeedbackToast) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                prevIsVi ? '🇬🇧 ' : '🇻🇳 ',
                style: const TextStyle(fontSize: 18),
              ),
              Expanded(
                child: Text(
                  prevIsVi
                      ? 'Switched to English'
                      : 'Đã đổi sang Tiếng Việt',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF2C2849),
          margin: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final activePalette = themeProvider.currentPalette;

    if (widget.style == LanguageToggleStyle.card) {
      return _buildCardStyle(context, langProvider, activePalette);
    }

    if (widget.style == LanguageToggleStyle.segmented) {
      return _buildSegmentedStyle(context, langProvider, activePalette);
    }

    return _buildCompactStyle(context, langProvider, activePalette);
  }

  Widget _buildCompactStyle(
    BuildContext context,
    LanguageProvider langProvider,
    dynamic activePalette,
  ) {
    final isVi = langProvider.isVietnamese;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: Tooltip(
        message: isVi ? 'Đổi sang English' : 'Switch to Tiếng Việt',
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleToggle(context, langProvider),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: activePalette.primary.withOpacity(0.25),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: activePalette.primary.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Flag
                Text(
                  langProvider.currentFlag,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 5),
                // Code
                Text(
                  langProvider.currentShortCode,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: activePalette.primary,
                  ),
                ),
                const SizedBox(width: 4),
                // Swap Icon
                Icon(
                  Icons.sync_alt_rounded,
                  size: 14,
                  color: AppTheme.darkTextSecondary.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedStyle(
    BuildContext context,
    LanguageProvider langProvider,
    dynamic activePalette,
  ) {
    final isVi = langProvider.isVietnamese;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EEF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSegmentItem(
            title: '🇻🇳 VI',
            isSelected: isVi,
            activePalette: activePalette,
            onTap: () {
              if (!isVi) _handleToggle(context, langProvider);
            },
          ),
          const SizedBox(width: 2),
          _buildSegmentItem(
            title: '🇬🇧 EN',
            isSelected: !isVi,
            activePalette: activePalette,
            onTap: () {
              if (isVi) _handleToggle(context, langProvider);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentItem({
    required String title,
    required bool isSelected,
    required dynamic activePalette,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? activePalette.primary
                : AppTheme.darkTextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCardStyle(
    BuildContext context,
    LanguageProvider langProvider,
    dynamic activePalette,
  ) {
    final isVi = langProvider.isVietnamese;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _handleToggle(context, langProvider),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: activePalette.primary.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: activePalette.primary.withOpacity(0.2),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: activePalette.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.translate_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVi ? 'Ngôn ngữ ứng dụng' : 'App Language',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: activePalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isVi ? 'Tiếng Việt (Mặc định)' : 'English (US)',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: activePalette.primary,
                    ),
                  ),
                ],
              ),
            ),
            // Language Toggle Capsule
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: activePalette.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    langProvider.currentFlag,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    langProvider.currentShortCode,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: activePalette.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.sync_alt_rounded,
                    size: 14,
                    color: activePalette.primary,
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
