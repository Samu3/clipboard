import 'package:clipboard/core/locale/providers/locale_provider.dart';
import 'package:clipboard/features/macos/settings/data/repositories/settings_repository_impl.dart';
import 'package:clipboard/features/macos/settings/domain/repositories/settings_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_providers.g.dart';

@riverpod
SettingsRepository settingsRepository(SettingsRepositoryRef ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsRepositoryImpl(prefs);
}
