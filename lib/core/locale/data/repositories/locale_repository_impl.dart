import '../../domain/entities/language.dart';
import '../../domain/repositories/locale_repository.dart';
import '../datasources/locale_datasource.dart';

class LocaleRepositoryImpl implements LocaleRepository {
  final LocaleDatasource datasource;

  LocaleRepositoryImpl(this.datasource);

  @override
  Future<Map<String, String>> getAvailableLanguages() async {
    final lang = await datasource.getCurrentLanguage();
    final data = await datasource.getAvailableLanguages(lang);
    return data;
  }

  @override
  Future<String> getCurrentLanguage() {
    return datasource.getCurrentLanguage();
  }

  @override
  Future<void> setLanguage(String languageCode) {
    return datasource.setLanguage(languageCode);
  }
}
