import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SaveImageButton extends StatefulWidget {
  const SaveImageButton({super.key, required this.onSave});
  final Future<void> Function() onSave;

  @override
  State<SaveImageButton> createState() => _SaveImageButtonState();
}

class _SaveImageButtonState extends State<SaveImageButton> {
  bool _saving = false;
  bool _saved = false;
  String? _error;

  Future<void> _save() async {
    if (_saving || _saved) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave();
      if (mounted) setState(() => _saved = true);
    } on PlatformException catch (error) {
      if (mounted) setState(() => _error = error.message ?? '保存失败，请重试');
    } catch (_) {
      if (mounted) setState(() => _error = '保存失败，请确认媒体文件仍然存在');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          OutlinedButton.icon(
            onPressed: _saving || _saved ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(_saved ? Icons.check : Icons.save_alt),
            label: Text(_saved
                ? '已保存到相册'
                : _saving
                    ? '保存中…'
                    : '保存到相册'),
          ),
        ],
      );
}
