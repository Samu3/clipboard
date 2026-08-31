import 'package:freezed_annotation/freezed_annotation.dart';

part 'water_record.freezed.dart';

@freezed
class WaterRecord with _$WaterRecord {
  const factory WaterRecord({
    required String id,
    required int ml,
    required DateTime drinkAt,
  }) = _WaterRecord;

  const WaterRecord._();
}
