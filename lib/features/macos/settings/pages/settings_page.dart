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
        error: (err, stack) => Center(child: Text('错误: $err')),
        data: (settings) => Column(
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
                      title: '快捷键设置',
                      children: [
                        _buildHotKeyItem(
                          label: '显示粘贴板菜单',
                          currentHotKey: settings.hotKey,
                          onTap: () {
                            _showHotKeyDialog(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: '常规设置',
                      children: [
                        _buildSwitchItem(
                          label: '开机自启动',
                          value: settings.autoStart,
                          onChanged: (value) {
                            ref
                                .read(settingsNotifierProvider.notifier)
                                .updateAutoStart(value);
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: '关于',
                      children: [
                        _buildInfoItem(
                          label: '版本',
                          value: '1.0.0',
                        ),
                        _buildInfoItem(
                          label: '意见反馈',
                          value: '328889498@qq.com',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
          const Text(
            '设置',
            style: TextStyle(
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF4F6BFF),
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
    setState(() {
      _capturedHotkey = null;
      _capturedKeyCode = null;
      _capturedModifiers = null;
    });

    // 开始录制快捷键
    final notifier = ref.read(settingsNotifierProvider.notifier);
    notifier.startHotKey();

    // 监听快捷键录制
    final nativeChannel = ref.read(nativeClipboardProvider);
    _hotkeySubscription?.cancel();
    _hotkeySubscription = nativeChannel.hotkeyStream.listen((data) {
      setState(() {
        _capturedHotkey = data['displayName'] as String;
        _capturedKeyCode = data['keyCode'] as int;
        _capturedModifiers = data['modifiers'] as int;
      });
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          // 监听捕获状态
          _hotkeySubscription = nativeChannel.hotkeyStream.listen((data) {
            setDialogState(() {
              _capturedHotkey = data['displayName'] as String;
              _capturedKeyCode = data['keyCode'] as int;
              _capturedModifiers = data['modifiers'] as int;
            });
          });

          return AlertDialog(
            title: const Text('修改快捷键'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('按下你想设置的快捷键组合'),
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
                  const CircularProgressIndicator(),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _hotkeySubscription?.cancel();
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: _capturedHotkey != null
                    ? () async {
                        // 保存快捷键
                        await notifier.updateHotKey(
                          _capturedHotkey!,
                          _capturedModifiers!,
                          _capturedKeyCode!,
                        );
                        _hotkeySubscription?.cancel();
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                      }
                    : null,
                child: const Text('确定'),
              ),
            ],
          );
        },
      ),
    );
  }
}
