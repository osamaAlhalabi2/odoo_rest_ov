import 'package:odoo_rest_ov/odoo_rest_ov.dart';
import 'package:test/test.dart';

void main() {
  group('OdooException.fromRpcError', () {
    test('maps AccessDenied to OdooAccessDeniedException', () {
      final error = {
        'message': 'Access Denied',
        'data': {
          'name': 'odoo.exceptions.AccessDenied',
          'message': 'Invalid credentials',
        },
      };
      final exception = OdooException.fromRpcError(error);
      expect(exception, isA<OdooAccessDeniedException>());
      expect(exception.message, 'Access Denied');
    });

    test('maps SessionExpiredException to OdooSessionExpiredException', () {
      final error = {
        'message': 'Session expired',
        'data': {
          'name': 'odoo.http.SessionExpiredException',
          'message': 'Session expired',
        },
      };
      final exception = OdooException.fromRpcError(error);
      expect(exception, isA<OdooSessionExpiredException>());
    });

    test('maps AccessError to OdooAccessErrorException', () {
      final error = {
        'message': 'Access Error',
        'data': {
          'name': 'odoo.exceptions.AccessError',
          'message': 'You do not have access',
        },
      };
      final exception = OdooException.fromRpcError(error);
      expect(exception, isA<OdooAccessErrorException>());
    });

    test('maps ValidationError to OdooValidationException', () {
      final error = {
        'message': 'Validation Error',
        'data': {
          'name': 'odoo.exceptions.ValidationError',
          'message': 'Field is required',
        },
      };
      final exception = OdooException.fromRpcError(error);
      expect(exception, isA<OdooValidationException>());
    });

    test('maps MissingError to OdooMissingErrorException', () {
      final error = {
        'message': 'Missing Error',
        'data': {
          'name': 'odoo.exceptions.MissingError',
          'message': 'Record does not exist',
        },
      };
      final exception = OdooException.fromRpcError(error);
      expect(exception, isA<OdooMissingErrorException>());
    });

    test('maps UserError to OdooUserErrorException', () {
      final error = {
        'message': 'User Error',
        'data': {
          'name': 'odoo.exceptions.UserError',
          'message': 'Cannot do this',
        },
      };
      final exception = OdooException.fromRpcError(error);
      expect(exception, isA<OdooUserErrorException>());
    });

    test('falls back to OdooRpcException for unknown errors', () {
      final error = {
        'message': 'Some weird error',
        'data': {
          'name': 'some.unknown.error',
          'message': 'Unknown',
        },
      };
      final exception = OdooException.fromRpcError(error);
      expect(exception, isA<OdooRpcException>());
    });

    test('detects session expired from message content', () {
      final error = {
        'message': 'Session expired',
        'data': {
          'name': 'werkzeug.exceptions.Forbidden',
          'message': 'Session expired',
        },
      };
      final exception = OdooException.fromRpcError(error);
      expect(exception, isA<OdooSessionExpiredException>());
    });

    test('handles missing data field', () {
      final error = {
        'message': 'Some error',
      };
      final exception = OdooException.fromRpcError(error);
      expect(exception, isA<OdooRpcException>());
      expect(exception.message, 'Some error');
    });

    test('toString includes exception type', () {
      const e = OdooValidationException('test');
      expect(e.toString(), 'OdooValidationException: test');
    });

    test('exception hierarchy is correct', () {
      const session = OdooSessionExpiredException('test');
      const access = OdooAccessDeniedException('test');
      const rpc = OdooRpcException('test');
      const validation = OdooValidationException('test');
      const network = OdooNetworkException('test');
      const protocol = OdooProtocolException('test');

      expect(session, isA<OdooSessionException>());
      expect(session, isA<OdooException>());
      expect(access, isA<OdooSessionException>());
      expect(rpc, isA<OdooException>());
      expect(validation, isA<OdooRpcException>());
      expect(network, isA<OdooException>());
      expect(protocol, isA<OdooException>());
    });
  });

  group('User-friendly error messages', () {
    test('AccessDenied gives friendly userMessage', () {
      final error = {
        'message': 'Odoo Server Error',
        'data': {
          'name': 'odoo.exceptions.AccessDenied',
          'message': 'Access Denied',
        },
      };
      final exception = OdooException.fromRpcError(error);
      expect(exception.userMessage, 'Invalid username or password.');
    });

    test('SessionExpired gives friendly userMessage', () {
      final error = {
        'message': 'Session expired',
        'data': {
          'name': 'odoo.http.SessionExpiredException',
          'message': 'Session expired',
        },
      };
      final exception = OdooException.fromRpcError(error);
      expect(exception.userMessage,
          'Your session has expired. Please log in again.');
    });

    test('ValidationError strips "The operation cannot be completed:" prefix',
        () {
      final error = {
        'message': 'Odoo Server Error',
        'data': {
          'name': 'odoo.exceptions.ValidationError',
          'message':
              'The operation cannot be completed: Contacts require a name',
          'arguments': [
            'The operation cannot be completed: Contacts require a name'
          ],
        },
      };
      final exception = OdooException.fromRpcError(error);
      expect(exception.userMessage, 'Contacts require a name.');
      // Raw message preserved for debugging
      expect(exception.message, 'Odoo Server Error');
    });

    test('MissingError strips record references', () {
      final error = {
        'message': 'Odoo Server Error',
        'data': {
          'name': 'odoo.exceptions.MissingError',
          'message':
              'Record does not exist or has been deleted.\n(Record: res.partner(999999999,), User: 2)',
          'arguments': [
            'Record does not exist or has been deleted.\n(Record: res.partner(999999999,), User: 2)'
          ],
        },
      };
      final exception = OdooException.fromRpcError(error);
      expect(exception.userMessage,
          'Record does not exist or has been deleted.');
    });

    test('UserError extracts clean message from arguments', () {
      final error = {
        'message': 'Odoo Server Error',
        'data': {
          'name': 'odoo.exceptions.UserError',
          'message': 'You cannot delete an active product.',
          'arguments': ['You cannot delete an active product.'],
        },
      };
      final exception = OdooException.fromRpcError(error);
      expect(exception.userMessage, 'You cannot delete an active product.');
    });

    test('generic "Odoo Server Error" gets type-specific default', () {
      final error = {
        'message': 'Odoo Server Error',
        'data': {
          'name': 'odoo.exceptions.AccessError',
          'message': 'Odoo Server Error',
        },
      };
      final exception = OdooException.fromRpcError(error);
      expect(exception.userMessage,
          'You do not have permission to perform this action.');
    });

    test('userMessage defaults to message when no special cleanup needed', () {
      const e = OdooException('Custom error');
      expect(e.userMessage, 'Custom error');
    });

    test('userMessage can be explicitly provided', () {
      const e = OdooException(
        'Technical details here',
        userMessage: 'Something went wrong.',
      );
      expect(e.userMessage, 'Something went wrong.');
      expect(e.message, 'Technical details here');
    });
  });
}
