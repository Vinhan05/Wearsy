import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';

extension LocalizationExtension on BuildContext {
  /// Translates key and listens to language changes
  String tr(String key, {Map<String, dynamic>? params}) {
    return Provider.of<LanguageProvider>(this).tr(key, params: params);
  }

  /// Read LanguageProvider without registering as listener
  LanguageProvider get languageProviderRead {
    return Provider.of<LanguageProvider>(this, listen: false);
  }

  /// Watch LanguageProvider to rebuild on changes
  LanguageProvider get languageProviderWatch {
    return Provider.of<LanguageProvider>(this);
  }
}
