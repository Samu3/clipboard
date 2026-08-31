import 'dart:async';
import 'dart:io';
import 'package:clipboard/features/macos/index/providers/clipboard_list_notifier.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clipboard/features/macos/index/domain/entities/clipboard_entry.dart';
import 'package:clipboard/features/macos/index/providers/clipboard_providers.dart';
import 'package:path_provider/path_provider.dart';

class MacIndex extends ConsumerStatefulWidget {
  const MacIndex({super.key});

  @override
  ConsumerState<MacIndex> createState() => _MacIndexState();
}

class _MacIndexState extends ConsumerState<MacIndex> {
  Timer? _searchDebounceTimer;
  // 新增：选中条目
  ClipboardEntry? selectedEntry;

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filterType = ref.watch(clipboardFilterProvider);
    final listAsync = ref.watch(clipboardListNotifierProvider);
    final notifier = ref.watch(clipboardListNotifierProvider.notifier);
    final cacheDirAsync = ref.watch(appCacheDirProvider);

    return cacheDirAsync.when(
      loading: () => const Material(
        color: Colors.transparent,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Material(
        color: Colors.transparent,
        child: Center(child: Text("缓存目录初始化失败：$err")),
      ),
      data: (Directory cacheDir) {
        // ✅ cacheDir 拿到了，往下传递给所有子组件
        return Material(
          color: Colors.transparent,
          child: Container(
            child: Row(
              children: [
                leftMenu(context, ref, filterType),
                Expanded(
                  child: buildRightMainArea(
                    context,
                    ref,
                    listAsync,
                    notifier,
                    selectedEntry,
                    cacheDir: cacheDir, // 把cacheDir传进去
                    onSelectEntry: (entry) {
                      setState(() {
                        selectedEntry = entry;
                      });
                    },
                    onCloseDetail: () {
                      setState(() {
                        selectedEntry = null;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildRightMainArea(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ClipboardEntry>> listAsync,
    ClipboardListNotifier notifier,
    ClipboardEntry? selectedEntry, {
    required Directory cacheDir, // 新增
    required ValueChanged<ClipboardEntry> onSelectEntry,
    required VoidCallback onCloseDetail,
  }) {
    if (selectedEntry != null) {
      // 传给详情页
      return buildDetailPage(selectedEntry, onCloseDetail, cacheDir);
    }

    // 否则渲染原来的列表页面
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 0.63,
                  color: const Color(0xFFF3F4F6),
                ),
              ),
            ),
            child: listAsync.when(
              loading: () => const Text(
                '加载中...',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 11,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1.50,
                ),
              ),
              error: (err, st) => Text(
                '读取失败',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 11,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1.50,
                ),
              ),
              data: (list) => Text(
                '${list.length} 条记录',
                style: TextStyle(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 11,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1.50,
                ),
              ),
            ),
          ),
          Expanded(
            child: listAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('错误：$err')),
              data: (entryList) {
                return NotificationListener<ScrollUpdateNotification>(
                  onNotification: (notification) {
                    final scrollDistance = notification.metrics.pixels;
                    final maxScroll = notification.metrics.maxScrollExtent;
                    if (scrollDistance >= maxScroll - 200) {
                      if (!notifier.hasMore) return false;
                      notifier.loadMore();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: entryList.length + 1,
                    itemBuilder: (ctx, index) {
                      if (index == entryList.length) {
                        if (notifier.hasMore) {
                          return const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                          );
                        } else {
                          return const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Center(
                                child: Text("没有更多记录了",
                                    style: TextStyle(color: Colors.grey))),
                          );
                        }
                      }
                      final entry = entryList[index];
                      return item(
                        context,
                        ref,
                        entry,
                        cacheDir: cacheDir, // 传给item
                        onTapItem: () => onSelectEntry(entry),
                        onToggleFavorite: () =>
                            notifier.toggleFavorite(entry.id),
                        onDelete: () => notifier.softDelete(entry.id),
                      );
                    },
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  // ========== 详情页面 ==========
  Widget buildDetailPage(
      ClipboardEntry entry, VoidCallback onClose, Directory cacheDir) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onClose,
                  child: const Icon(Icons.arrow_back_ios_new, size: 16),
                ),
                const SizedBox(width: 8),
                Text(entry.type == "image"
                    ? "图片详情"
                    : entry.type == "file"
                        ? "文件详情"
                        : "文本详情"),
                const Spacer(),
                if (entry.type == "file")
                  ElevatedButton(
                      onPressed: () async {
                        final List<String> tempPaths =
                            (entry.textContent ?? "").split(",").toList();
                        final result =
                            await FilePicker.platform.getDirectoryPath();
                        if (result == null) return;
                        final saveDir = Directory(result!);
                        for (final srcPath in tempPaths) {
                          final srcFile = File(srcPath);
                          if (!await srcFile.exists()) continue;
                          final targetFile = File(
                              "${saveDir.path}/${srcFile.path.split("/").last}");
                          await srcFile.copy(targetFile.path);
                        }
                      },
                      child: const Text("下载"))
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              // 传入cacheDir
              child: buildDetailContent(entry, cacheDir),
            ),
          )
        ],
      ),
    );
  }

  Widget buildDetailContent(ClipboardEntry entry, Directory cacheDir) {
    switch (entry.type) {
      case "text":
        return SelectableText(
          entry.textContent ?? "",
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: Color(0xFF1A1D23),
          ),
        );
      case "image":
        // ✅ 同步获取路径，不再FutureBuilder
        final imgPath = getImageCachePath(cacheDir, entry.hash ?? "");
        debugPrint(imgPath);
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.file(
            File(imgPath),
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, st) => const Text("图片损坏"),
          ),
        );
      case "file":
        final List<String> tempPaths =
            (entry.textContent ?? "").split(",").toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.preview ?? ""),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final result = await FilePicker.platform.getDirectoryPath();
                if (result == null) return;
                final saveDir = Directory(result!);
                for (final srcPath in tempPaths) {
                  final srcFile = File(srcPath);
                  if (!await srcFile.exists()) continue;
                  final targetFile =
                      File("${saveDir.path}/${srcFile.path.split("/").last}");
                  await srcFile.copy(targetFile.path);
                }
              },
              child: const Text("下载文件"),
            )
          ],
        );
      default:
        return Text(entry.preview ?? "");
    }
  }

  Widget item(BuildContext context, WidgetRef ref, ClipboardEntry entry,
      {required Directory cacheDir, // 新增
      required VoidCallback onTapItem,
      required VoidCallback onToggleFavorite,
      required VoidCallback onDelete}) {
    final timeText = _formatTime(entry.createdAt);
    final sourceText = entry.sourceDevice ?? "本机";
    return InkWell(
      onTap: onTapItem,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: ShapeDecoration(
          color: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 0.63,
              color: const Color(0xFFF7F8FA),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: _buildItemLeading(entry, cacheDir),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1A1D23),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.40,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        timeText,
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 10,
                          fontFamily: 'DM Mono',
                          fontWeight: FontWeight.w400,
                          height: 1.50,
                        ),
                      ),
                      const Text(
                        ' · ',
                        style: TextStyle(
                          color: Color(0xFFC4C9D4),
                          fontSize: 10,
                          fontFamily: 'Inter',
                          height: 1.50,
                        ),
                      ),
                      Text(
                        sourceText,
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 10,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.50,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (entry.favorite == 1)
              Container(
                width: 3.99,
                height: 3.99,
                decoration: ShapeDecoration(
                  color: Color(0xFF4F6BFF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemLeading(ClipboardEntry entry, Directory cacheDir) {
    if (entry.type == "image") {
      final imgPath = getImageCachePath(cacheDir, entry.hash ?? "");

      return ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Image.file(
          File(imgPath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const ColoredBox(color: Color(0xFFEEF1FF));
          },
        ),
      );
    } else {
      return Container(
        decoration: ShapeDecoration(
          color: Color(0xFFEEF1FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        child: Center(
          child: Text(
            _getTypeIcon(entry.type),
            style: const TextStyle(fontSize: 14, color: Color(0xFF4F6BFF)),
          ),
        ),
      );
    }
  }

  Widget leftMenu(BuildContext context, WidgetRef ref, String activeFilter) {
    return Container(
      width: 122.28,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: ShapeDecoration(
        color: const Color(0xFFFAFAFA),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 0.63,
            color: const Color(0xFFE4E6EB),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索框【增加防抖】
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextField(
              onChanged: (value) {
                _searchDebounceTimer?.cancel();
                _searchDebounceTimer =
                    Timer(const Duration(milliseconds: 300), () {
                  ref.read(clipboardSearchKeywordProvider.notifier).state =
                      value;
                });
              },
              decoration: InputDecoration(
                hintText: "搜索",
                hintStyle: const TextStyle(
                  color: Color(0x7F1A1D23),
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                isDense: true,
              ),
            ),
          ),

          // 菜单项
          _buildMenuItem(
            iconText: '⊞',
            label: '全部',
            filterKey: 'all',
            active: activeFilter == 'all',
            ref: ref,
          ),
          const SizedBox(height: 4),
          _buildMenuItem(
            iconText: 'T',
            label: '文本',
            filterKey: 'text',
            ref: ref,
            active: activeFilter == 'text',
          ),
          const SizedBox(height: 4),
          _buildMenuItem(
            iconText: '⬚',
            label: '图片',
            filterKey: 'image',
            ref: ref,
            active: activeFilter == 'image',
          ),
          const SizedBox(height: 4),
          _buildMenuItem(
            iconText: '□',
            label: '文件',
            filterKey: 'file',
            ref: ref,
            active: activeFilter == 'file',
          ),
          const SizedBox(height: 4),
          _buildMenuItem(
            iconText: '★',
            label: '收藏',
            filterKey: 'favorite',
            ref: ref,
            active: activeFilter == 'favorite',
          ),

          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  /// 单个侧边菜单项
  Widget _buildMenuItem({
    required String iconText,
    required String label,
    required String filterKey,
    required WidgetRef ref,
    bool active = false,
  }) {
    final Color iconColor =
        active ? const Color(0xFF4F6BFF) : const Color(0xFF6B7280);
    final Color textColor =
        active ? const Color(0xFF4F6BFF) : const Color(0xFF6B7280);
    final Color? bgColor = active ? const Color(0xFFEEF1FF) : null;

    return GestureDetector(
      onTap: () {
        ref.read(clipboardFilterProvider.notifier).state = filterKey;
      },
      child: Container(
        width: 105.66,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: ShapeDecoration(
          color: bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 15.99,
              child: Text(
                iconText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  height: 1.50,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                height: 1.50,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeIcon(String type) {
    switch (type) {
      case "text":
        return "T";
      case "image":
        return "🖼";
      case "file":
        return "📄";
      default:
        return "•";
    }
  }

  String _formatTime(int ms) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - ms;
    final minute = (diff / (1000 * 60)).floor();
    if (minute < 1) return "刚刚";
    if (minute < 60) return "$minute 分钟前";
    final hour = minute ~/ 60;
    if (hour < 24) return "$hour 小时前";
    final day = hour ~/ 24;
    return "$day 天前";
  }
}

/// 封装同步获取图片完整路径（依赖上面provider加载完成后使用）
String getImageCachePath(Directory cacheDir, String hash) {
  return "${cacheDir.path}/$hash.png";
}
