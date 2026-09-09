import 'package:clipboard/features/macos/index/domain/entities/clipboard_entry.dart';

abstract class ClipboardRepository {
  /// 新增单条记录
  Future<void> insertEntry(ClipboardEntry entry);

  /// 更新记录
  Future<void> updateEntry(ClipboardEntry entry);

  /// 软删除
  Future<void> softDeleteEntry(String id, int seq, int deletedAt);

  /// 根据id查询
  Future<ClipboardEntry?> getEntryById(String id);

  /// 获取未删除列表，【增加filter筛选参数】
  /// filter: all / text / image / file / transfer / favorite
  Future<List<ClipboardEntry>> getActiveEntries({
    required String filter,
    required String keyword,
    int limit = 50,
    int offset = 0,
  });

  /// 获取大于 lastSeq 的增量变更（同步补差核心）
  Future<List<ClipboardEntry>> getEntriesAfterSeq(int lastSeq);

  /// 获取最大seq，用于本地生成新seq
  Future<int> getMaxSeq();

  /// 清空所有记录
  Future<void> clearAllEntries();
}
