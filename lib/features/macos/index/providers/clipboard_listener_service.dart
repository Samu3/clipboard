import 'dart:async';
import 'dart:convert';
import 'package:clipboard/features/macos/index/providers/clipboard_list_notifier.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final clipboardListenerServiceProvider =
    Provider<ClipboardListenerService>((ref) {
  return ClipboardListenerService(ref);
});

class ClipboardListenerService {
  final Ref ref;
  Timer? _pollTimer;
  String? _lastClipHash;
  // 轮询间隔 800ms，兼顾性能和实时性
  static const Duration _pollDuration = Duration(milliseconds: 800);

  ClipboardListenerService(this.ref);

  /// 启动监听
  void startListen() {
    if (_pollTimer != null) return;
    _pollTimer = Timer.periodic(_pollDuration, (_) async {
      await _checkClipboard();
    });
  }

  /// 停止监听
  void stopListen() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// 读取剪贴板 + 判断是否更新
  Future<void> _checkClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;

    // 生成MD5 hash用于去重
    final bytes = utf8.encode(text);
    final hash = md5.convert(bytes).toString();

    // 和上一次剪贴内容一致，直接跳过
    if (hash == _lastClipHash) return;
    _lastClipHash = hash;

    // 写入数据库
    final notifier = ref.read(clipboardListNotifierProvider.notifier);
    await notifier.addEntry(
      id: hash,
      type: "text",
      title: text.length > 60 ? text.substring(0, 60) : text,
      preview: text,
      textContent: text,
      hash: hash,
      sizeBytes: bytes.length,
      sourceDevice: "Mac",
    );
  }
}
