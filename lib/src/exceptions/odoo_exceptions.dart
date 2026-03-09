/// Odoo-specific exception hierarchy.
///
/// All exceptions thrown by [OdooClient] extend [OdooException].
/// Specific subtypes are auto-mapped from Odoo's `error.data.name` field.
///
/// Each exception provides:
/// - [message] — The raw Odoo error message (for developers/logging).
/// - [userMessage] — A clean, user-friendly message safe to display in UI.
/// - [errorData] — The full raw error data map for debugging.
library;

/// Base exception for all Odoo errors.
class OdooException implements Exception {
  /// Raw Odoo error message (may contain technical details, tracebacks).
  final String message;

  /// Clean, user-friendly message safe to show in the app UI.
  ///
  /// Strips out technical details like Python tracebacks, SQL errors,
  /// record references, and model names.
  final String userMessage;

  /// Raw error data from the JSON-RPC response, if available.
  final Map<String, dynamic>? errorData;

  const OdooException(
    this.message, {
    String? userMessage,
    this.errorData,
  }) : userMessage = userMessage ?? message;

  /// Factory that maps Odoo's `error.data.name` to the correct exception type
  /// and extracts a user-friendly message.
  factory OdooException.fromRpcError(Map<String, dynamic> error) {
    final data = error['data'] as Map<String, dynamic>?;
    final name = data?['name'] as String? ?? '';
    final rawMessage = error['message'] as String? ??
        data?['message'] as String? ??
        'Unknown Odoo error';

    // Extract the clean message from data.arguments or data.message
    final arguments = data?['arguments'] as List?;
    final dataMessage = data?['message'] as String?;
    final cleanMessage = _extractUserMessage(
      rawMessage: rawMessage,
      dataMessage: dataMessage,
      arguments: arguments,
      errorName: name,
    );

    switch (name) {
      case 'odoo.exceptions.AccessDenied':
        return OdooAccessDeniedException(rawMessage,
            userMessage: cleanMessage, errorData: data);
      case 'odoo.http.SessionExpiredException':
        return OdooSessionExpiredException(rawMessage,
            userMessage: cleanMessage, errorData: data);
      case 'odoo.exceptions.AccessError':
        return OdooAccessErrorException(rawMessage,
            userMessage: cleanMessage, errorData: data);
      case 'odoo.exceptions.ValidationError':
        return OdooValidationException(rawMessage,
            userMessage: cleanMessage, errorData: data);
      case 'odoo.exceptions.MissingError':
        return OdooMissingErrorException(rawMessage,
            userMessage: cleanMessage, errorData: data);
      case 'odoo.exceptions.UserError':
        return OdooUserErrorException(rawMessage,
            userMessage: cleanMessage, errorData: data);
      default:
        if (name.contains('SessionExpired') ||
            rawMessage.contains('Session expired')) {
          return OdooSessionExpiredException(rawMessage,
              userMessage: cleanMessage, errorData: data);
        }
        if (name.contains('AccessDenied') ||
            rawMessage.contains('Access Denied')) {
          return OdooAccessDeniedException(rawMessage,
              userMessage: cleanMessage, errorData: data);
        }
        return OdooRpcException(rawMessage,
            userMessage: cleanMessage, errorData: data);
    }
  }

  /// Extracts a clean, user-facing message from the Odoo error data.
  static String _extractUserMessage({
    required String rawMessage,
    String? dataMessage,
    List<dynamic>? arguments,
    required String errorName,
  }) {
    // 1. For known error types, provide friendly defaults
    if (errorName == 'odoo.exceptions.AccessDenied') {
      return 'Invalid username or password.';
    }
    if (errorName == 'odoo.http.SessionExpiredException' ||
        errorName.contains('SessionExpired')) {
      return 'Your session has expired. Please log in again.';
    }

    // 2. Try to extract clean message from data.arguments (most specific)
    if (arguments != null && arguments.isNotEmpty) {
      final arg = arguments.first.toString();
      return _cleanMessage(arg, errorName);
    }

    // 3. Fall back to data.message
    if (dataMessage != null && dataMessage != 'Odoo Server Error') {
      return _cleanMessage(dataMessage, errorName);
    }

    // 4. Fall back to top-level message
    if (rawMessage != 'Odoo Server Error') {
      return _cleanMessage(rawMessage, errorName);
    }

    // 5. Generic fallback by error type
    return _defaultMessageForType(errorName);
  }

