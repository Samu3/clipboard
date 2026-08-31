import 'package:sqflite/sqflite.dart';
import 'package:unique_health/core/database/database_helper.dart';
import 'package:unique_health/features/water/domain/entities/water_setting.dart';
import '../../domain/entities/water_record.dart';

class WaterDatasource {
  final Database _db;
  final String accountId;
  final String uid;

  WaterDatasource(this._db, {required this.accountId, required this.uid});

  static const String _tableName = DatabaseHelper.waterReordsTableName;
  static const String _settingsTable = DatabaseHelper.waterSettingsTableName;

  /// 获取今日记录
  Future<List<WaterRecord>> getTodayRecords() async {
    final now = DateTime.now();
    final startOfDay =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59)
        .millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'timestamp >= ? AND timestamp <= ? AND account_id = ? AND uid = ?',
      whereArgs: [startOfDay, endOfDay, accountId, uid],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) {
      return WaterRecord(
        id: map['id'] as String,
        ml: map['amount'] as int,
        drinkAt: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      );
    }).toList();
  }

  Future<List<WaterRecord>> getAllRecords() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      _tableName,
      where: 'account_id = ? AND uid = ?',
      whereArgs: [accountId, uid],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) {
      return WaterRecord(
        id: map['id'] as String,
        ml: map['amount'] as int,
        drinkAt: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      );
    }).toList();
  }

  /// 添加喝水记录
  Future<void> addWater(int ml) async {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;

    await _db.insert(
      _tableName,
      {
        'id': '$timestamp',
        'account_id': accountId,
        'uid': uid,
        'amount': ml,
        'timestamp': timestamp,
        'note': null,
        'created_at': timestamp,
        'updated_at': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取水设置
  Future<WaterSetting> getWaterSetting() async {
    // 检查设置表是否存在
    final tableExists = await _checkSettingsTableExists();

    if (!tableExists) {
      // 如果表不存在，创建表并返回默认值
      await _createSettingsTable();
      return const WaterSetting(waterCpu: 200, waterTarget: 2000);
    }

    final List<Map<String, dynamic>> maps = await _db.query(
      _settingsTable,
      where: 'account_id = ? AND uid = ?',
      whereArgs: [accountId, uid],
      limit: 1,
    );

    if (maps.isEmpty) {
      // 如果没有设置记录，插入默认值
      await _db.insert(_settingsTable, {
        'id': DateTime.now().millisecondsSinceEpoch,
        'account_id': accountId,
        'uid': uid,
        'water_cpu': 200,
        'water_target': 2000,
      });
      return const WaterSetting(waterCpu: 200, waterTarget: 2000);
    }

    return WaterSetting(
      waterCpu: maps[0]['water_cpu'] as int,
      waterTarget: maps[0]['water_target'] as int,
    );
  }

  /// 检查设置表是否存在
  Future<bool> _checkSettingsTableExists() async {
    final result = await _db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$_settingsTable'");
    return result.isNotEmpty;
  }

  /// 创建设置表
  Future<void> _createSettingsTable() async {
    // 插入默认值
    await _db.insert(_settingsTable, {
      'id': DateTime.now().millisecondsSinceEpoch,
      'account_id': accountId,
      'uid': uid,
      'water_cpu': 200,
      'water_target': 2000,
    });
  }

  /// 更新水设置
  Future<void> updateWaterSetting(WaterSetting setting) async {
    final count = await _db.update(
      _settingsTable,
      {
        'water_cpu': setting.waterCpu,
        'water_target': setting.waterTarget,
      },
      where: 'account_id = ? AND uid = ?',
      whereArgs: [accountId, uid],
    );

    // 如果没有更新到记录，说明该用户还没有设置，插入一条
    if (count == 0) {
      await _db.insert(_settingsTable, {
        'id': DateTime.now().millisecondsSinceEpoch,
        'account_id': accountId,
        'uid': uid,
        'water_cpu': setting.waterCpu,
        'water_target': setting.waterTarget,
      });
    }
  }

  /// 删除记录
  Future<void> deleteRecord(String recordId) async {
    await _db.delete(
      _tableName,
      where: 'id = ? AND account_id = ? AND uid = ?',
      whereArgs: [recordId, accountId, uid],
    );
  }

  /// 获取最近N天有数据的每日总量（从数据库直接分组，只返回有记录的日期）
  Future<Map<String, int>> getDailyTotals(int days) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days - 1));
    final startOfDay = DateTime(startDate.year, startDate.month, startDate.day)
        .millisecondsSinceEpoch;

    // 使用 SQL GROUP BY 按日期分组并求和，只返回有数据的日期
    final result = await _db.rawQuery('''
      SELECT
        date(timestamp / 1000, 'unixepoch', 'localtime') as date,
        SUM(amount) as total
      FROM $_tableName
      WHERE timestamp >= ? AND account_id = ? AND uid = ?
      GROUP BY date(timestamp / 1000, 'unixepoch', 'localtime')
      ORDER BY date
    ''', [startOfDay, accountId, uid]);

    // 转换为 Map，只包含有数据的日期
    final Map<String, int> dailyTotals = {};
    for (var row in result) {
      final date = row['date'] as String;
      final total = row['total'] as int;
      dailyTotals[date] = total;
    }

    return dailyTotals;
  }
}
