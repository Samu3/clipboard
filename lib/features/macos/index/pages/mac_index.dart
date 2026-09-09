import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clipboard/core/locale/utils/translation_helper.dart';
import 'package:clipboard/core/utils/app_toast.dart';
import 'package:clipboard/features/macos/index/providers/clipboard_list_notifier.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clipboard/features/macos/index/domain/entities/clipboard_entry.dart';
import 'package:clipboard/features/macos/index/providers/clipboard_providers.dart';
import 'package:go_router/go_router.dart';

class MacIndex extends ConsumerStatefulWidget {
  const MacIndex({super.key});

  @override
  ConsumerState<MacIndex> createState() => _MacIndexState();
}

class _MacIndexState extends ConsumerState<MacIndex> {
  Timer? _searchDebounceTimer;
  // 新增：选中条目
  ClipboardEntry? selectedEntry;
  final Set<String> selectedTransfers = {};

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
        child: Center(child: Text("$err")),
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
                    filterType: filterType,
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
    required String filterType,
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
              loading: () => Text(
                ref.tr("LOADING"),
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 11,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1.50,
                ),
              ),
              error: (err, st) => Text(
                ref.tr("READ_FAILED"),
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 11,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1.50,
                ),
              ),
              data: (list) => Text(
                '${list.length}${ref.tr("RECORD_COUNT_SUFFIX")}',
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
          if (filterType == 'transfer')
            _transferToolbar(
                context, listAsync.valueOrNull ?? const [], notifier),
          Expanded(
            child: listAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('${ref.tr("ERROR")}：$err')),
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
                          return Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Center(
                                child: Text(ref.tr("NO_MORE_RECORDS"),
                                    style: TextStyle(color: Colors.grey))),
                          );
                        }
                      }
                      final entry = entryList[index];
                      final entryWidget = item(context, ref, entry,
                          cacheDir: cacheDir, // 传给item
                          onTapItem: () {
                            if (filterType == 'transfer') {
                              setState(() =>
                                  selectedTransfers.contains(entry.id)
                                      ? selectedTransfers.remove(entry.id)
                                      : selectedTransfers.add(entry.id));
                              return;
                            }
                            // Toast
                            if (context.mounted) {
                              AppToast.show(context, ref.tr("COPY_SUCCESS"));
                            }
                            notifier.copyClipboardEntry(entry);
                          },
                          onToggleFavorite: () =>
                              notifier.toggleFavorite(entry.id),
                          onTapDetail: () => onSelectEntry(entry),
                          onDelete: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(ref.tr("CONFIRM_DELETE")),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: Text(ref.tr("CANCEL"))),
                                  TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text(ref.tr("DELETE"))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              notifier.softDelete(entry);
                            }
                          });
                      if (filterType != 'transfer') return entryWidget;
                      return Row(children: [
                        Checkbox(
                          value: selectedTransfers.contains(entry.id),
                          onChanged: (_) => setState(() =>
                              selectedTransfers.contains(entry.id)
                                  ? selectedTransfers.remove(entry.id)
                                  : selectedTransfers.add(entry.id)),
                        ),
                        Expanded(child: entryWidget),
                      ]);
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

  Widget _transferToolbar(BuildContext context, List<ClipboardEntry> entries,
      ClipboardListNotifier notifier) {
    final selected =
        entries.where((entry) => selectedTransfers.contains(entry.id)).toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFFF8FAFF),
      child: Row(children: [
        Checkbox(
          value: entries.isNotEmpty && selected.length == entries.length,
          tristate: selected.isNotEmpty && selected.length != entries.length,
          onChanged: (_) => setState(() {
            if (selected.length == entries.length) {
              selectedTransfers.clear();
            } else {
              selectedTransfers.addAll(entries.map((entry) => entry.id));
            }
          }),
        ),
        Text('已选择 ${selected.length} 项'),
        const Spacer(),
        // TextButton.icon(
        //   onPressed: selected.isEmpty ? null : () => _viewTransfers(selected),
        //   icon: const Icon(Icons.visibility_outlined),
        //   label: const Text('批量查看'),
        // ),
        const SizedBox(width: 6),
        FilledButton.tonalIcon(
          onPressed: selected.isEmpty ? null : () => _saveTransfers(selected),
          icon: const Icon(Icons.drive_folder_upload_outlined),
          label: const Text('保存到文件夹'),
        ),
        const SizedBox(width: 6),
        TextButton.icon(
          onPressed: selected.isEmpty
              ? null
              : () => _deleteTransfers(context, selected, notifier),
          icon: const Icon(Icons.delete_outline),
          label: const Text('批量删除'),
        ),
      ]),
    );
  }

  Future<void> _saveTransfers(List<ClipboardEntry> entries) async {
    final directory = await FilePicker.platform.getDirectoryPath();
    if (directory == null) return;
    for (final entry in entries) {
      final path = entry.filePath;
      if (path == null) continue;
      final source = File(path);
      if (!await source.exists()) continue;
      final name = entry.title ?? source.uri.pathSegments.last;
      var target = File('$directory/$name');
      var suffix = 1;
      while (await target.exists()) {
        final dot = name.lastIndexOf('.');
        final base = dot > 0 ? name.substring(0, dot) : name;
        final extension = dot > 0 ? name.substring(dot) : '';
        target = File('$directory/$base ($suffix)$extension');
        suffix++;
      }
      await source.copy(target.path);
    }
    if (mounted) AppToast.show(context, '已保存 ${entries.length} 个项目');
  }

  Future<void> _viewTransfers(List<ClipboardEntry> entries) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('已选择 ${entries.length} 个项目'),
          content: SizedBox(
            width: 460,
            height: 320,
            child: ListView(
              children: entries
                  .map((entry) => ListTile(
                        leading: Icon(entry.type == 'image'
                            ? Icons.image_outlined
                            : Icons.insert_drive_file_outlined),
                        title: Text(entry.title ?? '未命名文件'),
                        subtitle: SelectableText(entry.filePath ?? '文件不可用'),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => selectedEntry = entry);
                        },
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'))
          ],
        ),
      );

  Future<void> _deleteTransfers(BuildContext context,
      List<ClipboardEntry> entries, ClipboardListNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除 ${entries.length} 个传输项目？'),
        content: const Text('记录及应用内保存的文件将被删除。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('删除')),
        ],
      ),
    );
    if (confirmed != true) return;
    for (final entry in entries) {
      final path = entry.filePath;
      if (path != null) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
      await notifier.softDelete(entry);
    }
    if (mounted) setState(selectedTransfers.clear);
  }

  // ========== 详情页面 ==========
  Widget buildDetailPage(
      ClipboardEntry entry, VoidCallback onClose, Directory cacheDir) {
    // ✅ 在 StatefulBuilder 外部创建 controller，避免重建时丢失内容
    final editController = TextEditingController(text: entry.textContent ?? "");

    return Container(
      color: Colors.white,
      child: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        editController.dispose(); // 关闭时释放
                        onClose();
                      },
                      child: const Icon(Icons.arrow_back_ios_new, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(entry.type == "image"
                        ? ref.tr("IMAGE_DETAIL")
                        : entry.type == "file"
                            ? ref.tr("FILE_DETAIL")
                            : ref.tr("TEXT_DETAIL")),
                    const Spacer(),
                    // ===== 右上角按钮区域 =====
                    if (entry.type == "text")
                      ElevatedButton(
                        onPressed: () async {
                          // ✅ 点击对勾：复制编辑后的文本到系统剪贴板
                          final newText = editController.text;
                          await Clipboard.setData(ClipboardData(text: newText));
                          onClose();
                          if (context.mounted) {
                            AppToast.show(context, ref.tr("COPY_SUCCESS"));
                          }
                        },
                        child: Text(ref.tr("UPDATE")),
                      ),

                    if (entry.type == "image")
                      ElevatedButton(
                        onPressed: () async {
                          // 图片保存：选择文件夹
                          final selectedDirPath =
                              await FilePicker.platform.getDirectoryPath();
                          if (selectedDirPath == null) return;
                          final imgFile = File(entry.filePath!);
                          if (!await imgFile.exists()) return;
                          final fileName = imgFile.path.split("/").last;
                          final targetFile = File("$selectedDirPath/$fileName");
                          await imgFile.copy(targetFile.path);
                        },
                        child: Text(ref.tr("SAVE_IMAGE")),
                      ),
                    if (entry.type == "file")
                      ElevatedButton(
                          onPressed: () async {
                            final paths = _filePathsForEntry(entry);
                            final result =
                                await FilePicker.platform.getDirectoryPath();
                            if (result == null) return;
                            final saveDir = Directory(result);
                            for (final srcPath in paths) {
                              final srcFile = File(srcPath);
                              if (!await srcFile.exists()) continue;
                              final targetFile = File(
                                  "${saveDir.path}/${srcFile.path.split("/").last}");
                              await srcFile.copy(targetFile.path);
                            }
                          },
                          child: Text(ref.tr("DOWNLOAD")))
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: buildDetailContent(entry, cacheDir, editController),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget buildDetailContent(
    ClipboardEntry entry,
    Directory cacheDir,
    TextEditingController editController,
  ) {
    switch (entry.type) {
      case "text":
        // 直接多行输入框，无需切换编辑状态，打开页面即可编辑
        return TextField(
          controller: editController,
          maxLines: null,
          minLines: 1,
          expands: false,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: ref.tr("EDIT_TEXT_HINT"),
          ),
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: Color(0xFF1A1D23),
          ),
        );
      case "image":
        final imgPath = entry.filePath ?? "";
        debugPrint(imgPath);
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.file(
            File(imgPath),
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, st) => Text(ref.tr("IMAGE_BROKEN")),
          ),
        );
      case "file":
        final paths = _filePathsForEntry(entry);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(paths.join('\n')),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final result = await FilePicker.platform.getDirectoryPath();
                if (result == null) return;
                final saveDir = Directory(result);
                for (final srcPath in paths) {
                  final srcFile = File(srcPath);
                  if (!await srcFile.exists()) continue;
                  final targetFile =
                      File("${saveDir.path}/${srcFile.path.split("/").last}");
                  await srcFile.copy(targetFile.path);
                }
              },
              child: Text(ref.tr("DOWNLOAD_FILE")),
            )
          ],
        );
      default:
        return Text(entry.preview ?? "");
    }
  }

  Widget item(BuildContext context, WidgetRef ref, ClipboardEntry entry,
      {required Directory cacheDir, // 新增
      required VoidCallback onTapDetail,
      required VoidCallback onTapItem,
      required VoidCallback onToggleFavorite,
      required VoidCallback onDelete}) {
    final timeText = _formatTime(entry.createdAt);
    final sourceText = entry.sourceDevice ?? ref.tr("LOCAL_DEVICE");
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
                  if (entry.type == 'file') ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.preview ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ],
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
                      Text(
                        ref.tr("TIME_SEP"),
                        style: const TextStyle(
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

            // ====== 新增【详情按钮】眼睛图标 ======
            const SizedBox(width: 8),
            SizedBox(
              width: 22,
              height: 22,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: onTapDetail,
                icon: const Icon(
                  Icons.remove_red_eye_outlined,
                  size: 14,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ),

            // ========== 新增收藏按钮（详情 和 删除中间） ==========
            IconButton(
              onPressed: onToggleFavorite,
              icon: Icon(
                entry.favorite == 1 ? Icons.star : Icons.star_border,
                size: 18,
                color: entry.favorite == 1 ? Colors.amber : Colors.grey,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),

            // ====== 新增删除按钮 ======
            const SizedBox(width: 8),

            SizedBox(
              width: 22,
              height: 22,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: onDelete,
                icon: const Icon(
                  Icons.close,
                  size: 14,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemLeading(ClipboardEntry entry, Directory cacheDir) {
    if (entry.type == "image") {
      final imgPath = entry.filePath ?? "";

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
      width: 150,
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
                hintText: ref.tr("SEARCH"),
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
            iconText: '',
            label: ref.tr("QUAN_BU"),
            filterKey: 'all',
            active: activeFilter == 'all',
            ref: ref,
          ),
          const SizedBox(height: 4),
          _buildMenuItem(
            iconText: '',
            label: ref.tr("TEXT"),
            filterKey: 'text',
            ref: ref,
            active: activeFilter == 'text',
          ),
          const SizedBox(height: 4),
          _buildMenuItem(
            iconText: '',
            label: ref.tr("IMAGE"),
            filterKey: 'image',
            ref: ref,
            active: activeFilter == 'image',
          ),
          const SizedBox(height: 4),
          _buildMenuItem(
            iconText: '',
            label: ref.tr("FILE"),
            filterKey: 'file',
            ref: ref,
            active: activeFilter == 'file',
          ),
          const SizedBox(height: 4),
          _buildMenuItem(
            iconText: '',
            label: '传输文件夹',
            filterKey: 'transfer',
            ref: ref,
            active: activeFilter == 'transfer',
          ),
          const SizedBox(height: 4),

          _buildMenuItem(
            iconText: '',
            label: ref.tr("FAVORITE"),
            filterKey: 'favorite',
            ref: ref,
            active: activeFilter == 'favorite',
          ),

          const Expanded(child: SizedBox()),

          GestureDetector(
            onTap: () => context.push('/sync'),
            child: Container(
              width: 105.66,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: const Row(children: [
                Icon(Icons.sync_alt, size: 14, color: Color(0xFF4F6BFF)),
                SizedBox(width: 6),
                Text('设备同步',
                    style: TextStyle(color: Color(0xFF4F6BFF), fontSize: 13)),
              ]),
            ),
          ),
          const SizedBox(height: 4),

          // 设置按钮
          const Divider(height: 1),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              // TODO: 导航到设置页面
              context.push('/settings');
              debugPrint('打开设置页面');
            },
            child: Container(
              width: 105.66,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: ShapeDecoration(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 15.99,
                    child: Icon(
                      Icons.settings,
                      size: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ref.tr("SETTINGS"),
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.50,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
        width: 130,
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

  List<String> _filePaths(String? value) {
    if (value == null || value.isEmpty) return const [];
    try {
      return List<String>.from(jsonDecode(value) as List);
    } catch (_) {
      return value.split(',').where((path) => path.isNotEmpty).toList();
    }
  }

  List<String> _filePathsForEntry(ClipboardEntry entry) =>
      entry.filePath?.isNotEmpty == true
          ? [entry.filePath!]
          : _filePaths(entry.textContent);

  String _formatTime(int ms) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - ms;
    final minute = (diff / (1000 * 60)).floor();
    if (minute < 1) return ref.tr("TIME_JUST_NOW");
    if (minute < 60) return "$minute ${ref.tr("TIME_MINUTE_AGO")}";
    final hour = minute ~/ 60;
    if (hour < 24) return "$hour ${ref.tr("TIME_HOUR_AGO")}";
    final day = hour ~/ 24;
    return "$day ${ref.tr("TIME_DAY_AGO")}";
  }
}

/// 封装同步获取图片完整路径（依赖上面provider加载完成后使用）
String getImageCachePath(Directory cacheDir, String hash) {
  return "${cacheDir.path}/$hash.png";
}
