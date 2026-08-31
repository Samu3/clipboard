import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

part 'database_provider.g.dart';

/// 数据库实例Provider
@riverpod
Future<Database> database(DatabaseRef ref) async {
  final dbHelper = DatabaseHelper();
  final db = await dbHelper.database;

  // 当Provider被销毁时，关闭数据库连接
  ref.onDispose(() async {
    await dbHelper.close();
  });

  return db;
}
