import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import '../utils/helpers/encryption_helper.dart';
import '../utils/secure_storage_helper.dart';
import 'api_service.dart';


class HttpService implements ApiService {

  // Initialize encryption helper
  HttpService() {
    EncryptionHelper.init();
  }

  // Helper method to encrypt request body
  String _encryptRequestBody(Map<String, dynamic> bodyData) {
    try {
      final jsonString = jsonEncode(bodyData);
      final encryptedData = EncryptionHelper.encrypt(jsonString);
      return jsonEncode({'payload': encryptedData});
    } catch (e) {
      print('❌ Failed to encrypt request body: $e');
      return jsonEncode(bodyData);
    }
  }

  // Helper method to decrypt response body
  dynamic _decryptResponseBody(String responseBody) {
    try {
      // Parse the response JSON
      final jsonResponse = jsonDecode(responseBody);

      // Check if response has a payload field
      if (jsonResponse is Map && jsonResponse.containsKey('payload')) {
        final encryptedPayload = jsonResponse['payload'] as String;

        if (encryptedPayload.isNotEmpty && EncryptionHelper.isEncrypted(encryptedPayload)) {
          final decryptedBody = EncryptionHelper.decrypt(encryptedPayload);
          // Parse the decrypted JSON string
          return jsonDecode(decryptedBody);
        }
      }

      // If no payload field or not encrypted, return original response
      return jsonResponse;
    } catch (e) {
      print('❌ Failed to decrypt/parse response: $e');
      return responseBody;
    }
  }

  // Helper method to process response (decrypt if needed)
  Future<http.Response> _processResponse(http.Response response) async {

    final body = response.body;

    if (body.isEmpty) {
      return response;
    }

    try {
      final decryptedData = _decryptResponseBody(body);

      final newHeaders = Map<String, String>.from(response.headers)
        ..remove('content-length');

      return http.Response(
        decryptedData is String ? decryptedData : jsonEncode(decryptedData),
        response.statusCode,
        headers: newHeaders,
        request: response.request,
      );
    } catch (e) {
      print('❌ Failed to process response: $e');
      return response;
    }
  }

  // ---------------------------------------------------------------------
  // Helpers for reading the decrypted body's inner "code"/"message" so the
  // UI can show a proper alert, e.g.:
  static int? extractInnerCode(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['code'] != null) {
        return int.tryParse(decoded['code'].toString());
      }
    } catch (e) {
      // ignore, fall through to null
    }
    return null;
  }

  // True if the inner code represents success (2xx range).
  // Falls back to the raw HTTP status if no inner code is present.
  static bool isSuccess(http.Response response) {
    final code = extractInnerCode(response);
    if (code == null) {
      return response.statusCode >= 200 && response.statusCode < 300;
    }
    return code >= 200 && code < 300;
  }

  // Extracts a human-readable message for display in an alert/snackbar.
  // Prefers the first field-level validation message (more specific),
  static String extractErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) {
        final errors = decoded['errors'];
        if (errors is List && errors.isNotEmpty) {
          final first = errors.first;
          if (first is Map && first['msg'] != null) {
            return first['msg'].toString();
          }
        }

        if (decoded['message'] != null) {
          return decoded['message'].toString();
        }
      }

      return 'Something went wrong. Please try again.';
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  @override
  Future<http.Response> getRequest(String endpoint, {String? type, Map<String, String>? queryParams}) async {
    final token = await SecureStorageHelper.getToken();
    final uri = Uri.parse('${AppConstants.apiUrl}$endpoint').replace(queryParameters: queryParams);

    final headers = {
      'Content-Type': 'application/json',
      'auth_token': token?.isNotEmpty == true ? token! : 'default_token',
    };

    http.Response response = type == 'MQTTCONFIG'
        ? await http.get(Uri.parse(endpoint), headers: headers)
        : await http.get(uri, headers: headers);

    return await _processResponse(response);
  }

  @override
  Future<http.Response> postRequest(String endpoint, Map<String, dynamic> bodyData) async {
    final token = await SecureStorageHelper.getToken();

    final headers = {
      'Content-Type': 'application/json',
      'auth_token': token?.isNotEmpty == true ? token! : 'default_token',
    };

    // Encrypt the request body
    final encryptedBody = _encryptRequestBody(bodyData);

    try {
      http.Response response = await http.post(
        Uri.parse('${AppConstants.apiUrl}$endpoint'),
        headers: headers,
        body: encryptedBody,
      ).timeout(const Duration(seconds: 60));

      return await _processResponse(response);
    } catch (e) {
      print('Request error: $e');
      rethrow;
    }
  }

  @override
  Future<http.Response> putRequest(String endpoint, Map<String, dynamic> bodyData) async {
    final token = await SecureStorageHelper.getToken();

    final headers = {
      'Content-Type': 'application/json',
      'auth_token': token?.isNotEmpty == true ? token! : 'default_token',
    };

    final encryptedBody = _encryptRequestBody(bodyData);

    try {
      http.Response response = await http.put(
        Uri.parse('${AppConstants.apiUrl}$endpoint'),
        headers: headers,
        body: encryptedBody,
      ).timeout(const Duration(seconds: 60));

      return await _processResponse(response);
    } catch (e) {
      print('Request error: $e');
      rethrow;
    }
  }

  @override
  Future<http.Response> deleteRequest(String endpoint, Map<String, dynamic> bodyData) async {
    final token = await SecureStorageHelper.getToken();

    final headers = {
      'Content-Type': 'application/json',
      'auth_token': token?.isNotEmpty == true ? token! : 'default_token',
    };

    final encryptedBody = _encryptRequestBody(bodyData);

    http.Response response = await http.delete(
      Uri.parse('${AppConstants.apiUrl}$endpoint'),
      headers: headers,
      body: encryptedBody,
    ).timeout(const Duration(seconds: 60));

    return await _processResponse(response);
  }
}