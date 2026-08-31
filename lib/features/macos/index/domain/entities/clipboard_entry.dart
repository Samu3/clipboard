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
  // ==========新增==========
  final String? filePath;

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
    this.filePath, // 新增参数
  });

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
    String? filePath,
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
      filePath: filePath ?? this.filePath,
    );
  }

  factory ClipboardEntry.fromJson(Map<String, dynamic> json) {
    return ClipboardEntry(
      id: json['id'] as String,
      seq: json['seq'] as int,
      type: json['type'] as String,
      title: json['title'] as String?,
      preview: json['preview'] as String?,
      textContent: json['textContent'] as String?,
      hash: json['hash'] as String?,
      sizeBytes: json['sizeBytes'] as int,
      favorite: json['favorite'] as int,
      sourceDevice: json['sourceDevice'] as String?,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
      deleted: json['deleted'] as int,
      deletedAt: json['deletedAt'] as int?,
      filePath: json['filePath'] as String?, // 新增
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seq': seq,
      'type': type,
      'title': title,
      'preview': preview,
      'textContent': textContent,
      'hash': hash,
      'sizeBytes': sizeBytes,
      'favorite': favorite,
      'sourceDevice': sourceDevice,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deleted': deleted,
      'deletedAt': deletedAt,
      'filePath': filePath, // 新增
    };
  }
}
