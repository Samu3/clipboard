import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme_mode_notifier.dart';

/// 主题模式切换按钮
class ThemeModeToggle extends ConsumerWidget {
  const ThemeModeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettingsAsync = ref.watch(themeNotifierProvider);

    return themeSettingsAsync.when(
      data: (themeSettings) {
        final isDark = themeSettings == ThemeMode.dark ||
            (themeSettings == ThemeMode.system &&
                MediaQuery.of(context).platformBrightness == Brightness.dark);

        return IconButton(
          icon: Icon(
            isDark ? Icons.light_mode : Icons.dark_mode,
          ),
          tooltip: isDark ? '切换到浅色模式' : '切换到深色模式',
          onPressed: () {
            ref.read(themeNotifierProvider.notifier).toggleThemeMode();
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// 主题设置按钮（跳转到主题设置页面）
class ThemeSettingsButton extends StatelessWidget {
  final VoidCallback? onTap;

  const ThemeSettingsButton({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.palette_outlined),
      tooltip: '主题设置',
      onPressed: onTap,
    );
  }
}
