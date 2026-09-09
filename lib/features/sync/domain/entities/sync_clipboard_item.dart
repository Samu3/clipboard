class SyncClipboardItem {
  const SyncClipboardItem({
    required this.id,
    required this.type,
    required this.title,
    required this.sizeBytes,
    required this.createdAt,
    this.textContent,
    this.sourceDevice,
    this.fileName,
    this.filePath,
    this.dataBase64,
  });

  final String id;
  final String type;
  final String title;
  final String? textContent;
  final int sizeBytes;
  final int createdAt;
  final String? sourceDevice;
  final String? fileName;
  final String? filePath;
  final String? dataBase64;

  bool get canTransfer => type == 'text' ? textContent != null : true;

  factory SyncClipboardItem.fromJson(Map<String, dynamic> json) =>
      SyncClipboardItem(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String? ?? json['type'] as String,
        textContent: json['textContent'] as String?,
        sizeBytes: (json['sizeBytes'] as num? ?? 0).toInt(),
        createdAt: (json['createdAt'] as num).toInt(),
        sourceDevice: json['sourceDevice'] as String?,
        fileName: json['fileName'] as String?,
        dataBase64: json['dataBase64'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'textContent': textContent,
        'sizeBytes': sizeBytes,
        'createdAt': createdAt,
        'sourceDevice': sourceDevice,
        'fileName': fileName,
        if (dataBase64 != null) 'dataBase64': dataBase64,
      };

  SyncClipboardItem copyWith({String? dataBase64}) => SyncClipboardItem(
        id: id,
        type: type,
        title: title,
        textContent: textContent,
        sizeBytes: sizeBytes,
        createdAt: createdAt,
        sourceDevice: sourceDevice,
        fileName: fileName,
        filePath: filePath,
        dataBase64: dataBase64 ?? this.dataBase64,
      );
}
