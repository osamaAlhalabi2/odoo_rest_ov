import 'package:dio/dio.dart';

import '../../exceptions/odoo_exceptions.dart';

/// Callback type for session expiry events.
typedef OnSessionExpired = void Function();

/// Dio interceptor that detects session expiry in Odoo JSON-RPC responses.
class SessionInterceptor extends Interceptor {
  /// Callback invoked when a session expiry is detected.
  final OnSessionExpired? onSessionExpired;

  SessionInterceptor({this.onSessionExpired});

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final error = data['error'] as Map<String, dynamic>?;
      if (error != null) {
        final errorData = error['data'] as Map<String, dynamic>?;
        final name = errorData?['name'] as String? ?? '';
        final message = error['message'] as String? ?? '';

        if (name == 'odoo.http.SessionExpiredException' ||
            message.contains('Session expired')) {
          onSessionExpired?.call();
          handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              error: OdooSessionExpiredException(
                message.isNotEmpty ? message : 'Session expired',
              ),
              type: DioExceptionType.badResponse,
            ),
          );
          return;
        }
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Wrap connectivity errors as OdooNetworkException
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          error: OdooNetworkException(
            err.message ?? 'Network error: ${err.type}',
          ),
          type: err.type,
        ),
      );
      return;
    }
    handler.next(err);
  }
}
