import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../exceptions/odoo_exceptions.dart';
import '../models/controller_response.dart';
import '../models/odoo_response.dart';
import '../models/server_info.dart';
import '../network/dio_config.dart';
import '../network/interceptors/session_interceptor.dart';
import '../orm/odoo_orm.dart';
import 'odoo_client_options.dart';
import 'odoo_session.dart';

/// The main entry point for interacting with an Odoo server.
///
/// Combines authentication, session management, ORM methods, report
/// generation, binary field handling, and web controller access.
///
/// ```dart
/// final client = OdooClient(OdooClientOptions(
///   baseUrl: 'https://mycompany.odoo.com',
///   database: 'mydb',
/// ));
///
/// await client.authenticate('admin', 'admin');
/// final partners = await client.searchRead('res.partner', []);
/// print(client.session?.userType); // OdooUserType.internal
/// ```
class OdooClient with OdooOrm {
  final OdooClientOptions _options;

  late final Dio _dio;
  OdooSession? _session;
  final StreamController<OdooSession?> _sessionController =
      StreamController<OdooSession?>.broadcast();

  Map<String, dynamic> _globalContext = {};

  /// Creates a new [OdooClient] with the given [options].
  OdooClient(this._options) {
    _globalContext = Map.from(_options.defaultContext);

    final sessionInterceptor = SessionInterceptor(
      onSessionExpired: _handleSessionExpired,
    );

    _dio = DioConfig.createDio(
      options: _options,
      sessionInterceptor: sessionInterceptor,
    );
  }

  /// Creates an [OdooClient] with a pre-configured [Dio] instance.
  ///
  /// Useful for testing or advanced customization.
  OdooClient.withDio(this._options, this._dio) {
    _globalContext = Map.from(_options.defaultContext);
  }

  // -- Dio access (for OdooOrm mixin) --

  @override
  Dio get dio => _dio;

  // -- Session --

  /// The current session, or `null` if not authenticated.
  OdooSession? get session => _session;

  /// A stream of session changes (emits on login, logout, expiry).
  Stream<OdooSession?> get sessionStream => _sessionController.stream;

  /// Whether the client currently has an active session.
  bool get isAuthenticated => _session != null;

  // -- Context --

  @override
  Map<String, dynamic> buildContext([
    Map<String, dynamic>? contextOverrides,
  ]) {
    final base = <String, dynamic>{};
    if (_session != null) {
      base.addAll(_session!.userContext);
    }
    base.addAll(_globalContext);
    if (contextOverrides != null) {
      base.addAll(contextOverrides);
    }
    return base;
  }

  /// Updates the global context with [values].
  void updateContext(Map<String, dynamic> values) {
    _globalContext.addAll(values);
  }

  /// Sets the language for all subsequent requests.
  void setLanguage(String lang) {
    _globalContext['lang'] = lang;
  }

  /// Sets the timezone for all subsequent requests.
  ///
  /// This is the **core timezone fix**. Odoo stores/returns all datetime
  /// fields in UTC. The `tz` context value tells Odoo how to display
  /// them in views/reports. When connecting via JSON-RPC, the timezone
  /// from `user_context` is automatically applied. If you need to
  /// override it (e.g. the device timezone differs from the user's Odoo
  /// setting), call this method:
  ///
  /// ```dart
  /// client.setTimezone('America/New_York');
  /// ```
  void setTimezone(String tz) {
    _globalContext['tz'] = tz;
  }

  // -- Authentication --

  /// Authenticates with the Odoo server using [username] and [password].
  ///
  /// Returns the [OdooSession] on success. The session includes user type
  /// info (`session.userType`, `session.isInternalUser`, etc.).
  ///
  /// If [autoDetectTimezone] is `true` (default), the user's timezone
  /// from Odoo is automatically applied to the global context, fixing
  /// the common timezone mismatch issue.
  ///
  /// Throws [OdooAccessDeniedException] on invalid credentials.
  Future<OdooSession> authenticate(
    String username,
    String password, {
    bool autoDetectTimezone = true,
  }) async {
    final response = await _dio.post(
      '/web/session/authenticate',
      data: JsonRpcRequest.build(params: {
        'db': _options.database,
        'login': username,
        'password': password,
      }),
    );

    final data = response.data as Map<String, dynamic>;
    final result = JsonRpcResponse.parse(data);

    if (result.isError) {
      throw OdooException.fromRpcError(result.error!);
    }

    final resultData = result.result as Map<String, dynamic>;

    // Odoo returns uid=false on failed auth (no RPC error)
    if (resultData['uid'] == false || resultData['uid'] == null) {
      throw const OdooAccessDeniedException(
        'Invalid username or password',
        userMessage: 'Invalid username or password.',
      );
    }

    _session = OdooSession.fromJson(resultData);

    // Auto-apply timezone from Odoo user settings
    if (autoDetectTimezone && _session!.timezone != null) {
      _globalContext['tz'] = _session!.timezone;
    }

    _notifySessionChanged();
    return _session!;
  }

