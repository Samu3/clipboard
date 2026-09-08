import 'package:clipboard/core/locale/providers/locale_provider.dart';
import 'package:clipboard/core/locale/utils/translation_helper.dart';
import 'package:clipboard/core/widgets/custom_toggle.dart';
import 'package:clipboard/features/macos/settings/channel/native_setting_channel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clipboard/features/macos/settings/presentation/providers/settings_notifier.dart';
import 'package:clipboard/features/macos/index/channel/native_clipboard_channel.dart';
import 'dart:async';

import 'package:clipboard/core/locale/providers/locale_provider.dart';
import 'package:clipboard/core/widgets/custom_toggle.dart';
import 'package:clipboard/features/macos/settings/channel/native_setting_channel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clipboard/features/macos/settings/presentation/providers/settings_notifier.dart';
import 'package:clipboard/features/macos/index/channel/native_clipboard_channel.dart';
import 'dart:async';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  StreamSubscription? _hotkeySubscription;
  String? _capturedHotkey;
  int? _capturedKeyCode;
  int? _capturedModifiers;

  @override
  void dispose() {
    _hotkeySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('${ref.tr("ERROR_TEXT")} $err')),
        data: (settings) {
          return Column(
            children: [
              // 顶部导航栏
              _buildTopBar(context),
              const Divider(height: 1),

              // 设置内容
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        title: ref.tr("SHORTCUT_SETTINGS"),
                        children: [
                          _buildHotKeyItem(
                            label: ref.tr("SHOW_CLIPBOARD_MENU"),
                            currentHotKey: settings.hotKey,
                            onTap: () {
                              _showHotKeyDialog(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        title: ref.tr("GENERAL_SETTINGS"),
                        children: [
                          _buildSwitchItem(
                            label: ref.tr("AUTO_START"),
                            value: settings.autoStart,
                            onChanged: (value) {
                              ref
                                  .read(settingsNotifierProvider.notifier)
                                  .updateAutoStart(value);
                            },
                          ),
                          _buildLangItem(ref: ref, context: context)
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        title: ref.tr("ABOUT"),
                        children: [
                          _buildInfoItem(
                            label: ref.tr("VERSION"),
                            value: '1.0.0',
                          ),
                          _buildInfoItem(
                            label: ref.tr("FEEDBACK"),
                            value: '328889498@qq.com',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Text(
            ref.tr("SETTINGS"),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1D23),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1D23),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE4E6EB)),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildHotKeyItem({
    required String label,
    required String currentHotKey,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1A1D23),
              ),
            ),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE4E6EB)),
                  ),
                  child: Text(
                    currentHotKey,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4F6BFF),
                      fontFamily: 'DM Mono',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF1A1D23),
            ),
          ),
          CustomToggle(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF4F6BFF),
          ),
        ],
      ),
    );
  }

  Widget _buildLangItem({
    required WidgetRef ref,
    required BuildContext context,
  }) {
    final langList = [
      MapEntry('zh', '简体中文'),
      MapEntry('en', 'English'),
    ];

    // 监听语言 AsyncValue
    final langAsync = ref.watch(currentLanguageProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            ref.tr("LANGUAGE"),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF1A1D23),
            ),
          ),
          langAsync.when(
            loading: () => const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
            error: (err, stack) => const Text(''),
            data: (currentLang) {
              return PopupMenuButton<String>(
                tooltip: '',
                initialValue: currentLang,
                onSelected: (langCode) {
                  // 调用notifier更新语言
                  ref
                      .read(currentLanguageProvider.notifier)
                      .changeLanguage(langCode);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 8,
                color: Colors.white,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      langList.firstWhere((e) => e.key == currentLang).value,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4F6BFF),
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: Color(0xFF6B7280),
                    ),
                  ],
                ),
                itemBuilder: (context) {
                  return langList.map((entry) {
                    final isSelected = entry.key == currentLang;
                    return PopupMenuItem<String>(
                      value: entry.key,
                      height: 40,
                      child: Row(
                        children: [
                          Expanded(child: Text(entry.value)),
                          if (isSelected)
                            const Icon(Icons.check,
                                size: 16, color: Color(0xFF4F6BFF)),
                        ],
                      ),
                    );
                  }).toList();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF1A1D23),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  void _showHotKeyDialog(BuildContext context) {
    // 外层变量初始化
    String? _capturedHotkey;
    int? _capturedKeyCode;
    int? _capturedModifiers;

    final notifier = ref.read(settingsNotifierProvider.notifier);
    final nativeChannel = ref.read(nativeSettingProvider);

    // 启动原生录制
    notifier.startHotKey();
    StreamSubscription<Map<String, dynamic>>? hotkeySub;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          // ✅ 在dialog内部订阅Stream，用setDialogState刷新弹窗UI
          hotkeySub = nativeChannel.hotkeyStream.listen((data) {
            setDialogState(() {
              _capturedHotkey = data['displayName'] as String;
              _capturedKeyCode = data['keyCode'] as int;
              _capturedModifiers = data['modifiers'] as int;
            });
          });

          return AlertDialog(
            title: Text(ref.tr("MODIFY_HOTKEY")),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(ref.tr("PRESS_HOTKEY_TIP")),
                const SizedBox(height: 16),
                if (_capturedHotkey != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF1FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF4F6BFF)),
                    ),
                    child: Text(
                      _capturedHotkey!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4F6BFF),
                        fontFamily: 'DM Mono',
                      ),
                    ),
                  )
                else
                  Text(ref.tr("WAITING_HOTKEY")),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  hotkeySub?.cancel();
                  notifier.stopHotKey();
                  Navigator.of(dialogContext).pop();
                },
                child: Text(ref.tr("CANCEL")),
              ),
              TextButton(
                onPressed: _capturedHotkey != null
                    ? () async {
                        await notifier.updateHotKey(
                          _capturedHotkey!,
                          _capturedModifiers!,
                          _capturedKeyCode!,
                        );
                        hotkeySub?.cancel();
                        notifier.stopHotKey();
                        Navigator.of(dialogContext).pop();
                      }
                    : null,
                child: Text(ref.tr("CONFIRM")),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      // 兜底：弹窗无论怎么关闭，都取消订阅 + 停止原生监听（防止内存泄漏）
      hotkeySub?.cancel();
      notifier.stopHotKey();
    });
  }
}
