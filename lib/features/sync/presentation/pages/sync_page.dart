import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:clipboard/features/macos/index/providers/clipboard_providers.dart';

import '../../../../core/storage/shared_preferences_provider.dart';
import '../../domain/entities/sync_clipboard_item.dart';
import '../../domain/entities/sync_peer.dart';
import '../providers/sync_page_controller.dart';
import '../providers/sync_providers.dart';

class SyncPage extends ConsumerStatefulWidget {
  const SyncPage({super.key});

  @override
  ConsumerState<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends ConsumerState<SyncPage> {
  final hostController = TextEditingController();
  final codeController = TextEditingController();
  bool restoreScheduled = false;

  @override
  void dispose() {
    hostController.dispose();
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clipboard = ref.watch(clipboardRepositoryProvider);
    final preferences = ref.watch(sharedPreferencesProvider);
    if (!restoreScheduled && clipboard.hasValue && preferences.hasValue) {
      restoreScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(syncPageControllerProvider.notifier)
              .restoreSavedConnection();
        }
      });
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '返回',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('局域网同步'),
      ),
      body: Platform.isMacOS || Platform.isWindows
          ? DefaultTabController(
              length: 2,
              child: Column(children: [
                const TabBar(tabs: [
                  Tab(text: '本机服务中心'),
                  Tab(text: '连接其他电脑'),
                ]),
                Expanded(
                  child: TabBarView(children: [
                    const _HubPanel(),
                    _ClientPanel(
                      hostController: hostController,
                      codeController: codeController,
                    ),
                  ]),
                ),
              ]),
            )
          : _ClientPanel(
              hostController: hostController,
              codeController: codeController,
            ),
    );
  }
}

class _HubPanel extends ConsumerStatefulWidget {
  const _HubPanel();

  @override
  ConsumerState<_HubPanel> createState() => _HubPanelState();
}

class _HubPanelState extends ConsumerState<_HubPanel> {
  bool sending = false;
  String? transferMessage;

  Future<void> chooseForIPhone(bool media) async {
    final picked = await FilePicker.platform.pickFiles(
        allowMultiple: true, type: media ? FileType.media : FileType.any);
    if (picked == null || picked.files.isEmpty) return;
    setState(() => sending = true);
    try {
      final repository = ref.read(syncRepositoryProvider);
      var count = 0;
      for (final file in picked.files) {
        if (file.path == null) continue;
        final item = await repository.importAsset(
          name: file.name,
          bytes: await File(file.path!).readAsBytes(),
          type: media ? _mediaType(file.name) : 'file',
        );
        await repository.queueForPairedDevices(item);
        count++;
      }
      if (mounted) {
        setState(() => transferMessage = '已准备 $count 个项目，iPhone 刷新后自动接收');
      }
    } catch (error) {
      if (mounted) setState(() => transferMessage = error.toString());
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  String _mediaType(String name) {
    const videoExtensions = {'mp4', 'mov', 'm4v', 'avi', 'mkv', 'webm', '3gp'};
    return videoExtensions.contains(name.split('.').last.toLowerCase())
        ? 'video'
        : 'image';
  }

  @override
  Widget build(BuildContext context) {
    final hub = ref.watch(syncHubProvider);
    return hub.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('服务启动失败：$error')),
      data: (state) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('在 iPhone 上输入以下信息完成配对', textAlign: TextAlign.center),
          const SizedBox(height: 20),
          _InfoCard(label: '配对码', value: state.pairCode, emphasized: true),
          const SizedBox(height: 12),
          _InfoCard(label: 'IP 地址', value: state.addresses.join('  /  ')),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: sending || state.connectedPeers.isEmpty
                    ? null
                    : () => chooseForIPhone(true),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('发送照片/视频到 iPhone'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: sending || state.connectedPeers.isEmpty
                    ? null
                    : () => chooseForIPhone(false),
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('发送文件到 iPhone'),
              ),
            ),
          ]),
          if (transferMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(transferMessage!),
            ),
          const SizedBox(height: 24),
          Text('已配对设备 (${state.connectedPeers.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (state.connectedPeers.isEmpty)
            const Text('等待 iPhone 配对…')
          else
            ...state.connectedPeers.map((peer) => _ConnectedPeerHistory(
                  peer: peer,
                  items: state.peerHistories[peer.id] ?? const [],
                )),
          const SizedBox(height: 20),
          const Text(
              '可浏览 iPhone 发布的历史。照片和文件请在 iPhone 点击“发送照片”或“发送文件”，传入后会保存在 Mac 主界面。',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ConnectedPeerHistory extends ConsumerStatefulWidget {
  const _ConnectedPeerHistory({required this.peer, required this.items});

  final SyncPeer peer;
  final List<SyncClipboardItem> items;

  @override
  ConsumerState<_ConnectedPeerHistory> createState() =>
      _ConnectedPeerHistoryState();
}

class _ConnectedPeerHistoryState extends ConsumerState<_ConnectedPeerHistory> {
  final selected = <String>{};
  bool syncing = false;
  String? message;

  Future<void> syncSelected() async {
    if (syncing || selected.isEmpty) return;
    setState(() {
      syncing = true;
      message = null;
    });
    try {
      final count = await ref
          .read(syncRepositoryProvider)
          .pullFromRemote(widget.peer, widget.items, selected);
      if (!mounted) return;
      setState(() {
        selected.clear();
        message = '已同步 $count 条文本到本机';
      });
    } catch (error) {
      if (mounted) setState(() => message = error.toString());
    } finally {
      if (mounted) setState(() => syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(top: 10),
        child: ExpansionTile(
          leading: Icon(widget.peer.platform == 'ios'
              ? Icons.phone_iphone
              : Icons.computer),
          title: Text(widget.peer.name),
          subtitle: Text('${widget.peer.host} · ${widget.peer.platform}'),
          children: [
            if (widget.items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('等待对方发布剪贴板历史…'),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.items.length,
                  itemBuilder: (_, index) {
                    final item = widget.items[index];
                    return CheckboxListTile(
                      value: selected.contains(item.id),
                      onChanged: item.type == 'text'
                          ? (_) => setState(() {
                                selected.contains(item.id)
                                    ? selected.remove(item.id)
                                    : selected.add(item.id);
                              })
                          : null,
                      title: Text(item.title,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(item.type == 'text'
                          ? '文本 · 来自 ${widget.peer.name}'
                          : '${item.type} · 请由对方主动发送'),
                    );
                  },
                ),
              ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(message!),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: selected.isEmpty || syncing ? null : syncSelected,
                  child: Text(syncing ? '同步中…' : '同步到本机 (${selected.length})'),
                ),
              ),
            ),
          ],
        ),
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(
      {required this.label, required this.value, this.emphasized = false});
  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 6),
            SelectableText(value.isEmpty ? '正在获取…' : value,
                style: TextStyle(
                    fontSize: emphasized ? 32 : 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: emphasized ? 8 : 0)),
          ]),
        ),
      );
}