  /// Ends the current session on the server and clears local state.
  Future<void> logout() async {
    if (_session == null) return;

    try {
      await _dio.post(
        '/web/session/destroy',
        data: JsonRpcRequest.build(params: {}),
      );
    } catch (_) {
      // Ignore errors during logout — session may already be expired
    }

    _session = null;
    _globalContext.remove('tz');
    _notifySessionChanged();
  }

  /// Sets an API key for authentication (Odoo 14+).
  ///
  /// This bypasses session-based auth and uses the API key header instead.
  void setApiKey(String apiKey) {
    _dio.options.headers['Authorization'] = 'Bearer $apiKey';
  }

  // -- Session Management --

  /// Checks whether the current session is still valid on the server.
  ///
  /// Returns `true` if the session is active, `false` if expired or invalid.
  /// Does NOT throw — returns `false` on any error.
  ///
  /// If the session is valid, the local session data is refreshed.
  /// If invalid, the local session is cleared and [sessionStream] emits `null`.
  Future<bool> checkSession() async {
    if (_session == null) return false;

    try {
      final response = await _dio.post(
        '/web/session/get_session_info',
        data: JsonRpcRequest.build(params: {}),
      );

      final data = response.data as Map<String, dynamic>;
      final result = JsonRpcResponse.parse(data);

      if (result.isError) {
        _handleSessionExpired();
        return false;
      }

      final resultData = result.result;
      if (resultData == null || resultData is! Map<String, dynamic>) {
        _handleSessionExpired();
        return false;
      }

      final uid = resultData['uid'];
      if (uid == null || uid == false) {
        _handleSessionExpired();
        return false;
      }

      // Refresh local session with latest server data
      _session = OdooSession.fromJson(resultData);
      _notifySessionChanged();
      return true;
    } on OdooSessionExpiredException {
      _handleSessionExpired();
      return false;
    } catch (_) {
      // Network errors etc. — can't confirm, but don't clear session
      return false;
    }
  }

  /// Refreshes the current session by re-fetching session info from the server.
  ///
  /// Returns the updated [OdooSession].
  /// Throws [OdooSessionExpiredException] if the session is no longer valid.
  Future<OdooSession> refreshSession() async {
    if (_session == null) {
      throw const OdooSessionExpiredException(
        'No active session',
        userMessage: 'You are not logged in. Please log in first.',
      );
    }

    final response = await _dio.post(
      '/web/session/get_session_info',
      data: JsonRpcRequest.build(params: {}),
    );

    final data = response.data as Map<String, dynamic>;
    final result =
        JsonRpcResponse.parse(data).extractResult() as Map<String, dynamic>;

    final uid = result['uid'];
    if (uid == null || uid == false) {
      _handleSessionExpired();
      throw const OdooSessionExpiredException(
        'Session expired',
        userMessage: 'Your session has expired. Please log in again.',
      );
    }

    _session = OdooSession.fromJson(result);
    _notifySessionChanged();
    return _session!;
  }

  /// Changes the user's password on the server.
  ///
  /// [oldPassword] — Current password.
  /// [newPassword] — New password.
  /// Throws [OdooException] on failure.
  Future<void> changePassword(String oldPassword, String newPassword) async {
    final response = await _dio.post(
      '/web/session/change_password',
      data: JsonRpcRequest.build(params: {
        'fields': [
          {'name': 'old_pwd', 'value': oldPassword},
          {'name': 'new_password', 'value': newPassword},
          {'name': 'confirm_pwd', 'value': newPassword},
        ],
      }),
    );

    final data = response.data as Map<String, dynamic>;
    final result = JsonRpcResponse.parse(data);
    if (result.isError) {
      throw OdooException.fromRpcError(result.error!);
    }
  }

  /// Switches to a different company (multi-company environments).
  ///
  /// [companyId] must be one of the companies in [session.allowedCompanies].
  /// After switching, the session is refreshed to reflect the new company.
  Future<OdooSession> switchCompany(int companyId) async {
    _globalContext['allowed_company_ids'] = [companyId];
    return refreshSession();
  }

  // -- Server info --

  /// Fetches server version information.
  Future<ServerInfo> getServerInfo() async {
    final response = await _dio.post(
      '/web/webclient/version_info',
      data: JsonRpcRequest.build(params: {}),
    );

    final data = response.data as Map<String, dynamic>;
    final result =
        JsonRpcResponse.parse(data).extractResult() as Map<String, dynamic>;
    return ServerInfo.fromJson(result);
  }

