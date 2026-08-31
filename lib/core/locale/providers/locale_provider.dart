import 'package:intl/locale.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clipboard/core/channel/native_channel.dart';
import 'package:clipboard/core/locale/data/api/locale_api_service.dart';
import 'package:clipboard/core/utils/logger.dart';
import '../data/datasources/locale_datasource.dart';
import '../data/repositories/locale_repository_impl.dart';
import '../domain/entities/language.dart';
import '../domain/repositories/locale_repository.dart';

part 'locale_provider.g.dart';

// SharedPreferences provider (需要在 main.dart 中 override)
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(SharedPreferencesRef ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
}

// 数据源provider
@Riverpod(keepAlive: true)
LocaleDatasource localeDatasource(LocaleDatasourceRef ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final api = ref.watch(localeApiServiceProvider);

  return LocaleDatasource(prefs, api);
}

// 仓库provider
@Riverpod(keepAlive: true)
LocaleRepository localeRepository(LocaleRepositoryRef ref) {
  final ds = ref.watch(localeDatasourceProvider);
  return LocaleRepositoryImpl(ds);
}

// 当前语言
@Riverpod(keepAlive: true)
class CurrentLanguage extends _$CurrentLanguage {
  String? _lastLoadedLang;

  @override
  Future<String> build() async {
    final repo = ref.watch(localeRepositoryProvider);

    final lang = await repo.getCurrentLanguage();

    // 如果和上次加载的语言相同，跳过加载
    if (_lastLoadedLang == lang) {
      return lang;
    }
    final localDataSource = ref.watch(localeDatasourceProvider);

    await localDataSource.getAvailableLanguages(lang);
    await localDataSource.getRemoteLanguageTexts(lang);

    _lastLoadedLang = lang;

    return lang;
  }

  /// 更新认证状态
  void updateAuthState(String newState) {
    state = AsyncValue.data(newState);
  }

  /// 切换语言
  Future<void> changeLanguage(String languageCode) async {
    logger.methodChannel('🌍 Changing language to: $languageCode');

    // 检查是否和当前语言相同
    final currentLang = state.valueOrNull;
    if (currentLang == languageCode) {
      logger.methodChannel('🌍 Language is already $languageCode, skipping');
      return;
    }
    final localDataSource = ref.watch(localeDatasourceProvider);

    await localDataSource.getAvailableLanguages(languageCode);
    await localDataSource.getRemoteLanguageTexts(languageCode);

    updateAuthState(languageCode);

    // 先保存语言设置
    final repo = ref.read(localeRepositoryProvider);

    await repo.setLanguage(languageCode);

    logger.methodChannel('🌍 Language saved to: $languageCode');

    // 重新加载 CurrentLanguage，触发 build() 重新执行
    // ref.invalidateSelf();
  }
}
