class ClipboardEntry {
  final String id;
  final int seq;
  final String type; // text / image / file
  final String? title;
  final String? preview;
  final String? textContent;
  final String? hash;
  final int sizeBytes;
  final int favorite; // 0 /1
  final String? sourceDevice;
  final int createdAt;
  final int updatedAt;
  final int deleted; // 0/1 软删除
  final int? deletedAt;

  const ClipboardEntry({
    required this.id,
    required this.seq,
    required this.type,
    this.title,
    this.preview,
    this.textContent,
    this.hash,
    required this.sizeBytes,
    required this.favorite,
    this.sourceDevice,
    required this.createdAt,
    required this.updatedAt,
    required this.deleted,
    this.deletedAt,
  });

  // copyWith 用于更新字段（修改、软删除非常关键）
  ClipboardEntry copyWith({
    String? id,
    int? seq,
    String? type,
    String? title,
    String? preview,
    String? textContent,
    String? hash,
    int? sizeBytes,
    int? favorite,
    String? sourceDevice,
    int? createdAt,
    int? updatedAt,
    int? deleted,
    int? deletedAt,
  }) {
    return ClipboardEntry(
      id: id ?? this.id,
      seq: seq ?? this.seq,
      type: type ?? this.type,
      title: title ?? this.title,
      preview: preview ?? this.preview,
      textContent: textContent ?? this.textContent,
      hash: hash ?? this.hash,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      favorite: favorite ?? this.favorite,
      sourceDevice: sourceDevice ?? this.sourceDevice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
