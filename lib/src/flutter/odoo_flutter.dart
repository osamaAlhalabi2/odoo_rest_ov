import 'package:cookie_jar/cookie_jar.dart';

import '../client/odoo_client.dart';
import '../client/odoo_client_options.dart';

/// Flutter-specific helpers for [OdooClient].
///
/// This file provides utilities for persistent cookie storage
/// using `path_provider`. Import via `package:odoo_rest_ov/odoo_rest_ov_flutter.dart`.
class OdooFlutter {
  OdooFlutter._();

  /// Creates a persistent cookie jar that stores cookies on disk.
  ///
  /// Requires `path_provider` to be available (Flutter only).
  /// The [directory] should be the application documents directory path.
  ///
  /// Example:
  /// ```dart
  /// import 'package:path_provider/path_provider.dart';
  ///
  /// final dir = await getApplicationDocumentsDirectory();
  /// final cookieJar = OdooFlutter.createPersistentCookieJar(dir.path);
  /// ```
  static PersistCookieJar createPersistentCookieJar(String directory) {
    return PersistCookieJar(storage: FileStorage('$directory/.cookies/'));
  }

  /// Convenience factory that creates an [OdooClient] with persistent cookies.
  ///
  /// [documentsPath] — The application documents directory path from
  /// `path_provider`.
  static OdooClient createClient({
    required String baseUrl,
    required String database,
    required String documentsPath,
    bool enableLogging = false,
    Map<String, dynamic> defaultContext = const {},
  }) {
    final cookieJar = createPersistentCookieJar(documentsPath);

    return OdooClient(OdooClientOptions(
      baseUrl: baseUrl,
      database: database,
      cookieJar: cookieJar,
      enableLogging: enableLogging,
      defaultContext: defaultContext,
    ));
  }
}
