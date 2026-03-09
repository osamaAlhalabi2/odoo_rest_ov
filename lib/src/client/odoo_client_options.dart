import 'package:dio/dio.dart';

import '../client/odoo_session.dart';

/// Configuration for [OdooClient].
class OdooClientOptions {
  /// The Odoo server base URL (e.g. `https://mycompany.odoo.com`).
  final String baseUrl;

  /// The database name to connect to.
  final String database;

  /// Connection timeout. Defaults to 30 seconds.
  final Duration connectTimeout;

  /// Receive timeout. Defaults to 30 seconds.
  final Duration receiveTimeout;

  /// Send timeout. Defaults to 30 seconds.
  final Duration sendTimeout;

  /// Optional custom cookie jar for session persistence.
  ///
  /// On **mobile/desktop**: pass a `CookieJar` (or `PersistCookieJar` for
  /// disk persistence). If not provided, a default in-memory jar is created.
  ///
  /// On **web**: ignored — the browser manages cookies automatically.
  ///
  /// Type is `dynamic` to avoid importing `dart:io`-dependent packages
  /// on web platforms.
  final dynamic cookieJar;

  /// Additional Dio interceptors to include.
  final List<Interceptor> interceptors;

  /// Whether to enable request/response logging.
  final bool enableLogging;

  /// Default user context values (e.g. `{'lang': 'en_US', 'tz': 'UTC'}`).
  final Map<String, dynamic> defaultContext;

  /// Callback invoked whenever the session changes (login, logout, expiry).
  final void Function(OdooSession?)? onSessionChanged;

  const OdooClientOptions({
    required this.baseUrl,
    required this.database,
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.sendTimeout = const Duration(seconds: 30),
    this.cookieJar,
    this.interceptors = const [],
    this.enableLogging = false,
    this.defaultContext = const {},
    this.onSessionChanged,
  });

  /// The normalized base URL (without trailing slash).
  String get normalizedBaseUrl {
    var url = baseUrl;
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }
}
