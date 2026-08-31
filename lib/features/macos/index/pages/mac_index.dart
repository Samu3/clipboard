import 'dart:async';
import 'package:clipboard/features/macos/index/providers/clipboard_list_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clipboard/features/macos/index/domain/entities/clipboard_entry.dart';
import 'package:clipboard/features/macos/index/providers/clipboard_providers.dart';

class MacIndex extends ConsumerStatefulWidget {
  const MacIndex({super.key});

  @override
  ConsumerState<MacIndex> createState() => _MacIndexState();
}

class _MacIndexState extends ConsumerState<MacIndex> {
  Timer? _searchDebounceTimer;

  @override
  void dispose() {
    // 页面销毁，取消定时器，防止内存泄漏
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filterType = ref.watch(clipboardFilterProvider);
    final listAsync = ref.watch(clipboardListNotifierProvider);
    final notifier = ref.watch(clipboardListNotifierProvider.notifier);

    return Material(
      color: Colors.transparent,
      child: Container(
        child: Row(
          children: [
            leftMenu(context, ref, filterType),
            Expanded(
              child: buildRightMainArea(context, ref, listAsync, notifier),
            ),
          ],
        ),
      ),
    );
  }

  /// 右侧主内容区域
  Widget buildRightMainArea(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ClipboardEntry>> listAsync,
    ClipboardListNotifier notifier,
  ) {
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
                    // 判断是否滚动到底部
                    final scrollDistance = notification.metrics.pixels;
                    final maxScroll = notification.metrics.maxScrollExtent;
                    // 距离底部还有200像素预加载
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
                      // 最后一项，渲染加载更多footer
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

  /// 单个列表Item
  Widget item(
    BuildContext context,
    WidgetRef ref,
    ClipboardEntry entry, {
    required VoidCallback onToggleFavorite,
    required VoidCallback onDelete,
  }) {
    final timeText = _formatTime(entry.createdAt);
    final sourceText = entry.sourceDevice ?? "本机";
    return Container(
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
          Container(
            width: 26,
            height: 26,
            decoration: ShapeDecoration(
              color: const Color(0xFFEEF1FF),
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
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title ?? entry.preview ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF1A1D23),
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
                      style: TextStyle(
                        color: const Color(0xFF9CA3AF),
                        fontSize: 10,
                        fontFamily: 'DM Mono',
                        fontWeight: FontWeight.w400,
                        height: 1.50,
                      ),
                    ),
                    const Text(
                      ' · ',
                      style: TextStyle(
                        color: const Color(0xFFC4C9D4),
                        fontSize: 10,
                        fontFamily: 'Inter',
                        height: 1.50,
                      ),
                    ),
                    Text(
                      sourceText,
                      style: TextStyle(
                        color: const Color(0xFF9CA3AF),
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
                color: const Color(0xFF4F6BFF),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
        ],
      ),
    );
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
