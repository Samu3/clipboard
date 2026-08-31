import 'package:freezed_annotation/freezed_annotation.dart';

part 'water_setting.freezed.dart';

@freezed
class WaterSetting with _$WaterSetting {
  const factory WaterSetting({
    required int waterCpu,
    required int waterTarget,
  }) = _WaterSetting;

  const WaterSetting._();
}
