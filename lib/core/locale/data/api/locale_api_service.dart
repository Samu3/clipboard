import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:clipboard/core/network/result/base_result.dart';
import '../../../../core/network/dio_provider.dart';

part 'locale_api_service.g.dart';

/// Locale API Service
/// 处理多语言相关的 API 接口
@RestApi()
abstract class LocaleApiService {
  factory LocaleApiService(Dio dio, {String baseUrl}) = _LocaleApiService;

  /// 获取增量语言包
  ///
  /// [lang] 语言代码，如：zh, en, ja, ko
  /// [appType] 应用类型，如：Unique_Health
  @GET('/web/system/lang/getIncrListByAppType')
  Future<BaseResult> getLanguageTexts(
    @Query('lang') String lang,
    @Query('appType') String appType,
  );
}

/// Locale API Service Provider
@Riverpod(keepAlive: true)
LocaleApiService localeApiService(LocaleApiServiceRef ref) {
  final dio = ref.watch(dioProvider);

  // 添加调试信息

  return LocaleApiService(dio);
}
