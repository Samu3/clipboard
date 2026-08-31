import 'package:unique_health/features/water/domain/entities/water_setting.dart';
import 'package:unique_health/features/water/providers/water_provider.dart';

import '../../domain/entities/water_record.dart';
import '../../domain/repositories/water_repository.dart';
import '../datasources/water_datasource.dart';

class WaterRepositoryImpl implements WaterRepository {
  final WaterDatasource localDatasource;

  WaterRepositoryImpl(this.localDatasource);

  @override
  Future<List<WaterRecord>> getTodayRecords() {
    return localDatasource.getTodayRecords();
  }

  @override
  Future<List<WaterRecord>> getAllRecords() {
    return localDatasource.getAllRecords();
  }

  @override
  Future<void> addWater(int ml) {
    return localDatasource.addWater(ml);
  }

  @override
  Future<void> deleteRecord(String recordId) {
    return localDatasource.deleteRecord(recordId);
  }

  @override
  Future<WaterSetting> getWaterSettings() {
    return localDatasource.getWaterSetting();
  }

  @override
  Future<void> updateWaterSettings(WaterSetting setting) {
    return localDatasource.updateWaterSetting(setting);
  }

  @override
  Future<Map<String, int>> getDailyTotals(int days) {
    return localDatasource.getDailyTotals(days);
  }
}
