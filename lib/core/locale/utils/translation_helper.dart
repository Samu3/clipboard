import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';

/// 全局翻译入口
///
/// 使用本地硬编码的翻译映射
String t(WidgetRef ref, String key) {
  // 获取当前语言
  final currentLangAsync = ref.watch(currentLanguageProvider);
  final currentLang = currentLangAsync.value ?? 'zh';

  // 使用本地翻译映射
  return _getTranslation(ref, currentLang, key);
}

/// 本地翻译映射
///
/// 实际项目中可以：
/// 1. 从远程 API 获取翻译
/// 2. 使用 flutter_localizations 的 ARB 文件
/// 3. 使用数据库缓存
Map<String, Map<String, String>> _translations = {};

String _getTranslation(WidgetRef ref, String languageCode, String key) {
  final locale = ref.watch(localeDatasourceProvider);

  final langMap = locale.getCachedLanguageTexts(languageCode);
  if (langMap != null && langMap.containsKey(key)) {
    return langMap[key]!;
  }

  // 降级到英文
  final enMap = _translations['en'];
  if (enMap != null && enMap.containsKey(key)) {
    return enMap[key]!;
  }

  // 如果都找不到，返回 key 本身
  return key;
}

/// 扩展方法，方便在 Widget 中使用
extension LocalizationExtension on WidgetRef {
  String tr(String key, {String tag = ""}) => t(this, key);
}
