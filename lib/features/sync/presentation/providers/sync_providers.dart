import 'dart:io';

import 'package:clipboard/features/macos/index/providers/clipboard_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/shared_preferences_provider.dart';
import '../../data/datasources/lan_sync_datasource.dart';
import '../../data/repositories/sync_repository_impl.dart';
import '../../domain/entities/sync_hub_state.dart';
import '../../domain/repositories/sync_repository.dart';

final lanSyncDatasourceProvider = Provider<LanSyncDatasource>((ref) {
  final repository = ref.watch(clipboardRepositoryProvider).valueOrNull;
  if (repository == null) throw StateError('剪贴板数据库尚未就绪');
  final preferences = ref.watch(sharedPreferencesProvider).valueOrNull;
  if (preferences == null) throw StateError('本地设置尚未就绪');
  final datasource = LanSyncDatasource(
    clipboardRepository: repository,
    preferences: preferences,
  );
  ref.onDispose(datasource.stopHub);
  return datasource;
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  final clipboard = ref.watch(clipboardRepositoryProvider).valueOrNull;
  if (clipboard == null) throw StateError('剪贴板数据库尚未就绪');
  return SyncRepositoryImpl(
    datasource: ref.watch(lanSyncDatasourceProvider),
    clipboardRepository: clipboard,
  );
});

final syncHubProvider = StreamProvider<SyncHubState>((ref) async* {
  if (!Platform.isMacOS && !Platform.isWindows) {
    yield const SyncHubState.stopped();
    return;
  }
  final repository = ref.watch(syncRepositoryProvider);
  yield await repository.startHub();
  yield* repository.hubStates;
});
