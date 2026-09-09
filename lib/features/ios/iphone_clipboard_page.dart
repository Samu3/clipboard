import 'save_image_button.dart';
import 'dart:convert';
import 'clipboard_text_editor.dart';
import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../macos/index/domain/entities/clipboard_entry.dart';
import '../macos/index/domain/repositories/clipboard_repository.dart';
import '../macos/index/providers/clipboard_providers.dart';
import 'iphone_clipboard_service.dart';

class IphoneClipboardPage extends ConsumerStatefulWidget {
  const IphoneClipboardPage({super.key});
  @override
  ConsumerState<IphoneClipboardPage> createState() =>
      _IphoneClipboardPageState();
}

class _IphoneClipboardPageState extends ConsumerState<IphoneClipboardPage>
    with WidgetsBindingObserver {
  Timer? _clipboardTimer;
  bool _capturing = false;
  Completer<void>? _captureCompletion;
  bool _editingText = false;
  final _search = TextEditingController();
  List<ClipboardEntry> _entries = [];
  String _filter = 'all';
  String? _error;
  bool _loading = true;
  bool _busy = false;
  bool _more = true;
  int _request = 0;
  static const _blue = Color(0xFF3869EA);
  static const _filters = {
    'all': '全部',
    'text': '文本',
    'image': '图片',
    'file': '文件',
    'favorite': '收藏'
  };

  @override
  void initState() {
    super.initState();
    _reload();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _startClipboardCapture();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startClipboardCapture();
    } else {
      _clipboardTimer?.cancel();
      _clipboardTimer = null;
    }
  }

  void _startClipboardCapture() {
    _clipboardTimer?.cancel();
    _captureClipboard();
    _clipboardTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _captureClipboard());
  }

  Future<void> _captureClipboard() async {
    if (!mounted ||
        _busy ||
        _capturing ||
        _editingText ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed)
      return;
    _capturing = true;
    final completion = Completer<void>();
    _captureCompletion = completion;
    try {
      final service = ref.read(iphoneClipboardServiceProvider);
      final repo = await _repo;
      if (!mounted ||
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed)
        return;
      final entry = await service.paste(repo, onlyIfChanged: true);
      if (mounted && entry != null) await _reload();
    } catch (error) {
      // Manual paste remains available for retry, without repeated error toasts.
      debugPrint('Foreground clipboard capture failed: $error');
    } finally {
      _capturing = false;
      completion.complete();
      _captureCompletion = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clipboardTimer?.cancel();
    _request++;
    _search.dispose();
    super.dispose();
  }

  Future<ClipboardRepository> get _repo =>
      ref.read(clipboardRepositoryProvider.future);
  Future<void> _reload({bool append = false}) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = await _repo;
      try {
        await ref.read(iphoneClipboardServiceProvider).syncKeyboard(repo);
      } catch (error) {
        debugPrint('Keyboard history sync failed: $error');
      }
      final items = await repo.getActiveEntries(
          filter: _filter,
          keyword: _search.text,
          offset: append ? _entries.length : 0,
          limit: 50);
      if (!mounted || request != _request) return;
      setState(() {
        _entries = append ? [..._entries, ...items] : items;
        _more = items.length == 50;
      });
    } catch (error, stack) {
      debugPrint('Clipboard history load failed: $error\n$stack');
      if (mounted && request == _request) setState(() => _error = '加载失败，请重试');
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy || _capturing) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      _message('操作失败，请检查粘贴权限或文件后重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _paste() => _run(() async {
        final service = ref.read(iphoneClipboardServiceProvider);
        final entry = await service.paste(await _repo);
        if (!mounted) return;
        if (entry == null) {
          _message('没有可保存的文本或图片；文件请通过“导入文件”添加');
        } else {
          _search.clear();
          _filter = 'all';
          await _reload();
          _message('已保存到剪贴板历史');
        }
      });

  Future<void> _showKeyboardGuide() async {
    await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('启用 ClipSync 键盘'),
              content: const Text(
                  '在系统设置 → 通用 → 键盘 → 键盘 → 添加新键盘中选择 ClipSync。\n\n在聊天输入框中长按地球图标，切换到 ClipSync，点击文本卡片即可输入。\n\n键盘展示最近 200 条本地文本；先回到 App 保存内容。'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('知道了'))
              ],
            ));
  }

  Future<void> _import() => _run(() async {
        final service = ref.read(iphoneClipboardServiceProvider);
        final picked = await FilePicker.platform.pickFiles();
        if (picked == null || !mounted) return;
        final file = picked.files.single;
        final bytes = file.bytes ??
            (file.path == null ? null : await File(file.path!).readAsBytes());
        if (bytes == null) throw StateError('文件不可读');
        await service.save(await _repo,
            type: 'file', bytes: bytes, name: file.name);
        if (!mounted) return;
        _search.clear();
        _filter = 'all';
        await _reload();
        _message('文件已保存');
      });

  Future<void> _copy(ClipboardEntry entry) => _run(() async {
        await ref.read(iphoneClipboardServiceProvider).copy(entry);
        _message('已复制，可切换到其他应用粘贴');
      });

  Future<void> _favorite(ClipboardEntry entry) => _run(() async {
        final repo = await _repo;
        await repo.updateEntry(entry.copyWith(
            favorite: entry.favorite == 1 ? 0 : 1,
            seq: await repo.getMaxSeq() + 1,
            updatedAt: DateTime.now().millisecondsSinceEpoch));
        if (mounted) await _reload();
      });

  Future<void> _delete(ClipboardEntry entry) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('删除这条记录？'),
                content: const Text('删除后将不再显示在本地历史中。'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('删除'))
                ]));
    if (confirmed != true || !mounted) return;
    await _run(() async {
      final repo = await _repo;
      await repo.softDeleteEntry(entry.id, await repo.getMaxSeq() + 1,
          DateTime.now().millisecondsSinceEpoch);
      if (mounted) await _reload();
    });
  }

  Future<void> _detail(ClipboardEntry entry) async {
    if (entry.type == 'text') {
      _editingText = true;
      try {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          isDismissible: false,
          enableDrag: false,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (_) => ClipboardTextEditor(
            text: entry.textContent ?? entry.title ?? '',
            onCopy: (text) async {
              // Finish any foreground capture before writing another history entry.
              await _captureCompletion?.future;
              if (!mounted) throw StateError('Page disposed');
              final service = ref.read(iphoneClipboardServiceProvider);
              final saved = await service.save(await _repo,
                  type: 'text', bytes: utf8.encode(text), text: text);
              await service.copy(saved);
              if (mounted) {
                await _reload();
                _message('已复制编辑后的内容');
              }
            },
          ),
        );
      } finally {
        _editingText = false;
      }
      return;
    }
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) => SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                    height: MediaQuery.of(context).size.height * .65,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(children: [
                            const Expanded(
                                child: Text('剪贴板内容',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600))),
                            IconButton(
                                tooltip: '分享',
                                onPressed: () => _run(() => ref
                                    .read(iphoneClipboardServiceProvider)
                                    .share(entry)),
                                icon: const Icon(Icons.ios_share_outlined)),
                            IconButton(
                                tooltip: '关闭',
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close))
                          ]),
                          const SizedBox(height: 16),
                          Expanded(
                              child: SingleChildScrollView(
                                  child: entry.type == 'image'
                                      ? _image(entry, large: true)
                                      : SelectableText(
                                          entry.textContent ??
                                              entry.title ??
                                              '文件',
                                          style:
                                              const TextStyle(fontSize: 16)))),
                          const SizedBox(height: 16),
                          if (entry.type == 'image') ...[
                            SaveImageButton(
                                onSave: () => ref
                                    .read(iphoneClipboardServiceProvider)
                                    .saveImageToPhotos(entry)),
                            const SizedBox(height: 8),
                          ],
                          FilledButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _copy(entry);
                              },
                              icon: const Icon(Icons.copy),
                              label: const Text('复制内容')),
                        ])))));
  }

  @override
  Widget build(BuildContext context) {
    // Keep the repository and its database open while this page is visible.
    ref.watch(clipboardRepositoryProvider);
    return Theme(
      data: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(seedColor: _blue),
          scaffoldBackgroundColor: const Color(0xFFF7F8FA)),
      child: Scaffold(
          body: SafeArea(
              child: Column(children: [
        Container(
            width: double.infinity,
            color: const Color(0xFFF0F1F4),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            child: const Text('●  前台自动收录 · 历史记录保存在此设备',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 12))),
        _pasteBanner(),
        Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
            child: Row(children: [
              const Icon(Icons.content_paste_rounded, color: _blue),
              const SizedBox(width: 10),
              Expanded(
                  child: TextField(
                      controller: _search,
                      onChanged: (_) => _reload(),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                          hintText: '搜索剪贴板…',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _search.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: '清除搜索',
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    _search.clear();
                                    _reload();
                                  }),
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
                          isDense: true,
                          border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(10))))),
              PopupMenuButton<String>(
                  tooltip: '更多操作',
                  enabled: !_busy,
                  onSelected: (action) {
                    if (action == 'sync') {
                      context.push('/sync');
                    } else if (action == 'keyboard') {
                      _showKeyboardGuide();
                    } else {
                      _import();
                    }
                  },
                  itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'sync', child: Text('设备配对与同步')),
                        const PopupMenuItem(
                            value: 'import', child: Text('导入文件')),
                        const PopupMenuItem(
                            value: 'keyboard', child: Text('启用 ClipSync 键盘'))
                      ]),
            ])),
        Container(
            color: Colors.white,
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                    children: _filters.entries
                        .map((filter) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                                label: Text(filter.value),
                                selected: _filter == filter.key,
                                showCheckmark: false,
                                onSelected: (_) {
                                  _filter = filter.key;
                                  _reload();
                                },
                                selectedColor: const Color(0xFFE9EFFF),
                                side: BorderSide.none,
                                labelStyle: TextStyle(
                                    color: _filter == filter.key
                                        ? _blue
                                        : const Color(0xFF6B7280)))))
                        .toList()))),
        Expanded(child: _body()),
      ]))),
    );
  }

  Widget _pasteBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3869EA), Color(0xFF635BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x333869EA),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.content_paste_go_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '保存当前剪贴板',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '复制文本或图片后，点击右侧即可保存',
                  style: TextStyle(color: Color(0xDFFFFFFF), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: _busy || _capturing ? null : _paste,
            style: FilledButton.styleFrom(
              foregroundColor: _blue,
              backgroundColor: Colors.white,
              disabledBackgroundColor: Colors.white.withOpacity(.55),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            ),
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    '粘贴保存',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading && _entries.isEmpty)
      return const Center(child: CircularProgressIndicator());
    if (_error != null)
      return Center(
          child: TextButton(onPressed: () => _reload(), child: Text(_error!)));
    if (_entries.isEmpty)
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.content_paste_rounded,
                    size: 48, color: Color(0xFFB8C2D5)),
                const SizedBox(height: 18),
                Text(
                    _search.text.isNotEmpty || _filter != 'all'
                        ? '没有匹配的记录'
                        : '还没有剪贴板记录',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                const Text('在其他应用复制文本或图片后，\n回到这里将自动保存，也可点击“粘贴保存”。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey)),
              ])));
    return RefreshIndicator(
        onRefresh: () => _reload(),
        child: ListView.builder(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
            itemCount: _entries.length + 1,
            itemBuilder: (context, index) {
              if (index == _entries.length)
                return _more
                    ? TextButton(
                        onPressed:
                            _loading ? null : () => _reload(append: true),
                        child: Text(_loading ? '加载中…' : '加载更多'))
                    : const SizedBox(height: 12);
              return _card(_entries[index]);
            }));
  }

  Widget _image(ClipboardEntry entry, {bool large = false}) {
    if (entry.filePath == null) return const Icon(Icons.broken_image_outlined);
    return FutureBuilder<String>(
        future: ref
            .read(iphoneClipboardServiceProvider)
            .resolvePath(entry.filePath!),
        builder: (context, snapshot) => snapshot.hasData
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(snapshot.data!),
                    height: large ? null : 150,
                    width: double.infinity,
                    fit: large ? BoxFit.contain : BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                        height: 80, child: Center(child: Text('图片不可用')))))
            : const SizedBox(
                height: 80, child: Center(child: CircularProgressIndicator())));
  }

  Widget _card(ClipboardEntry entry) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E6EB))),
      child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _detail(entry),
          child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 6),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.type == 'image')
                      Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _image(entry))
                    else
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (entry.type == 'file')
                              const Padding(
                                  padding: EdgeInsets.only(right: 10),
                                  child: Icon(Icons.insert_drive_file_outlined,
                                      color: _blue, size: 30)),
                            Expanded(
                                child: Text(
                                    entry.textContent ?? entry.title ?? '文件',
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.6,
                                        color: Color(0xFF1A1D23)))),
                            const SizedBox(width: 8)
                          ]),
                    Row(children: [
                      Expanded(
                          child: Text(
                              '${_time(entry.createdAt)} · ${entry.sourceDevice ?? 'iPhone'}${entry.type == 'file' ? ' · ${_size(entry.sizeBytes)}' : ''}',
                              style: const TextStyle(
                                  color: Color(0xFF9CA3AF), fontSize: 11))),
                      IconButton(
                          tooltip: entry.favorite == 1 ? '取消收藏' : '收藏',
                          onPressed: _busy ? null : () => _favorite(entry),
                          icon: Icon(
                              entry.favorite == 1
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: entry.favorite == 1
                                  ? Colors.amber
                                  : const Color(0xFF9CA3AF),
                              size: 21)),
                      IconButton(
                          tooltip: '复制',
                          onPressed: _busy ? null : () => _copy(entry),
                          icon: const Icon(Icons.copy_outlined,
                              size: 18, color: _blue)),
                      IconButton(
                        icon: Icon(Icons.delete_outline_sharp),
                        color: const Color(0xFF9CA3AF),
                        onPressed: () {
                          _delete(entry);
                        },
                      )
                      // PopupMenuButton<String>(
                      //     tooltip: '记录操作',
                      //     enabled: !_busy,
                      //     onSelected: (_) => _delete(entry),
                      //     itemBuilder: (_) => [
                      //           const PopupMenuItem(
                      //               value: 'delete', child: Text('删除'))
                      //         ],
                      //     icon: const Icon(Icons.more_horiz,
                      //         size: 18, color: Colors.grey)),
                    ]),
                  ]))));

  String _size(int bytes) => bytes >= 1048576
      ? '${(bytes / 1048576).toStringAsFixed(1)} MB'
      : '${(bytes / 1024).toStringAsFixed(1)} KB';
  String _time(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final elapsed = DateTime.now().difference(date);
    if (elapsed.inMinutes < 1) return '刚刚';
    if (elapsed.inHours < 1) return '${elapsed.inMinutes} 分钟前';
    if (elapsed.inDays < 1) return '${elapsed.inHours} 小时前';
    return '${date.month}/${date.day}';
  }
}
