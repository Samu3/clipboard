import 'dart:io';

import 'package:clipboard/core/database/database_provider.dart';
import 'package:clipboard/features/macos/index/data/datasources/clipboard_local_datasource.dart';
import 'package:clipboard/features/macos/index/data/repositories/clipboard_repository_impl.dart';
import 'package:clipboard/features/macos/index/domain/repositories/clipboard_repository.dart';
import 'package:clipboard/features/macos/index/domain/usecases/add_clipboard_entry_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clipboard_providers.g.dart';

/// 缓存目录 Provider，全局只执行一次
final appCacheDirProvider = FutureProvider<Directory>((ref) async {
  final dir = await getApplicationCacheDirectory();
  return dir;
});

// 筛选类型：all / text / image / file / favorite
final clipboardFilterProvider = StateProvider<String>((ref) => 'all');
// 搜索关键词
final clipboardSearchKeywordProvider = StateProvider<String>((ref) => '');

// 本地数据源，依赖数据库Future
@riverpod
Future<ClipboardLocalDatasource> clipboardLocalDatasource(
    ClipboardLocalDatasourceRef ref) async {
  final db = await ref.watch(databaseProvider.future);
  return ClipboardLocalDatasource(db: db);
}

// Repository，注意：外层是Future，因为依赖上面FutureProvider
@riverpod
Future<ClipboardRepository> clipboardRepository(
    ClipboardRepositoryRef ref) async {
  final ds = await ref.watch(clipboardLocalDatasourceProvider.future);
  return ClipboardRepositoryImpl(localDs: ds);
}

// UseCase
@riverpod
Future<AddClipboardEntryUseCase> addClipboardEntryUseCase(
    AddClipboardEntryUseCaseRef ref) async {
  final repo = await ref.watch(clipboardRepositoryProvider.future);
  return AddClipboardEntryUseCase(repo);
}
