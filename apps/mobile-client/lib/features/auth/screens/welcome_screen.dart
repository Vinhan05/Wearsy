import 'package:flutter/material.dart';
import 'package:wearsy_mobile/core/theme/app_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final activeId = themeProvider.currentThemeId;
    final isTheme1 = activeId == 'theme_1';
    final isTheme2 = activeId == 'theme_2';

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        },
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // Full screen background image anchored to topCenter for crisp header & logo
              Positioned.fill(
                child: Image.asset(
                  'assets/images/welcome_screen_bg.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),

              // Subtle tone harmonizer overlay for Theme 2 & other themes
              if (!isTheme1)
                Positioned.fill(
                  child: Container(
                    color: isTheme2
                        ? const Color(0xFF543D37).withOpacity(0.08)
                        : AppTheme.primaryColor.withOpacity(0.08),
                  ),
                ),

              // Dynamic GET STARTED button matching active theme
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 28,
                left: 32,
                right: 32,
                child: GestureDetector(
                  key: const Key('welcome_get_started_btn'),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: isTheme1
                          ? const Color(0xFFC4B8FA) // Exact Lavender button matching palette
                          : isTheme2
                              ? const Color(0xFF543D37) // Exact Mocha Cacao from 2.png
                              : AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: (isTheme1
                                  ? const Color(0xFF8174DB)
                                  : isTheme2
                                      ? const Color(0xFF543D37)
                                      : AppTheme.primaryColor)
                              .withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'GET STARTED',
                            style: AppFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: isTheme1
                                  ? const Color(0xFF2C2849)
                                  : Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: isTheme1
                                ? const Color(0xFF2C2849)
                                : Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
