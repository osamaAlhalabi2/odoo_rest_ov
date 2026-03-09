import 'package:dio/dio.dart';

import '../client/odoo_client_options.dart';
import 'cookie_manager_stub.dart'
    if (dart.library.io) 'cookie_manager_io.dart'
    if (dart.library.html) 'cookie_manager_web.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/session_interceptor.dart';

/// Factory for creating a configured [Dio] instance from [OdooClientOptions].
class DioConfig {
  DioConfig._();

  /// Creates a [Dio] instance configured for Odoo JSON-RPC communication.
  ///
  /// On mobile/desktop: uses `CookieManager` for session cookie persistence.
  /// On web: skips cookie manager (the browser handles cookies natively)
  /// and sets `withCredentials: true` so cookies are sent cross-origin.
  static Dio createDio({
    required OdooClientOptions options,
    required SessionInterceptor sessionInterceptor,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: options.normalizedBaseUrl,
        connectTimeout: options.connectTimeout,
        receiveTimeout: options.receiveTimeout,
        sendTimeout: options.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.json,
        extra: {'withCredentials': true},
      ),
    );

    // Cookie management (no-op on web — browser handles cookies)
    final cookieInterceptor = createCookieInterceptor(options.cookieJar);
    if (cookieInterceptor != null) {
      dio.interceptors.add(cookieInterceptor);
    }

    // Session interceptor
    dio.interceptors.add(sessionInterceptor);

    // Custom interceptors
    for (final interceptor in options.interceptors) {
      dio.interceptors.add(interceptor);
    }

    // Logging (added last so it captures final request/response)
    if (options.enableLogging) {
      dio.interceptors.add(OdooLoggingInterceptor());
    }

    return dio;
  }
}
