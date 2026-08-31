import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clipboard/core/theme/app_colors.dart';

/// 自定义AppBar组件
///
/// 支持左侧返回按钮、标题和右侧操作按钮列表
class CustomAppBar extends ConsumerWidget {
  /// 标题文本
  final String title;

  /// 右侧操作按钮列表
  final List<AppBarAction>? actions;

  /// 是否显示返回按钮，默认显示
  final bool showBackButton;

  /// 自定义返回按钮点击事件
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusHeight = MediaQuery.of(context).padding.top;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AppBar 工具栏
        Container(
          height: kToolbarHeight,
          margin: EdgeInsets.only(top: statusHeight, left: 20, right: 16),
          child: Row(
            children: [
              // 左侧返回按钮
              if (showBackButton)
                GestureDetector(
                  onTap: onBackPressed ?? () => context.pop(),
                  child: const Icon(Icons.arrow_back),
                ),
              const Spacer(),
              // 右侧操作按钮列表
              if (actions != null)
                ...actions!.map((action) => Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: GestureDetector(
                        onTap: action.onTap,
                        child: Icon(action.icon),
                      ),
                    )),
            ],
          ),
        ),
        // 标题
        Padding(
          padding: const EdgeInsets.only(left: 25),
          child: Text(
            title,
            style: TextStyle(
              color: context.color.black08,
              fontSize: 30,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ],
    );
  }
}

/// AppBar 操作按钮模型
class AppBarAction {
  /// 图标
  final IconData icon;

  /// 点击事件
  final VoidCallback onTap;

  /// 工具提示（可选）
  final String? tooltip;

  const AppBarAction({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });
}
