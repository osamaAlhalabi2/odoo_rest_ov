import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

/// Creates a [CookieManager] interceptor for mobile/desktop platforms.
Interceptor? createCookieInterceptor(dynamic cookieJar) {
  final jar = cookieJar as CookieJar? ?? CookieJar();
  return CookieManager(jar);
}

/// Creates a default in-memory [CookieJar].
dynamic createDefaultCookieJar() => CookieJar();
