import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unique_health/core/auth/auth_provider.dart';
import 'package:unique_health/core/database/database_provider.dart';
import 'package:unique_health/features/water/domain/entities/water_setting.dart';
import '../data/datasources/water_datasource.dart';
import '../data/repositories/water_repository_impl.dart';
import '../domain/entities/water_record.dart';
import '../domain/repositories/water_repository.dart';

part 'water_provider.g.dart';

// 数据源provider - 注入数据库实例
@Riverpod(keepAlive: true)
Future<WaterDatasource> waterDatasource(WaterDatasourceRef ref) async {
  final db = await ref.watch(databaseProvider.future);

  // 从认证状态获取真实的 accountId 和 uid
  final authState = await ref.watch(authStateNotifierProvider.future);
  final accountId =
      authState.accountId.isNotEmpty ? authState.accountId : 'default_account';
  final uid = authState.uid.isNotEmpty ? authState.uid : 'default_user';

  return WaterDatasource(
    db,
    accountId: accountId,
    uid: uid,
  );
}

// 仓库provider，注入数据源
@Riverpod(keepAlive: true)
Future<WaterRepository> waterRepository(WaterRepositoryRef ref) async {
  final ds = await ref.watch(waterDatasourceProvider.future);
  return WaterRepositoryImpl(ds);
}

// 业务状态：今日喝水记录
@riverpod
class WaterNotifier extends _$WaterNotifier {
  @override
  Future<List<WaterRecord>> build() async {
    // 等待 repository 初始化完成
    final repo = await ref.watch(waterRepositoryProvider.future);
    // 初始化读取今日数据
    return await repo.getTodayRecords();
  }

  /// 添加喝水
  Future<void> addDrink(int ml) async {
    final repo = await ref.read(waterRepositoryProvider.future);
    state = await AsyncValue.guard(() async {
      await repo.addWater(ml);
      return await repo.getTodayRecords();
    });
    refreshProvider();
  }

  /// 删除一条记录
  Future<void> delete(String recordId) async {
    final repo = await ref.read(waterRepositoryProvider.future);
    state = await AsyncValue.guard(() async {
      await repo.deleteRecord(recordId);
      return await repo.getTodayRecords();
    });
    refreshProvider();
  }

  int getTotalMl(List<WaterRecord> list) {
    return list.fold<int>(0, (pre, item) => pre + item.ml);
  }

  void refreshProvider() {
    ref.invalidate(waterDailyTotalsProvider);
    ref.invalidate(waterAllRecordTotalsProvider);
  }
}

// 水设置 Provider（独立管理）
@riverpod
class WaterSettingNotifier extends _$WaterSettingNotifier {
  @override
  Future<WaterSetting> build() async {
    final repo = await ref.watch(waterRepositoryProvider.future);
    return await repo.getWaterSettings();
  }

  /// 更新水设置
  Future<void> updateWaterSettings(WaterSetting setting) async {
    final repo = await ref.read(waterRepositoryProvider.future);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.updateWaterSettings(setting);

      return setting;
    });
  }

  /// 仅更新每日目标
  Future<void> updateWaterTarget(int waterTarget) async {
    final current = state.value;
    if (current == null) return;
    await updateWaterSettings(current.copyWith(waterTarget: waterTarget));
  }

  /// 仅更新每杯水量
  Future<void> updateWaterCpu(int waterCpu) async {
    final current = state.value;
    if (current == null) return;
    await updateWaterSettings(current.copyWith(waterCpu: waterCpu));
  }
}

// 每日总量 Provider - 获取最近N天的数据
@riverpod
Future<Map<String, int>> waterDailyTotals(
  WaterDailyTotalsRef ref, {
  int days = 7,
}) async {
  final repo = await ref.watch(waterRepositoryProvider.future);
  return await repo.getDailyTotals(days);
}

//获取全部record
@riverpod
Future<List<WaterRecord>> waterAllRecordTotals(
  WaterAllRecordTotalsRef ref,
) async {
  final repo = await ref.read(waterRepositoryProvider.future);

  return await repo.getAllRecords();
}