  /// Fetches the current session information from the server.
  Future<OdooSession> getSessionInfo() async {
    final response = await _dio.post(
      '/web/session/get_session_info',
      data: JsonRpcRequest.build(params: {}),
    );

    final data = response.data as Map<String, dynamic>;
    final result =
        JsonRpcResponse.parse(data).extractResult() as Map<String, dynamic>;
    _session = OdooSession.fromJson(result);
    _notifySessionChanged();
    return _session!;
  }

  // -- Reports --

  /// Downloads a report as bytes.
  ///
  /// [reportName] — The report's XML ID (e.g. `'account.report_invoice'`).
  /// [ids] — Record IDs to include in the report.
  /// [format] — Output format: `'pdf'` (default), `'html'`, etc.
  Future<Uint8List> getReport(
    String reportName,
    List<int> ids, {
    String format = 'pdf',
  }) async {
    final idsStr = ids.join(',');
    final response = await _dio.get(
      '/report/$format/$reportName/$idsStr',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data as List<int>);
  }

  // -- Binary fields --

  /// Uploads binary data to a record's field.
  Future<bool> uploadBinary(
    String model,
    int id,
    String field,
    Uint8List bytes, {
    String? filename,
  }) async {
    final base64Data = base64Encode(bytes);
    final values = <String, dynamic>{field: base64Data};
    if (filename != null) {
      values['${field}_filename'] = filename;
    }
    return write(model, [id], values);
  }

  /// Downloads binary data from a record's field.
  Future<Uint8List?> downloadBinary(
    String model,
    int id,
    String field,
  ) async {
    final records = await read(model, [id], fields: [field]);
    if (records.isEmpty) return null;

    final value = records.first[field];
    if (value == null || value == false) return null;

    return base64Decode(value as String);
  }

  // -- Web controllers --

  /// Calls a custom web controller endpoint and returns a structured response.
  ///
  /// Supports both JSON-RPC wrapped endpoints and plain REST/JSON endpoints.
  ///
  /// [route] — The endpoint path (e.g. `'/api/v1/partners'`).
  /// [params] — Request parameters (body for POST, query for GET).
  /// [method] — HTTP method: `'GET'`, `'POST'` (default), `'PUT'`, `'DELETE'`.
  /// [headers] — Additional request headers.
  /// [isJsonRpc] — Set to `true` to wrap params in a JSON-RPC envelope.
  ///   Defaults to `true` for POST requests, `false` for GET.
  ///
  /// Returns an [OdooControllerResponse] with status code, headers, and data.
  ///
  /// ```dart
  /// // JSON-RPC controller
  /// final resp = await client.callController('/my/rpc/endpoint',
  ///     params: {'name': 'test'});
  /// print(resp.data);
  ///
  /// // REST-style GET
  /// final resp = await client.callController('/api/partners',
  ///     method: 'GET', params: {'limit': '10'}, isJsonRpc: false);
  /// print(resp.dataAsList);
  /// ```
  Future<OdooControllerResponse> callController(
    String route, {
    Map<String, dynamic>? params,
    String method = 'POST',
    Map<String, String>? headers,
    bool? isJsonRpc,
  }) async {
    final httpMethod = method.toUpperCase();
    final useJsonRpc = isJsonRpc ?? (httpMethod == 'POST');

    final options = headers != null ? Options(headers: headers) : null;
    final Response response;

    switch (httpMethod) {
      case 'GET':
        response = await _dio.get(route,
            queryParameters: params, options: options);
        break;
      case 'PUT':
        response = await _dio.put(route, data: params, options: options);
        break;
      case 'DELETE':
        response = await _dio.delete(route,
            queryParameters: params, options: options);
        break;
      case 'PATCH':
        response = await _dio.patch(route, data: params, options: options);
        break;
      default: // POST
        final data = useJsonRpc && params != null
            ? JsonRpcRequest.build(params: params)
            : params;
        response = await _dio.post(route, data: data, options: options);
    }

    // Extract data — unwrap JSON-RPC if present
    dynamic extractedData = response.data;
    if (extractedData is Map<String, dynamic> &&
        extractedData.containsKey('jsonrpc')) {
      extractedData = JsonRpcResponse.parse(extractedData).extractResult();
    }

    return OdooControllerResponse(
      statusCode: response.statusCode ?? 0,
      isSuccess: (response.statusCode ?? 0) >= 200 &&
          (response.statusCode ?? 0) < 300,
      data: extractedData,
      headers: response.headers.map,
      requestPath: route,
      method: httpMethod,
    );
  }

  // -- Cleanup --

  /// Closes the client and releases resources.
  void close() {
    _dio.close();
    _sessionController.close();
  }

  // -- Private --

  void _handleSessionExpired() {
    _session = null;
    _notifySessionChanged();
  }

  void _notifySessionChanged() {
    if (!_sessionController.isClosed) {
      _sessionController.add(_session);
    }
    _options.onSessionChanged?.call(_session);
  }
}
