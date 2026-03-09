import 'package:dio/dio.dart';

import '../models/odoo_record.dart';
import '../models/odoo_response.dart';
import '../network/json_rpc.dart';

/// Mixin providing typed ORM method wrappers for Odoo's `call_kw` endpoint.
///
/// Classes using this mixin must provide [dio] and [buildContext].
mixin OdooOrm {
  /// The Dio instance for making HTTP requests.
  Dio get dio;

  /// Builds the kwargs context (user context + overrides).
  Map<String, dynamic> buildContext([Map<String, dynamic>? contextOverrides]);

  /// Calls an Odoo model method via `/web/dataset/call_kw/{model}/{method}`.
  Future<dynamic> callKw({
    required String model,
    required String method,
    List<dynamic> args = const [],
    Map<String, dynamic> kwargs = const {},
  }) async {
    final contextOverrides = kwargs['context'] as Map<String, dynamic>?;
    final filteredKwargs = Map<String, dynamic>.from(kwargs)..remove('context');
    final mergedKwargs = {
      'context': buildContext(contextOverrides),
      ...filteredKwargs,
    };

    final params = JsonRpc.buildCallKwParams(
      model: model,
      method: method,
      args: args,
      kwargs: mergedKwargs,
    );

    final response = await dio.post(
      '/web/dataset/call_kw/$model/$method',
      data: JsonRpcRequest.build(params: params),
    );

    return JsonRpc.extractResult(response.data as Map<String, dynamic>);
  }

  /// Searches for records and reads their fields in a single call.
  ///
  /// [model] — The Odoo model name (e.g. `'res.partner'`).
  /// [domain] — Search domain (raw list or built via [OdooDomain]).
  /// [fields] — Fields to read. If empty, all fields are returned.
  /// [limit] — Maximum records to return.
  /// [offset] — Number of records to skip.
  /// [order] — Sort order (e.g. `'name asc, id desc'`).
  Future<List<OdooRecord>> searchRead(
    String model,
    List<dynamic> domain, {
    List<String> fields = const [],
    int? limit,
    int offset = 0,
    String? order,
  }) async {
    final kwargs = <String, dynamic>{
      'fields': fields,
      'offset': offset,
    };
    if (limit != null) kwargs['limit'] = limit;
    if (order != null) kwargs['order'] = order;

    // search_read uses a different endpoint on newer Odoo versions
    final result = await callKw(
      model: model,
      method: 'search_read',
      args: [domain],
      kwargs: kwargs,
    );

    if (result is List) {
      return result.cast<Map<String, dynamic>>();
    }
    // Some Odoo versions return {'records': [...], 'length': n}
    if (result is Map && result.containsKey('records')) {
      return (result['records'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Searches for record IDs matching [domain].
  Future<List<int>> search(
    String model,
    List<dynamic> domain, {
    int? limit,
    int offset = 0,
    String? order,
  }) async {
    final kwargs = <String, dynamic>{
      'offset': offset,
    };
    if (limit != null) kwargs['limit'] = limit;
    if (order != null) kwargs['order'] = order;

    final result = await callKw(
      model: model,
      method: 'search',
      args: [domain],
      kwargs: kwargs,
    );

    return (result as List).cast<int>();
  }

  /// Reads fields from records by their [ids].
  Future<List<OdooRecord>> read(
    String model,
    List<int> ids, {
    List<String> fields = const [],
  }) async {
    final result = await callKw(
      model: model,
      method: 'read',
      args: [ids],
      kwargs: {'fields': fields},
    );

    return (result as List).cast<Map<String, dynamic>>();
  }

  /// Returns the count of records matching [domain].
  Future<int> searchCount(String model, List<dynamic> domain) async {
    final result = await callKw(
      model: model,
      method: 'search_count',
      args: [domain],
    );
    return result as int;
  }

  /// Creates a new record and returns its ID.
  Future<int> create(String model, Map<String, dynamic> values) async {
    final result = await callKw(
      model: model,
      method: 'create',
      args: [values],
    );
    // Odoo 17+ returns a list for create
    if (result is List) return result.first as int;
    return result as int;
  }

  /// Creates multiple records and returns their IDs.
  Future<List<int>> createMulti(
    String model,
    List<Map<String, dynamic>> valuesList,
  ) async {
    final result = await callKw(
      model: model,
      method: 'create',
      args: [valuesList],
    );
    return (result as List).cast<int>();
  }

  /// Updates records by [ids] with [values]. Returns `true` on success.
  Future<bool> write(
    String model,
    List<int> ids,
    Map<String, dynamic> values,
  ) async {
    final result = await callKw(
      model: model,
      method: 'write',
      args: [ids, values],
    );
    return result as bool;
  }

  /// Deletes records by [ids]. Returns `true` on success.
  Future<bool> unlink(String model, List<int> ids) async {
    final result = await callKw(
      model: model,
      method: 'unlink',
      args: [ids],
    );
    return result as bool;
  }

  /// Returns field metadata for [model].
  Future<Map<String, dynamic>> fieldsGet(
    String model, {
    List<String>? attributes,
  }) async {
    final kwargs = <String, dynamic>{};
    if (attributes != null) kwargs['attributes'] = attributes;

    final result = await callKw(
      model: model,
      method: 'fields_get',
      kwargs: kwargs,
    );
    return Map<String, dynamic>.from(result as Map);
  }

  /// Returns display names for records by [ids].
  Future<List<dynamic>> nameGet(String model, List<int> ids) async {
    final result = await callKw(
      model: model,
      method: 'name_get',
      args: [ids],
    );
    return result as List;
  }

  /// Searches records by display name.
  Future<List<dynamic>> nameSearch(
    String model,
    String name, {
    List<dynamic> domain = const [],
    int limit = 8,
  }) async {
    final result = await callKw(
      model: model,
      method: 'name_search',
      kwargs: {
        'name': name,
        'domain': domain,
        'limit': limit,
      },
    );
    return result as List;
  }

  /// Returns default values for [fields] on [model].
  Future<Map<String, dynamic>> defaultGet(
    String model,
    List<String> fields,
  ) async {
    final result = await callKw(
      model: model,
      method: 'default_get',
      args: [fields],
    );
    return Map<String, dynamic>.from(result as Map);
  }

  /// Calls any model method with custom arguments.
  Future<dynamic> callMethod(
    String model,
    String method, {
    List<dynamic> args = const [],
    Map<String, dynamic> kwargs = const {},
  }) {
    return callKw(model: model, method: method, args: args, kwargs: kwargs);
  }
}
