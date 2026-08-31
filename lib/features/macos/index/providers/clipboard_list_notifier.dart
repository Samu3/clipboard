import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:clipboard/features/macos/index/domain/entities/clipboard_entry.dart';
import 'package:clipboard/features/macos/index/domain/repositories/clipboard_repository.dart';
import 'package:clipboard/features/macos/index/providers/clipboard_providers.dart';

part 'clipboard_list_notifier.g.dart';

@riverpod
class ClipboardListNotifier extends _$ClipboardListNotifier {
  int _offset = 0;
  bool _hasMore = true;
  final int _pageSize = 50;
  List<ClipboardEntry> _cacheList = [];

  bool get hasMore => _hasMore;

  @override
  Future<List<ClipboardEntry>> build() async {
    // 每次build读取repo，不再存late成员
    final repo = await ref.watch(clipboardRepositoryProvider.future);
    final filter = ref.watch(clipboardFilterProvider);
    final keyword = ref.watch(clipboardSearchKeywordProvider);

    // 筛选/搜索条件变化，重置分页，重新加载第一页
    _offset = 0;
    _hasMore = true;
    _cacheList.clear();

    final pageData = await repo.getActiveEntries(
      filter: filter,
      keyword: keyword,
      limit: _pageSize,
      offset: _offset,
    );
    _cacheList = pageData;
    if (pageData.length < _pageSize) {
      _hasMore = false;
    }
    return _cacheList;
  }

  /// 加载下一页
  Future<void> loadMore() async {
    if (!_hasMore) return;
    state = AsyncLoading();
    try {
      final repo = await ref.watch(clipboardRepositoryProvider.future);
      final filter = ref.watch(clipboardFilterProvider);
      final keyword = ref.watch(clipboardSearchKeywordProvider);
      _offset += _pageSize;
      final nextPage = await repo.getActiveEntries(
        filter: filter,
        keyword: keyword,
        limit: _pageSize,
        offset: _offset,
      );
      if (nextPage.isEmpty || nextPage.length < _pageSize) {
        _hasMore = false;
      }
      _cacheList.addAll(nextPage);
      state = AsyncData(List.from(_cacheList));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 下拉刷新
  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repo = await ref.watch(clipboardRepositoryProvider.future);
      final filter = ref.watch(clipboardFilterProvider);
      final keyword = ref.watch(clipboardSearchKeywordProvider);
      _offset = 0;
      _hasMore = true;
      final pageData = await repo.getActiveEntries(
        filter: filter,
        keyword: keyword,
        limit: _pageSize,
        offset: _offset,
      );
      _cacheList = pageData;
      if (pageData.length < _pageSize) {
        _hasMore = false;
      }
      state = AsyncData(List.from(_cacheList));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 切换收藏
  Future<void> toggleFavorite(String entryId) async {
    final list = state.valueOrNull;
    if (list == null) return;

    final repo = await ref.watch(clipboardRepositoryProvider.future);
    final entry = list.firstWhere((e) => e.id == entryId);
    final now = DateTime.now().millisecondsSinceEpoch;
    final maxSeq = await repo.getMaxSeq();
    final newSeq = maxSeq + 1;

    final updatedEntry = entry.copyWith(
      favorite: entry.favorite == 1 ? 0 : 1,
      seq: newSeq,
      updatedAt: now,
    );
    await repo.updateEntry(updatedEntry);

    final newList = list.map((item) {
      if (item.id == entryId) return updatedEntry;
      return item;
    }).toList();
    _cacheList = newList;
    state = AsyncData(List.from(newList));
  }

  /// 软删除
  Future<void> softDelete(String entryId) async {
    final list = state.valueOrNull;
    if (list == null) return;

    final repo = await ref.watch(clipboardRepositoryProvider.future);
    final entry = list.firstWhere((e) => e.id == entryId);
    final now = DateTime.now().millisecondsSinceEpoch;
    final maxSeq = await repo.getMaxSeq();
    final newSeq = maxSeq + 1;

    await repo.softDeleteEntry(entryId, newSeq, now);
    final newList = list.where((item) => item.id != entryId).toList();
    _cacheList = newList;
    state = AsyncData(List.from(newList));
  }

  /// 新增记录
  Future<void> addEntry(
      {required String id,
      required String type,
      String? title,
      String? preview,
      String? textContent,
      String? hash,
      required int sizeBytes,
      String? sourceDevice,
      String? filePath}) async {
    final useCase = await ref.watch(addClipboardEntryUseCaseProvider.future);
    await useCase.call(
        id: id,
        type: type,
        title: title,
        preview: preview,
        textContent: textContent,
        hash: hash,
        sizeBytes: sizeBytes,
        sourceDevice: sourceDevice,
        filePath: filePath);
    await refresh();
  }
}
