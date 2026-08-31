import '../entities/language.dart';

abstract class LocaleRepository {
  Future<Map<String, String>> getAvailableLanguages();
  Future<String> getCurrentLanguage();
  Future<void> setLanguage(String languageCode);
}
