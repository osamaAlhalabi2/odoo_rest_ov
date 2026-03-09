/// Server version information returned by `/web/webclient/version_info`.
class ServerInfo {
  /// Full version string, e.g. "17.0".
  final String serverVersion;

  /// Version serie, e.g. "17.0".
  final String serverSerie;

  /// JSON-RPC protocol version.
  final int protocolVersion;

  /// Raw version info array, e.g. [17, 0, 0, 'final', 0].
  final List<dynamic> serverVersionInfo;

  const ServerInfo({
    required this.serverVersion,
    required this.serverSerie,
    required this.protocolVersion,
    required this.serverVersionInfo,
  });

  factory ServerInfo.fromJson(Map<String, dynamic> json) {
    return ServerInfo(
      serverVersion: json['server_version'] as String? ?? '',
      serverSerie: json['server_serie'] as String? ?? '',
      protocolVersion: json['protocol_version'] as int? ?? 1,
      serverVersionInfo: json['server_version_info'] as List<dynamic>? ?? [],
    );
  }

  @override
  String toString() => 'ServerInfo(version: $serverVersion, serie: $serverSerie)';
}