class _ClientPanel extends ConsumerWidget {
  const _ClientPanel(
      {required this.hostController, required this.codeController});
  final TextEditingController hostController;
  final TextEditingController codeController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncPageControllerProvider);
    final controller = ref.read(syncPageControllerProvider.notifier);
    if (state.peer != null)
      return _HistoryBrowser(state: state, controller: controller);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        FilledButton.icon(
          onPressed: state.busy ? null : controller.discover,
          icon: const Icon(Icons.radar),
          label: const Text('扫描局域网中的 PasteLink'),
        ),
        if (state.discovered.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...state.discovered.map((peer) => Card(
                child: ListTile(
                  leading: const Icon(Icons.computer),
                  title: Text(peer.name),
                  subtitle: Text('${peer.host}:${peer.port}'),
                  onTap: () => hostController.text = peer.host,
                ),
              )),
        ],
        const SizedBox(height: 20),
        TextField(
          controller: hostController,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
              labelText: 'Mac IP 地址', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
              labelText: '6 位配对码', border: OutlineInputBorder()),
        ),
        FilledButton(
          onPressed: state.busy
              ? null
              : () =>
                  controller.connect(hostController.text, codeController.text),
          child: Text(state.busy ? '连接中…' : '连接 Mac'),
        ),
        if (state.message != null)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(state.message!)),
      ],
    );
  }
}

class _HistoryBrowser extends StatelessWidget {
  const _HistoryBrowser({required this.state, required this.controller});
  final SyncPageState state;
  final SyncPageController controller;

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Column(children: [
          ListTile(
            leading: const Icon(Icons.link, color: Colors.green),
            title: Text('已连接 ${state.peer!.name}'),
            subtitle: Text('${state.peer!.host}:${state.peer!.port}'),
            trailing: IconButton(
                onPressed: state.busy ? null : controller.refresh,
                icon: const Icon(Icons.refresh)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.busy
                      ? null
                      : () => controller.chooseAndSend(media: true),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('发送照片/视频'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.busy
                      ? null
                      : () => controller.chooseAndSend(media: false),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('发送文件'),
                ),
              ),
            ]),
          ),
          const TabBar(tabs: [Tab(text: '本机历史'), Tab(text: 'Mac 历史')]),
          if (state.message != null)
            Padding(
                padding: const EdgeInsets.all(8), child: Text(state.message!)),
          Expanded(
            child: TabBarView(children: [
              _SelectableHistory(
                items: state.localItems,
                selected: state.selectedLocal,
                onToggle: controller.toggleLocal,
                actionLabel: '同步到 Mac',
                onAction: state.selectedLocal.isEmpty || state.busy
                    ? null
                    : controller.push,
              ),
              _SelectableHistory(
                items: state.remoteItems,
                selected: state.selectedRemote,
                onToggle: controller.toggleRemote,
                actionLabel: '同步到本机',
                onAction: state.selectedRemote.isEmpty || state.busy
                    ? null
                    : controller.pull,
              ),
            ]),
          ),
        ]),
      );
}

class _SelectableHistory extends StatelessWidget {
  const _SelectableHistory({
    required this.items,
    required this.selected,
    required this.onToggle,
    required this.actionLabel,
    required this.onAction,
  });
  final List<SyncClipboardItem> items;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Column(children: [
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('暂无剪贴板历史'))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return CheckboxListTile(
                      value: selected.contains(item.id),
                      onChanged:
                          item.canTransfer ? (_) => onToggle(item.id) : null,
                      secondary: Icon(_icon(item.type)),
                      title: Text(item.title,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${_typeLabel(item.type)} · 可同步'),
                    );
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: onAction,
                  child: Text('$actionLabel (${selected.length})')),
            ),
          ),
        ),
      ]);

  static IconData _icon(String type) => switch (type) {
        'image' => Icons.image_outlined,
        'video' => Icons.video_file_outlined,
        'file' => Icons.insert_drive_file_outlined,
        _ => Icons.text_snippet_outlined,
      };

  static String _typeLabel(String type) => switch (type) {
        'image' => '图片',
        'video' => '视频',
        'file' => '文件',
        _ => '文本',
      };
}
