import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// 日志级别
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// 日志分类
enum LogCategory { http, common, database, ui, performance, methodChannel }

/// 日志系统
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  File? _logFile;
  final List<String> _logBuffer = [];
  static const int _maxBufferSize = 50; // 缓存50条后写入文件

  /// 初始化日志文件
  Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');

      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _logFile = File('${logDir.path}/app_$dateStr.log');

      // 如果文件不存在，创建文件
      if (!await _logFile!.exists()) {
        await _logFile!.create();
      }
    } catch (e) {
      debugPrint('日志文件初始化失败: $e');
    }
  }

  /// 写入日志
  void log(
    String message, {
    LogLevel level = LogLevel.info,
    LogCategory category = LogCategory.common,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timestamp =
        DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
    final levelStr = level.name.toUpperCase().padRight(7);
    final categoryStr = '[${category.name.toUpperCase()}]'.padRight(12);

    final logLine = '$timestamp $levelStr $categoryStr $message';

    // 在开发模式下打印到控制台
    if (kDebugMode) {
      _printWithColor(logLine, level);
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }

    // 添加到缓冲区
    _logBuffer.add(logLine);
    if (error != null) {
      _logBuffer.add('Error: $error');
    }
    if (stackTrace != null) {
      _logBuffer.add('StackTrace: $stackTrace');
    }

    // 如果缓冲区满了，写入文件
    if (_logBuffer.length >= _maxBufferSize) {
      _flushToFile();
    }
  }

  /// 打印带颜色的日志（仅开发模式）
  void _printWithColor(String message, LogLevel level) {
    const reset = '\x1B[0m';
    String color;

    switch (level) {
      case LogLevel.debug:
        color = '\x1B[37m'; // 白色
        break;
      case LogLevel.info:
        color = '\x1B[32m'; // 绿色
        break;
      case LogLevel.warning:
        color = '\x1B[33m'; // 黄色
        break;
      case LogLevel.error:
        color = '\x1B[31m'; // 红色
        break;
    }

    debugPrint('$message');
  }

  /// 将缓冲区内容写入文件
  Future<void> _flushToFile() async {
    if (_logFile == null || _logBuffer.isEmpty) return;

    try {
      final content = _logBuffer.join('\n') + '\n';
      await _logFile!.writeAsString(content, mode: FileMode.append);
      _logBuffer.clear();
    } catch (e) {
      debugPrint('写入日志文件失败: $e');
    }
  }

  /// 强制刷新缓冲区到文件
  Future<void> flush() async {
    await _flushToFile();
  }

  /// 获取当前日志文件路径
  String? get logFilePath => _logFile?.path;

  /// 清理旧日志（保留最近N天）
  Future<void> cleanOldLogs({int keepDays = 7}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');

      if (!await logDir.exists()) return;

      final now = DateTime.now();
      final files = await logDir.list().toList();

      for (var file in files) {
        if (file is File && file.path.endsWith('.log')) {
          final stat = await file.stat();
          final age = now.difference(stat.modified).inDays;

          if (age > keepDays) {
            await file.delete();
            debugPrint('删除旧日志: ${file.path}');
          }
        }
      }
    } catch (e) {
      debugPrint('清理旧日志失败: $e');
    }
  }

  // 便捷方法
  void d(String message, {LogCategory category = LogCategory.common}) {
    log(message, level: LogLevel.debug, category: category);
  }

  void i(String message, {LogCategory category = LogCategory.common}) {
    log(message, level: LogLevel.info, category: category);
  }

  void w(String message, {LogCategory category = LogCategory.common}) {
    log(message, level: LogLevel.warning, category: category);
  }

  void e(
    String message, {
    LogCategory category = LogCategory.common,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      message,
      level: LogLevel.error,
      category: category,
      error: error,
      stackTrace: stackTrace,
    );
  }

  // HTTP 专用方法
  void http(String message, {LogLevel level = LogLevel.info}) {
    log(message, level: level, category: LogCategory.http);
  }

  void methodChannel(String message, {LogLevel level = LogLevel.info}) {
    log(message, level: level, category: LogCategory.methodChannel);
  }

  void common(String message, {LogLevel level = LogLevel.info}) {
    log(message, level: level, category: LogCategory.common);
  }
}

/// 全局日志实例
final logger = AppLogger();
