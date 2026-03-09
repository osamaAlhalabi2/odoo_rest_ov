import 'dart:developer' as developer;

import 'package:dio/dio.dart';

/// Lightweight request/response logger using `dart:developer`.
class OdooLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    developer.log(
      '→ ${options.method} ${options.uri}',
      name: 'odoo_rest_ov',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    developer.log(
      '← ${response.statusCode} ${response.requestOptions.uri}',
      name: 'odoo_rest_ov',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log(
      '✗ ${err.type} ${err.requestOptions.uri}: ${err.message}',
      name: 'odoo_rest_ov',
      level: 1000,
    );
    handler.next(err);
  }
}
