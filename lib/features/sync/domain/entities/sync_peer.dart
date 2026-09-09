class SyncPeer {
  const SyncPeer({
    required this.id,
    required this.name,
    required this.platform,
    required this.host,
    required this.port,
    this.token,
  });

  final String id;
  final String name;
  final String platform;
  final String host;
  final int port;
  final String? token;

  bool get isPaired => token?.isNotEmpty == true;

  SyncPeer copyWith({String? token}) => SyncPeer(
        id: id,
        name: name,
        platform: platform,
        host: host,
        port: port,
        token: token ?? this.token,
      );

  factory SyncPeer.fromJson(Map<String, dynamic> json, String host) => SyncPeer(
        id: json['id'] as String,
        name: json['name'] as String,
        platform: json['platform'] as String,
        host: host,
        port: (json['port'] as num).toInt(),
        token: json['token'] as String?,
      );

  factory SyncPeer.fromStoredJson(Map<String, dynamic> json) => SyncPeer(
        id: json['id'] as String,
        name: json['name'] as String,
        platform: json['platform'] as String,
        host: json['host'] as String,
        port: (json['port'] as num).toInt(),
        token: json['token'] as String?,
      );

  Map<String, dynamic> toJson({bool includeToken = true}) => {
        'id': id,
        'name': name,
        'platform': platform,
        'host': host,
        'port': port,
        if (includeToken) 'token': token,
      };
}
