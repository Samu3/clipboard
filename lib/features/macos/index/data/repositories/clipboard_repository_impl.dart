import 'package:clipboard/features/macos/index/data/datasources/clipboard_local_datasource.dart';
import 'package:clipboard/features/macos/index/domain/entities/clipboard_entry.dart';
import 'package:clipboard/features/macos/index/domain/repositories/clipboard_repository.dart';

class ClipboardRepositoryImpl implements ClipboardRepository {
  final ClipboardLocalDatasource localDs;

  ClipboardRepositoryImpl({required this.localDs});

  @override
  Future<void> insertEntry(ClipboardEntry entry) async {
    await localDs.insert(localDs.entryToMap(entry));
  }

  @override
  Future<void> updateEntry(ClipboardEntry entry) async {
    await localDs.update(localDs.entryToMap(entry));
  }

  @override
  Future<void> softDeleteEntry(String id, int seq, int deletedAt) async {
    final item = await getEntryById(id);
    if (item == null) return;
    final updateItem = item.copyWith(
      deleted: 1,
      deletedAt: deletedAt,
      seq: seq,
      updatedAt: deletedAt,
    );
    await updateEntry(updateItem);
  }

  @override
  Future<ClipboardEntry?> getEntryById(String id) async {
    final map = await localDs.findById(id);
    if (map == null) return null;
    return localDs.mapToEntry(map);
  }

  @override
  Future<List<ClipboardEntry>> getActiveEntries({
    required String filter,
    required String keyword,
    int limit = 50,
    int offset = 0,
  }) async {
    final list = await localDs.getActiveList(
      filter: filter,
      keyword: keyword,
      limit: limit,
      offset: offset,
    );
    return list.map((e) => localDs.mapToEntry(e)).toList();
  }

  @override
  Future<List<ClipboardEntry>> getEntriesAfterSeq(int lastSeq) async {
    final list = await localDs.getEntriesAfterSeq(lastSeq);
    return list.map((e) => localDs.mapToEntry(e)).toList();
  }

  @override
  Future<int> getMaxSeq() async {
    final val = await localDs.getMaxSeq();
    return val ?? 0;
  }

  @override
  Future<void> clearAllEntries() async {
    await localDs.deleteAll();
  }
}
