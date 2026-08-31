import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// 数据库帮助类
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  static const String tableEntries = 'entries';
  static const String tableBlobs = 'blobs';
  static const String tableTags = 'tags';
  static const String tableEntryTags = 'entry_tags';
  static const String tableDevices = 'devices';
  static const String tableSyncState = 'sync_state';
  static const String tableSettings = 'settings';
  static const String tableSubscription = 'subscription';

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'clipboard.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    // 1. entries 剪贴板主表
    await db.execute('''
    CREATE TABLE IF NOT EXISTS $tableEntries (
      id TEXT PRIMARY KEY,
      seq INTEGER UNIQUE NOT NULL,
      type TEXT NOT NULL,
      title TEXT,
      preview TEXT,
      text_content TEXT,
      hash TEXT,
      size_bytes INTEGER DEFAULT 0,
      favorite INTEGER DEFAULT 0,
      source_device TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      deleted INTEGER DEFAULT 0,
      deleted_at INTEGER,
      filePath TEXT
    )
    ''');

    // entries索引
    await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_entries_seq ON $tableEntries(seq)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_entries_created_at ON $tableEntries(created_at DESC)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_entries_type ON $tableEntries(type)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_entries_favorite ON $tableEntries(favorite) WHERE deleted=0');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_entries_hash ON $tableEntries(hash) WHERE deleted=0');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_entries_deleted ON $tableEntries(deleted) WHERE deleted=0');

    // 2. blobs 大内容表
    await db.execute('''
    CREATE TABLE IF NOT EXISTS $tableBlobs (
      entry_id TEXT PRIMARY KEY,
      mime_type TEXT,
      file_name TEXT,
      file_path TEXT,
      thumb_blob BLOB,
      content_hash TEXT,
      created_at INTEGER NOT NULL,
      FOREIGN KEY(entry_id) REFERENCES $tableEntries(id) ON DELETE CASCADE
    )
    ''');

    //3. tags 标签
    await db.execute('''
    CREATE TABLE IF NOT EXISTS $tableTags (
      id TEXT PRIMARY KEY,
      name TEXT UNIQUE NOT NULL,
      color TEXT,
      created_at INTEGER NOT NULL
    )
    ''');

    // entry_tags 中间表，联合主键
    await db.execute('''
    CREATE TABLE IF NOT EXISTS $tableEntryTags (
      entry_id TEXT NOT NULL,
      tag_id TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      PRIMARY KEY(entry_id, tag_id),
      FOREIGN KEY(entry_id) REFERENCES $tableEntries(id) ON DELETE CASCADE,
      FOREIGN KEY(tag_id) REFERENCES $tableTags(id) ON DELETE CASCADE
    )
    ''');

    //4. devices 配对设备
    await db.execute('''
    CREATE TABLE IF NOT EXISTS $tableDevices (
      device_id TEXT PRIMARY KEY,
      name TEXT,
      platform TEXT,
      token_hash TEXT,
      cert_fingerprint TEXT,
      last_seen_at INTEGER,
      created_at INTEGER NOT NULL
    )
    ''');

    //5. sync_state 每设备同步游标
    await db.execute('''
    CREATE TABLE IF NOT EXISTS $tableSyncState (
      device_id TEXT PRIMARY KEY,
      last_synced_seq INTEGER NOT NULL DEFAULT 0,
      last_push_at INTEGER,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY(device_id) REFERENCES $tableDevices(device_id) ON DELETE CASCADE
    )
    ''');

    //6. settings 键值配置
    await db.execute('''
    CREATE TABLE IF NOT EXISTS $tableSettings (
      key TEXT PRIMARY KEY,
      value TEXT,
      updated_at INTEGER NOT NULL
    )
    ''');

    //7. subscription 付费本地缓存
    await db.execute('''
    CREATE TABLE IF NOT EXISTS $tableSubscription (
      is_pro INTEGER DEFAULT 0,
      plan TEXT,
      expiry INTEGER,
      receipt_b64 TEXT,
      updated_at INTEGER NOT NULL
    )
    ''');
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
