import 'dart:convert';
import 'dart:io';
import 'package:clipboard/features/macos/index/providers/clipboard_list_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final nativeClipboardProvider = Provider<NativeClipboardChannel>((ref) {
  final channel = NativeClipboardChannel(ref);
  // 保持 provider 存活，防止被垃圾回收导致 MethodCallHandler 失效
  ref.keepAlive();
  return channel;
});

class NativeClipboardChannel {
  final Ref ref;
  late MethodChannel _channel;
  String? _lastHash;

  NativeClipboardChannel(this.ref) {
    _channel = const MethodChannel("com.clipboard/channel");
    _channel.setMethodCallHandler(_handleMethod);
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    debugPrint("🔔 收到 Native 调用: ${call.method}");
    if (call.method == "onClipboardChange") {
      debugPrint("📋 粘贴板内容变化: ${call.arguments}");
      final data = call.arguments as Map;
      final String type = data["type"];
      final Map payload = data["payload"];
      await _processClipItem(type, payload);
    }
  }

  Future<void> _processClipItem(String type, Map payload) async {
    final notifier = ref.read(clipboardListNotifierProvider.notifier);
    String id;
    String title;
    String preview;
    String textContent = "";
    String hash;
    int sizeBytes = 0;

    switch (type) {
      case "text":
        final String txt = payload["text"];
        final bytes = utf8.encode(txt);
        hash = md5.convert(bytes).toString();
        if (hash == _lastHash) return;
        _lastHash = hash;
        id = hash;
        title = txt.length > 60 ? txt.substring(0, 60) : txt;
        preview = txt;
        textContent = txt;
        sizeBytes = bytes.length;
        await notifier.addEntry(
          id: id,
          type: "text",
          title: title,
          preview: preview,
          textContent: textContent,
          hash: hash,
          sizeBytes: sizeBytes,
          sourceDevice: "Mac本机",
        );
        break;

      case "image":
        final String tempFilePath = payload["filePath"];
        // 新增：从payload读取图片原始文件名
        final String originImageName = payload["fileName"];
        final File tempFile = File(tempFilePath);
        if (!await tempFile.exists()) return;

        final imgBytes = await tempFile.readAsBytes();
        hash = md5.convert(imgBytes).toString();
        if (hash == _lastHash) return;
        _lastHash = hash;
        id = hash;
        title = originImageName; // 图片title=文件名
        preview = "[图片]";
        sizeBytes = imgBytes.length;

        await saveImageCache(imgBytes, hash);
        await notifier.addEntry(
          id: id,
          type: "image",
          title: title,
          preview: preview,
          hash: hash,
          sizeBytes: sizeBytes,
          sourceDevice: "Mac本机",
        );
        break;

      case "file":
        final List<String> tempFilePaths =
            List<String>.from(payload["filePaths"]);
        List<List<int>> allFileBytes = [];
        int totalSize = 0;
        List<String> fileNameList = [];

        for (final path in tempFilePaths) {
          final f = File(path);
          if (!await f.exists()) continue;
          final bytes = await f.readAsBytes();
          allFileBytes.add(bytes);
          totalSize += bytes.length;
          fileNameList.add(f.path.split("/").last);
        }

        final combineBytes = allFileBytes.expand((e) => e).toList();
        hash = md5.convert(combineBytes).toString();
        if (hash == _lastHash) return;
        _lastHash = hash;
        id = hash;

        title =
            fileNameList.isNotEmpty ? fileNameList.first : ""; // 文件title：第一个文件名
        preview = "[文件] ${tempFilePaths.length}个文件";
        textContent = tempFilePaths.join(",");
        sizeBytes = totalSize;

        await notifier.addEntry(
          id: id,
          type: "file",
          title: title,
          preview: preview,
          textContent: textContent,
          hash: hash,
          sizeBytes: sizeBytes,
          sourceDevice: "Mac本机",
        );
        break;
    }
  }

  Future<void> saveImageCache(List<int> imgBytes, String hash) async {
    // 缓存图片到应用支持目录，Dart读取显示
    // 可使用 path_provider 获取ApplicationSupportDirectory
  }
}
