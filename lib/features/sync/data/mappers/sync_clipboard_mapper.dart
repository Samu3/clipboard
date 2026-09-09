import 'dart:convert';

import 'package:clipboard/features/macos/index/domain/entities/clipboard_entry.dart';

import '../../domain/entities/sync_clipboard_item.dart';

extension SyncClipboardMapper on ClipboardEntry {
  SyncClipboardItem toSyncItem() => SyncClipboardItem(
        id: id,
        type: type,
        title: title ?? preview ?? type,
        textContent: type == 'text' ? textContent : null,
        fileName: title,
        filePath: filePath ?? _firstFilePath(type, textContent),
        sizeBytes: sizeBytes,
        createdAt: createdAt,
        sourceDevice: sourceDevice,
      );
}

String? _firstFilePath(String type, String? value) {
  if (type != 'file' || value == null || value.isEmpty) return null;
  try {
    final paths = List<String>.from(jsonDecode(value) as List);
    return paths.isEmpty ? null : paths.first;
  } catch (_) {
    final paths = value.split(',');
    return paths.isEmpty ? null : paths.first;
  }
}