  /// Cleans up a raw Odoo error message for user display.
  static String _cleanMessage(String raw, String errorName) {
    var msg = raw;

    // Remove "(Record: res.partner(123,), User: 2)" style suffixes
    msg = msg.replaceAll(RegExp(r'\n?\(Record:.*\)'), '');

    // Remove "(Document model: ir.model, Operation: read)" style
    msg = msg.replaceAll(
        RegExp(r'\n?\(Document model:.*?\)'), '');

    // Remove Python class refs like "odoo.exceptions.ValidationError:"
    msg = msg.replaceAll(RegExp(r'odoo\.\w+\.\w+:\s*'), '');

    // Strip leading "The operation cannot be completed: " prefix
    msg = msg.replaceFirst(
        RegExp(r'^The operation cannot be completed:\s*', caseSensitive: false),
        '');

    // Remove SQL/technical details after \n\n
    final doubleNewline = msg.indexOf('\n\n');
    if (doubleNewline > 0) {
      msg = msg.substring(0, doubleNewline);
    }

    // Clean up whitespace
    msg = msg.trim();

    // Capitalize first letter
    if (msg.isNotEmpty) {
      msg = msg[0].toUpperCase() + msg.substring(1);
    }

    // Ensure it ends with a period
    if (msg.isNotEmpty && !msg.endsWith('.') && !msg.endsWith('!') && !msg.endsWith('?')) {
      msg = '$msg.';
    }

    return msg.isEmpty ? _defaultMessageForType(errorName) : msg;
  }

  /// Returns a generic user-friendly message for each error type.
  static String _defaultMessageForType(String errorName) {
    switch (errorName) {
      case 'odoo.exceptions.AccessError':
        return 'You do not have permission to perform this action.';
      case 'odoo.exceptions.ValidationError':
        return 'The data you entered is not valid. Please check and try again.';
      case 'odoo.exceptions.MissingError':
        return 'The record you are looking for no longer exists.';
      case 'odoo.exceptions.UserError':
        return 'The operation could not be completed.';
      case 'odoo.exceptions.AccessDenied':
        return 'Invalid username or password.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  @override
  String toString() => 'OdooException: $message';
}

// -- Session exceptions --

/// Base for session-related errors.
class OdooSessionException extends OdooException {
  const OdooSessionException(super.message, {super.userMessage, super.errorData});

  @override
  String toString() => 'OdooSessionException: $message';
}

/// Thrown when authentication credentials are invalid.
class OdooAccessDeniedException extends OdooSessionException {
  const OdooAccessDeniedException(super.message, {super.userMessage, super.errorData});

  @override
  String toString() => 'OdooAccessDeniedException: $message';
}

/// Thrown when the session has expired and must be re-authenticated.
class OdooSessionExpiredException extends OdooSessionException {
  const OdooSessionExpiredException(super.message, {super.userMessage, super.errorData});

  @override
  String toString() => 'OdooSessionExpiredException: $message';
}

// -- RPC exceptions --

/// Base for Odoo business-logic errors returned via JSON-RPC.
class OdooRpcException extends OdooException {
  const OdooRpcException(super.message, {super.userMessage, super.errorData});

  @override
  String toString() => 'OdooRpcException: $message';
}

/// Thrown when the user lacks access rights.
class OdooAccessErrorException extends OdooRpcException {
  const OdooAccessErrorException(super.message, {super.userMessage, super.errorData});

  @override
  String toString() => 'OdooAccessErrorException: $message';
}

/// Thrown when a record fails validation constraints.
class OdooValidationException extends OdooRpcException {
  const OdooValidationException(super.message, {super.userMessage, super.errorData});

  @override
  String toString() => 'OdooValidationException: $message';
}

/// Thrown when a referenced record does not exist.
class OdooMissingErrorException extends OdooRpcException {
  const OdooMissingErrorException(super.message, {super.userMessage, super.errorData});

  @override
  String toString() => 'OdooMissingErrorException: $message';
}

/// Thrown for user-facing errors (e.g. business rule violations).
class OdooUserErrorException extends OdooRpcException {
  const OdooUserErrorException(super.message, {super.userMessage, super.errorData});

  @override
  String toString() => 'OdooUserErrorException: $message';
}

// -- Transport exceptions --

/// Thrown when a network error occurs (timeout, DNS, connectivity).
class OdooNetworkException extends OdooException {
  const OdooNetworkException(super.message, {super.userMessage, super.errorData});

  @override
  String toString() => 'OdooNetworkException: $message';
}

/// Thrown when the server response is not valid JSON-RPC 2.0.
class OdooProtocolException extends OdooException {
  const OdooProtocolException(super.message, {super.userMessage, super.errorData});

  @override
  String toString() => 'OdooProtocolException: $message';
}
