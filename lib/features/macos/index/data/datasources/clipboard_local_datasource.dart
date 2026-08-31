import 'package:sqflite/sqflite.dart';
import 'package:clipboard/features/macos/index/domain/entities/clipboard_entry.dart';

class ClipboardLocalDatasource {
  final Database db;

  ClipboardLocalDatasource({required this.db});

  static const String tableName = 'entries';

  Map<String, dynamic> entryToMap(ClipboardEntry entry) {
    return {
      'id': entry.id,
      'seq': entry.seq,
      'type': entry.type,
      'title': entry.title,
      'preview': entry.preview,
      'text_content': entry.textContent,
      'hash': entry.hash,
      'size_bytes': entry.sizeBytes,
      'favorite': entry.favorite,
      'source_device': entry.sourceDevice,
      'created_at': entry.createdAt,
      'updated_at': entry.updatedAt,
      'deleted': entry.deleted,
      'deleted_at': entry.deletedAt,
      'filePath': entry.filePath
    };
  }

  ClipboardEntry mapToEntry(Map<String, dynamic> map) {
    return ClipboardEntry(
      id: map['id'] as String,
      seq: map['seq'] as int,
      type: map['type'] as String,
      title: map['title'] as String?,
      preview: map['preview'] as String?,
      textContent: map['text_content'] as String?,
      hash: map['hash'] as String?,
      sizeBytes: map['size_bytes'] as int,
      favorite: map['favorite'] as int,
      sourceDevice: map['source_device'] as String?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
      deleted: map['deleted'] as int,
      deletedAt: map['deleted_at'] as int?,
      filePath: map['filePath'] as String?,
    );
  }

  Future<void> insert(Map<String, dynamic> map) async {
    await db.insert(tableName, map);
  }

  Future<void> update(Map<String, dynamic> map) async {
    await db.update(
      tableName,
      map,
      where: 'id = ?',
      whereArgs: [map['id']],
    );
  }

  Future<Map<String, dynamic>?> findById(String id) async {
    final res = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (res.isEmpty) return null;
    return res.first;
  }

  /// 数据库筛选查询【核心改动】
  Future<List<Map<String, dynamic>>> getActiveList({
    required String filter,
    required String keyword,
    int limit = 50,
    int offset = 0,
  }) async {
    List<String> whereList = ['deleted = 0'];
    List<Object> whereArgs = [];

    // 类型筛选
    switch (filter) {
      case 'text':
      case 'image':
      case 'file':
        whereList.add('type = ?');
        whereArgs.add(filter);
        break;
      case 'favorite':
        whereList.add('favorite = 1');
        break;
      case 'all':
      default:
        break;
    }

    // 搜索关键词模糊查询，匹配 title / preview / text_content
    final kw = keyword.trim();
    if (kw.isNotEmpty) {
      whereList.add('(title LIKE ? OR preview LIKE ? OR text_content LIKE ?)');
      final likeStr = '%$kw%';
      whereArgs.addAll([likeStr, likeStr, likeStr]);
    }

    final where = whereList.join(' AND ');

    return await db.query(
      tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> getEntriesAfterSeq(int lastSeq) async {
    return await db.query(
      tableName,
      where: 'seq > ?',
      whereArgs: [lastSeq],
      orderBy: 'seq ASC',
    );
  }

  Future<int?> getMaxSeq() async {
    final res = await db.rawQuery('SELECT MAX(seq) as max_seq FROM $tableName');
    return Sqflite.firstIntValue(res);
  }
}
