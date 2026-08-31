import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// 数据库帮助类
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // 表名常量
  static const String waterReordsTableName = 'water_records';
  static const String waterSettingsTableName = 'water_settings';

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
    final path = join(databasePath, 'unique_health.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    // 创建喝水记录表
    await db.execute('''
      CREATE TABLE water_records (
        id TEXT PRIMARY KEY,
        account_id TEXT,
        uid TEXT,
        amount INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        note TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 创建索引以提高查询效率
    await db.execute('''
      CREATE INDEX idx_water_records_timestamp
      ON water_records(timestamp)
    ''');

    await db.execute('''
      CREATE INDEX idx_water_records_account_uid
      ON water_records(account_id, uid)
    ''');

    // 创建水设置表
    await db.execute('''
      CREATE TABLE water_settings (
        id INTEGER PRIMARY KEY,
        account_id TEXT,
        uid TEXT,
        water_cpu INTEGER NOT NULL,
        water_target INTEGER NOT NULL
      )
    ''');

    // TODO: 添加其他表
    // 例如：用户信息表、健康数据表等
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 添加 account_id 和 uid 字段到 water_records
      await db.execute('''
        ALTER TABLE water_records ADD COLUMN account_id TEXT
      ''');
      await db.execute('''
        ALTER TABLE water_records ADD COLUMN uid TEXT
      ''');

      // 创建新索引
      await db.execute('''
        CREATE INDEX idx_water_records_account_uid
        ON water_records(account_id, uid)
      ''');

      // 检查 water_settings 表是否存在
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='water_settings'");

      if (tables.isEmpty) {
        // 创建 water_settings 表
        await db.execute('''
          CREATE TABLE water_settings (
            id INTEGER PRIMARY KEY,
            account_id TEXT,
            uid TEXT,
            water_cpu INTEGER NOT NULL,
            water_target INTEGER NOT NULL
          )
        ''');
      } else {
        // 表已存在，添加字段
        await db.execute('''
          ALTER TABLE water_settings ADD COLUMN account_id TEXT
        ''');
        await db.execute('''
          ALTER TABLE water_settings ADD COLUMN uid TEXT
        ''');
      }
    }
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
