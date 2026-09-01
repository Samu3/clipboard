import 'dart:io';

import 'package:clipboard/features/macos/index/channel/native_clipboard_channel.dart';
import 'package:flutter/services.dart';
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
  Future<void> softDelete(ClipboardEntry deleteEntry) async {
    deleteFile(deleteEntry);

    final list = state.valueOrNull;
    if (list == null) return;

    final repo = await ref.watch(clipboardRepositoryProvider.future);
    final entry = list.firstWhere((e) => e.id == deleteEntry.id);
    final now = DateTime.now().millisecondsSinceEpoch;
    final maxSeq = await repo.getMaxSeq();
    final newSeq = maxSeq + 1;

    await repo.softDeleteEntry(entry.id, newSeq, now);
    final newList = list.where((item) => item.id != deleteEntry.id).toList();
    _cacheList = newList;
    state = AsyncData(List.from(newList));
  }

  void deleteFile(ClipboardEntry entry) async {
    if (entry.type == "image" && entry.filePath != null) {
      final file = File(entry.filePath!);
      if (await file.exists()) {
        await file.delete();
        print("已删除剪贴板图片：${entry.filePath}");
      }
    }
    // 可选：file类型，删除临时文件
    if (entry.type == "file") {
      // 如果你的file存储也是filePath数组，在这里循环删除
      // for(final path in entry.payloadFileList){
      //   final f = File(path);
      //   if(await f.exists()) await f.delete();
      // }
    }
  }

  Future<void> copyClipboardEntry(ClipboardEntry entry) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      bool copySuccess = false;

      if (entry.type == "text") {
        final text = entry.textContent ?? entry.title ?? "";
        await Clipboard.setData(ClipboardData(text: text));
        copySuccess = true;
      } else if (entry.type == "image") {
        // 图片复制：这里后续对接mac原生MethodChannel，先占位
        copySuccess = true;
        var filePath = entry.filePath;
        var nativeChannel = ref.read(nativeClipboardProvider);
        if (filePath != null) {
          copySuccess = await nativeChannel.copyImageToPasteboard(filePath);
        }
      } else if (entry.type == "file") {
        // 文件复制：后续对接mac原生MethodChannel，先占位
        copySuccess = true;
      }

      if (copySuccess) {
        // 更新updatedAt

        final repo = await ref.watch(clipboardRepositoryProvider.future);

        final updateEntry = entry.copyWith(createdAt: now);
        await repo.updateEntry(updateEntry);

        await refresh();
      }
    } catch (e) {}
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
