import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wearsy_mobile/core/localization/localization.dart';
import 'package:wearsy_mobile/core/theme/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppTranslations Tests', () {
    test('Translates standard keys for VI and EN', () {
      expect(AppTranslations.translate('nav_home', AppTranslations.vi), 'Trang chủ');
      expect(AppTranslations.translate('nav_home', AppTranslations.en), 'Home');

      expect(AppTranslations.translate('btn_save', AppTranslations.vi), 'Lưu');
      expect(AppTranslations.translate('btn_save', AppTranslations.en), 'Save');

      expect(AppTranslations.translate('settings_logout', AppTranslations.vi), 'Đăng xuất');
      expect(AppTranslations.translate('settings_logout', AppTranslations.en), 'Log Out');
    });

    test('Interpolates placeholders in translations correctly', () {
      final viGreeting = AppTranslations.translate(
        'home_greeting_morning',
        AppTranslations.vi,
        params: {'userName': 'Lan'},
      );
      expect(viGreeting, contains('Lan'));

      final enGreeting = AppTranslations.translate(
        'home_greeting_morning',
        AppTranslations.en,
        params: {'userName': 'John'},
      );
      expect(enGreeting, contains('Good morning John!'));

      final countItems = AppTranslations.translate(
        'home_total_items',
        AppTranslations.en,
        params: {'count': 15},
      );
      expect(countItems, '15 items');
    });

    test('Falls back gracefully for unknown keys', () {
      expect(AppTranslations.translate('unknown_key_123', AppTranslations.vi), 'unknown_key_123');
      expect(AppTranslations.translate('unknown_key_123', AppTranslations.en), 'unknown_key_123');
    });
  });

  group('LanguageProvider Tests', () {
    test('Defaults to Vietnamese', () {
      final provider = LanguageProvider();
      expect(provider.currentLanguage, 'vi');
      expect(provider.isVietnamese, true);
      expect(provider.isEnglish, false);
      expect(provider.currentFlag, '🇻🇳');
      expect(provider.currentShortCode, 'VI');
      expect(provider.targetFlag, '🇬🇧');
      expect(provider.targetShortCode, 'EN');
    });

    test('Toggles language from VI to EN and back to VI', () async {
      final provider = LanguageProvider();

      await provider.toggleLanguage();
      expect(provider.currentLanguage, 'en');
      expect(provider.isVietnamese, false);
      expect(provider.isEnglish, true);
      expect(provider.currentFlag, '🇬🇧');
      expect(provider.currentShortCode, 'EN');

      await provider.toggleLanguage();
      expect(provider.currentLanguage, 'vi');
      expect(provider.isVietnamese, true);
      expect(provider.currentFlag, '🇻🇳');
    });

    test('setLanguage ignores invalid language codes', () async {
      final provider = LanguageProvider();
      await provider.setLanguage('invalid_code');
      expect(provider.currentLanguage, 'vi');
    });
  });

  group('LanguageToggleButton Widget Tests', () {
    testWidgets('Renders compact button and toggles language on tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: LanguageToggleButton(
                  style: LanguageToggleStyle.compact,
                  showFeedbackToast: false,
                ),
              ),
            ),
          ),
        ),
      );

      // Initially displays VI and Vietnam flag
      expect(find.text('VI'), findsOneWidget);
      expect(find.text('🇻🇳'), findsOneWidget);

      // Tap button to switch language
      await tester.tap(find.byType(LanguageToggleButton));
      await tester.pumpAndSettle();

      // Now displays EN and UK flag
      expect(find.text('EN'), findsOneWidget);
      expect(find.text('🇬🇧'), findsOneWidget);

      // Tap button again to switch back
      await tester.tap(find.byType(LanguageToggleButton));
      await tester.pumpAndSettle();

      // Back to VI
      expect(find.text('VI'), findsOneWidget);
      expect(find.text('🇻🇳'), findsOneWidget);
    });

    testWidgets('Renders card style in Profile/Settings', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: LanguageToggleButton.card(showFeedbackToast: false),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Ngôn ngữ ứng dụng'), findsOneWidget);
      expect(find.text('Tiếng Việt (Mặc định)'), findsOneWidget);

      await tester.tap(find.byType(LanguageToggleButton));
      await tester.pumpAndSettle();

      expect(find.text('App Language'), findsOneWidget);
      expect(find.text('English (US)'), findsOneWidget);
    });
  });
}
