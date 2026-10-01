import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
              // Full screen background image
              Positioned.fill(
                child: Image.asset(
                  'assets/images/welcome_screen_bg.png',
                  fit: BoxFit.cover,
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
                bottom: MediaQuery.of(context).padding.bottom + 24,
                left: 36,
                right: 36,
                child: GestureDetector(
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
                          ? const Color(0xFFC4B8FA) // Exact Lavender button from 1.png
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
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'GET STARTED',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: isTheme1 ? const Color(0xFF2C2849) : Colors.white,
                        ),
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

