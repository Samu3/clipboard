import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/locale.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleDatasource {
  final SharedPreferences prefs;

  static const _keyCurrentLanguage = 'current_language';
  static const _keyCachedTexts = 'cached_texts_';
  static const _appType = 'PasteLink';

  LocaleDatasource(this.prefs);

  /// 缓存语言文本到本地
  Future<void> _cacheLanguageTexts(
      String languageCode, Map<String, String> texts) async {
    final jsonString =
        texts.entries.map((e) => '"${e.key}":"${e.value}"').join(',');
    await prefs.setString('$_keyCachedTexts$languageCode', '{$jsonString}');
  }

  /// 从缓存读取语言文本
  Map<String, String> getCachedLanguageTexts(String languageCode) {
    final jsonString = prefs.getString('$_keyCachedTexts$languageCode');
    if (jsonString == null || jsonString.isEmpty) {
      return {};
    }

    // 简单解析 JSON 字符串
    final texts = <String, String>{};
    final cleaned = jsonString.substring(1, jsonString.length - 1); // 去掉 {}
    if (cleaned.isEmpty) return texts;

    final pairs = cleaned.split('","');
    for (final pair in pairs) {
      final parts = pair.replaceAll('"', '').split(':');
      if (parts.length == 2) {
        texts[parts[0]] = parts[1];
      }
    }

    return texts;
  }

  /// 模拟从远程获取可用语言列表
  Future<Map<String, String>> getAvailableLanguages(String languageCode) async {
    // 模拟网络延迟

    // 读取assets json文本
    final jsonStr =
        await rootBundle.loadString('assets/locales/$languageCode.json');
    final dynamic jsonData = json.decode(jsonStr);

    // 情况A：后端格式为 Map<String,String> { "key":"text" }
    if (jsonData is Map) {
      Map<String, String> mapData = Map<String, String>.from(jsonData);
      // 如果你必须返回 List<Map<>>

      await _cacheLanguageTexts(languageCode, mapData);

      return mapData;
    }

    return {};
  }

  /// 获取当前语言
  Future<String> getCurrentLanguage() async {
    var lang = prefs.getString(_keyCurrentLanguage) ?? 'zh';
    return lang;
  }

  /// 设置当前语言
  Future<void> setLanguage(String languageCode) async {
    await prefs.setString(_keyCurrentLanguage, languageCode);
  }
}
