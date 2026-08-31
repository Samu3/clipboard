import 'package:unique_health/features/water/domain/entities/water_setting.dart';

import '../entities/water_record.dart';

abstract class WaterRepository {
  Future<List<WaterRecord>> getTodayRecords();
  Future<List<WaterRecord>> getAllRecords();
  Future<void> addWater(int ml);
  Future<void> deleteRecord(String recordId);
  Future<WaterSetting> getWaterSettings();
  Future<void> updateWaterSettings(WaterSetting setting);

  /// 获取最近N天的每日总量
  Future<Map<String, int>> getDailyTotals(int days);
}
