import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../macos/index/domain/entities/clipboard_entry.dart';
import '../macos/index/domain/repositories/clipboard_repository.dart';

final iphoneClipboardServiceProvider =
    Provider((ref) => IphoneClipboardService());

class IphoneClipboardService {
  static const channel = MethodChannel('com.clipboard/ios');

  Future<ClipboardEntry?> paste(ClipboardRepository repo,
      {bool onlyIfChanged = false}) async {
    final data = await channel.invokeMapMethod<String, dynamic>(
        onlyIfChanged ? 'readClipboardIfChanged' : 'readClipboard');
    if (data == null) return null;
    if (data['type'] == 'text') {
      final text = data['text'] as String;
      if (text.isEmpty) return null;
      return save(repo, type: 'text', bytes: utf8.encode(text), text: text);
    }
    return save(repo,
        type: 'image', bytes: data['bytes'] as Uint8List, name: '剪贴板图片.png');
  }

  Future<ClipboardEntry> save(ClipboardRepository repo,
      {required String type,
      required List<int> bytes,
      String? text,
      String? name}) async {
    final hash =
        sha256.convert([...utf8.encode('$type:'), ...bytes]).toString();
    final id = 'iphone-$hash';
    final old = await repo.getEntryById(id);
    final now = DateTime.now().millisecondsSinceEpoch;
    String? relativePath;
    if (type != 'text') {
      final root = await getApplicationSupportDirectory();
      final dir = Directory('${root.path}/clipboard');
      await dir.create(recursive: true);
      final safeName = (name ?? '文件').split('/').last;
      relativePath = 'clipboard/$hash-$safeName';
      await File('${root.path}/$relativePath').writeAsBytes(bytes, flush: true);
    }
    final entry = ClipboardEntry(
        id: id,
        seq: await repo.getMaxSeq() + 1,
        type: type,
        title: text ?? name,
        preview: text ?? name,
        textContent: text,
        hash: hash,
        sizeBytes: bytes.length,
        favorite: old?.favorite ?? 0,
        sourceDevice: 'iPhone',
        createdAt: now,
        updatedAt: now,
        deleted: 0,
        filePath: relativePath);
    if (old == null) {
      await repo.insertEntry(entry);
    } else {
      await repo.updateEntry(entry);
    }
    return entry;
  }

  Future<void> syncKeyboard(ClipboardRepository repo) async {
    final entries =
        await repo.getActiveEntries(filter: 'text', keyword: '', limit: 200);
    await channel.invokeMethod(
        'syncKeyboardTexts',
        entries
            .where((entry) => entry.textContent?.isNotEmpty == true)
            .map((entry) => {
                  'text': entry.textContent!,
                  'favorite': entry.favorite == 1,
                  'createdAt': entry.createdAt,
                })
            .toList());
  }

  Future<String> resolvePath(String path) async {
    if (path.startsWith('/')) return path;
    return '${(await getApplicationSupportDirectory()).path}/$path';
  }

  Future<void> saveImageToPhotos(ClipboardEntry entry) async {
    if (entry.type != 'image' || entry.filePath == null) {
      throw StateError('图片不存在');
    }
    final saved = await channel.invokeMethod<bool>('saveImageToPhotos', {
      'path': await resolvePath(entry.filePath!),
    });
    if (saved != true) throw StateError('保存失败');
  }

  Future<void> copy(ClipboardEntry entry) async {
    if (entry.type == 'text') {
      await Clipboard.setData(ClipboardData(text: entry.textContent ?? ''));
      return;
    }
    if (entry.filePath == null) throw StateError('文件不存在');
    final ok = await channel.invokeMethod<bool>('copyFile', {
      'path': await resolvePath(entry.filePath!),
      'type': entry.type,
    });
    if (ok != true) throw StateError('无法复制文件');
  }

  Future<void> share(ClipboardEntry entry) async {
    if (entry.type == 'text') {
      await channel.invokeMethod<bool>('shareText', {
        'text': entry.textContent ?? entry.title ?? '',
      });
      return;
    }
    if (entry.filePath == null) throw StateError('文件不存在');
    final shared = await channel.invokeMethod<bool>('shareFile', {
      'path': await resolvePath(entry.filePath!),
    });
    if (shared != true) throw StateError('无法分享文件');
  }
}
