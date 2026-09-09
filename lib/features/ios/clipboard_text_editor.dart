import 'package:flutter/material.dart';

class ClipboardTextEditor extends StatefulWidget {
  const ClipboardTextEditor(
      {super.key, required this.text, required this.onCopy});

  final String text;
  final Future<void> Function(String text) onCopy;

  @override
  State<ClipboardTextEditor> createState() => _ClipboardTextEditorState();
}

class _ClipboardTextEditorState extends State<ClipboardTextEditor> {
  late final TextEditingController _controller;
  bool _copying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    if (_copying || _controller.text.isEmpty) return;
    setState(() {
      _copying = true;
      _error = null;
    });
    try {
      await widget.onCopy(_controller.text);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _error = '复制失败，请重试');
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final availableHeight =
        media.size.height - media.viewInsets.bottom - media.padding.top;
    return PopScope(
      canPop: !_copying,
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: SafeArea(
            top: false,
            child: SizedBox(
              height: availableHeight * .85,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        const Expanded(
                            child: Text('编辑剪贴板内容',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600))),
                        IconButton(
                            tooltip: '关闭',
                            onPressed:
                                _copying ? null : () => Navigator.pop(context),
                            icon: const Icon(Icons.close)),
                      ]),
                      const SizedBox(height: 8),
                      Expanded(
                          child: TextField(
                        controller: _controller,
                        readOnly: _copying,
                        expands: true,
                        minLines: null,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textAlignVertical: TextAlignVertical.top,
                        onChanged: (_) => setState(() => _error = null),
                        decoration: const InputDecoration(
                            hintText: '输入文本内容', border: OutlineInputBorder()),
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      )),
                      if (_error != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(_error!,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error))),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed:
                            _copying || _controller.text.isEmpty ? null : _copy,
                        icon: _copying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.copy),
                        label: Text(_copying ? '复制中…' : '复制编辑后的内容'),
                      ),
                    ]),
              ),
            )),
      ),
    );
  }
}
