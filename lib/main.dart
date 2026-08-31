import 'package:clipboard/features/macos/index/channel/native_clipboard_channel.dart';
import 'package:clipboard/features/macos/index/providers/clipboard_listener_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clipboard/core/channel/native_channel.dart';
import 'package:clipboard/core/locale/providers/locale_provider.dart';
import 'package:clipboard/core/network/api_config.dart';
import 'package:clipboard/core/theme/app_theme.dart';
import 'package:clipboard/core/theme/theme_mode_notifier.dart';
import 'package:clipboard/core/router/app_router.dart';
import 'package:clipboard/core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化日志系统
  await logger.init();
  logger.i('应用启动', category: LogCategory.common);

  // 初始化 SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  logger.i('SharedPreferences 初始化完成', category: LogCategory.common);

  // 初始化 ApiConfig，加载保存的 domain
  await ApiConfig().init(prefs);

  // 清理7天前的日志
  await logger.cleanOldLogs(keepDays: 7);

  // final container = ProviderContainer();
  // 初始化原生MethodChannel，Swift自动监听剪贴板

  // _testNetworkConnectivity();
  runApp(
    ProviderScope(
      overrides: [
        // 提供 SharedPreferences 实例
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 设置 AppChannel 的 ref，让它可以访问 providers
    AppChannel().setRef(ref);
    // 使用 watch 保持 NativeClipboardChannel 实例存活，确保 MethodCallHandler 能接收回调
    ref.watch(nativeClipboardProvider);

    // 直接获取值，如果为 null 显示加载界面
    final themeMode = ref.watch(themeNotifierProvider).valueOrNull;
    final currentLangAsync = ref.watch(currentLanguageProvider);
    final router = ref.watch(goRouterProvider);

    // 如果正在加载或者为空，显示加载界面
    if (currentLangAsync.isLoading && !currentLangAsync.hasValue) {
      return Container();
    }

    final currentLang = currentLangAsync.valueOrNull;

    if (currentLang == null) {
      return Container();
    }

    final locale = _getLocaleFromCode(currentLang);

    return MaterialApp.router(
      title: 'Clip',
      debugShowCheckedModeBanner: false,
      // 根据设置应用主题
      themeMode: themeMode,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      // 多语言配置
      locale: locale,
      supportedLocales: const [
        Locale("zh"), // zh‑Hans 简体
        Locale("zh", "TW"), // zh‑Hant 繁体
        Locale("en"),
        Locale("ja"),
        Locale("fr"),
        Locale("ko"),
        Locale("de"),
        Locale("ru"),
        Locale("es"),
        Locale("it"),
        Locale("pt", "BR"),
        Locale("ar"),
        Locale("hu"),
        Locale("pl"),
        Locale("cs"),
        Locale("vi"),
        Locale("th"),
        Locale("id"),
        Locale("tr"),
        Locale("da"),
        Locale("nl"),
        Locale("hr"),
        Locale("sv"),
        Locale("mn"),
        Locale("nb"),
        Locale("fi"),
        Locale("sk"),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );

    // 将语言代码转换为 Locale
  }

  // 将语言代码转换为 Locale
  Locale _getLocaleFromCode(String code) {
    switch (code) {
      case 'zh‑Hans':
        return const Locale('zh');
      case 'zh‑Hant':
        return const Locale('zh', 'TW');
      case 'pt‑BR':
        return const Locale('pt', 'BR');
      case 'en':
        return const Locale('en');
      case 'ja':
        return const Locale('ja');
      case 'ko':
        return const Locale('ko');
      case 'fr':
        return const Locale('fr');
      case 'de':
        return const Locale('de');
      case 'ru':
        return const Locale('ru');
      case 'es':
        return const Locale('es');
      case 'it':
        return const Locale('it');
      case 'ar':
        return const Locale('ar');
      case 'hu':
        return const Locale('hu');
      case 'pl':
        return const Locale('pl');
      case 'cs':
        return const Locale('cs');
      case 'vi':
        return const Locale('vi');
      case 'th':
        return const Locale('th');
      case 'id':
        return const Locale('id');
      case 'tr':
        return const Locale('tr');
      case 'da':
        return const Locale('da');
      case 'nl':
        return const Locale('nl');
      case 'hr':
        return const Locale('hr');
      case 'sv':
        return const Locale('sv');
      case 'mn':
        return const Locale('mn');
      case 'nb':
        return const Locale('nb');
      case 'fi':
        return const Locale('fi');
      case 'sk':
        return const Locale('sk');
      default:
        // 兜底简体中文
        return const Locale('zh');
    }
  }
}


/// 监听goRouter路由变化，上报栈深度给iOS原生
