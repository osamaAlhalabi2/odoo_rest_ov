import 'package:dio/dio.dart';

/// On web, the browser manages cookies automatically.
/// No [CookieManager] interceptor is needed.
Interceptor? createCookieInterceptor(dynamic cookieJar) => null;

/// On web, cookies are handled by the browser — no jar needed.
dynamic createDefaultCookieJar() => null;
