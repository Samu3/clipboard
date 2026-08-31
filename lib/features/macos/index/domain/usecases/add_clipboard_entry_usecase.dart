import 'package:clipboard/features/macos/index/domain/entities/clipboard_entry.dart';
import 'package:clipboard/features/macos/index/domain/repositories/clipboard_repository.dart';

class AddClipboardEntryUseCase {
  final ClipboardRepository repo;

  AddClipboardEntryUseCase(this.repo);

  Future<void> call(
      {required String id,
      required String type,
      String? title,
      String? preview,
      String? textContent,
      String? hash,
      required int sizeBytes,
      String? sourceDevice,
      String? filePath}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final maxSeq = await repo.getMaxSeq();
    final newSeq = maxSeq + 1;

    final entry = ClipboardEntry(
        id: id,
        seq: newSeq,
        type: type,
        title: title,
        preview: preview,
        textContent: textContent,
        hash: hash,
        sizeBytes: sizeBytes,
        favorite: 0,
        sourceDevice: sourceDevice,
        createdAt: now,
        updatedAt: now,
        deleted: 0,
        deletedAt: null,
        filePath: filePath);
    await repo.insertEntry(entry);
  }
}
