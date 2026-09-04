import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../utils/constants.dart';
import '../utils/helpers/encryption_helper.dart';
import '../utils/secure_storage_helper.dart';
import 'api_service.dart';

class HttpService implements ApiService {
  IOClient? _client;

  HttpService() {
    EncryptionHelper.init();
  }

  // ------------------------------------------------------------
  // SSL PINNED CLIENT
  // ------------------------------------------------------------
  Future<IOClient> _getClient() async {
    if (_client != null) {
      return _client!;
    }

    final certificateData = await rootBundle.load(
      'assets/certificates/server.crt',
    );

    final securityContext = SecurityContext(
      withTrustedRoots: false,
    );

    securityContext.setTrustedCertificatesBytes(
      certificateData.buffer.asUint8List(),
    );

    final httpClient = HttpClient(
      context: securityContext,
    );

    _client = IOClient(httpClient);

    return _client!;
  }

  // ------------------------------------------------------------
  // REQUEST ENCRYPTION
  // ------------------------------------------------------------
  String _encryptRequestBody(
      Map<String, dynamic> bodyData,
      ) {
    try {
      final jsonString = jsonEncode(bodyData);

      final encryptedData =
      EncryptionHelper.encrypt(jsonString);

      return jsonEncode({
        'payload': encryptedData,
      });
    } catch (e) {
      print(
        '❌ Failed to encrypt request body: $e',
      );

      return jsonEncode(bodyData);
    }
  }

  // ------------------------------------------------------------
  // RESPONSE DECRYPTION
  // ------------------------------------------------------------
  dynamic _decryptResponseBody(
      String responseBody,
      ) {
    try {
      final jsonResponse =
      jsonDecode(responseBody);

      if (jsonResponse is Map &&
          jsonResponse.containsKey('payload')) {
        final encryptedPayload =
        jsonResponse['payload'] as String;

        if (encryptedPayload.isNotEmpty &&
            EncryptionHelper.isEncrypted(
              encryptedPayload,
            )) {
          final decryptedBody =
          EncryptionHelper.decrypt(
            encryptedPayload,
          );

          return jsonDecode(
            decryptedBody,
          );
        }
      }

      return jsonResponse;
    } catch (e) {
      print(
        '❌ Failed to decrypt/parse response: $e',
      );

      return responseBody;
    }
  }

  // ------------------------------------------------------------
  // PROCESS RESPONSE
  // ------------------------------------------------------------
  Future<http.Response> _processResponse(
      http.Response response,
      ) async {
    final body = response.body;

    if (body.isEmpty) {
      return response;
    }

    try {
      final decryptedData =
      _decryptResponseBody(body);

      final newHeaders =
      Map<String, String>.from(
        response.headers,
      )..remove('content-length');

      return http.Response(
        decryptedData is String
            ? decryptedData
            : jsonEncode(decryptedData),
        response.statusCode,
        headers: newHeaders,
        request: response.request,
      );
    } catch (e) {
      print(
        '❌ Failed to process response: $e',
      );

      return response;
    }
  }

  // ------------------------------------------------------------
  // COMMON HEADERS
  // ------------------------------------------------------------
  Map<String, String> _buildHeaders(
      String? token,
      ) {
    return {
      'Content-Type': 'application/json',
      'auth_token':
      token?.isNotEmpty == true
          ? token!
          : 'default_token',
    };
  }

  // ------------------------------------------------------------
  // RESPONSE HELPERS
  // ------------------------------------------------------------
  static int? extractInnerCode(
      http.Response response,
      ) {
    try {
      final decoded =
      jsonDecode(response.body);

      if (decoded is Map &&
          decoded['code'] != null) {
        return int.tryParse(
          decoded['code'].toString(),
        );
      }
    } catch (_) {}

    return null;
  }

  static bool isSuccess(
      http.Response response,
      ) {
    final code =
    extractInnerCode(response);

    if (code == null) {
      return response.statusCode >= 200 &&
          response.statusCode < 300;
    }

    return code >= 200 &&
        code < 300;
  }

  static String extractErrorMessage(
      http.Response response,
      ) {
    try {
      final decoded =
      jsonDecode(response.body);

      if (decoded is Map) {
        final errors =
        decoded['errors'];

        if (errors is List &&
            errors.isNotEmpty) {
          final first =
              errors.first;

          if (first is Map &&
              first['msg'] != null) {
            return first['msg']
                .toString();
          }
        }

        if (decoded['message'] != null) {
          return decoded['message']
              .toString();
        }
      }

      return 'Something went wrong. Please try again.';
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  // ------------------------------------------------------------
  // GET
  // ------------------------------------------------------------
  @override
  Future<http.Response> getRequest(
      String endpoint, {
        String? type,
        Map<String, String>? queryParams,
      }) async {
    final token = await SecureStorageHelper.getToken();

    final headers = _buildHeaders(token);

    if (type == 'MQTTCONFIG') {
      final response = await http.get(
        Uri.parse(endpoint),
        headers: headers,
      );

      return _processResponse(response);
    }

    final uri = Uri.parse(
      '${AppConstants.apiUrl}$endpoint',
    ).replace(
      queryParameters: queryParams,
    );

    late http.Response response;

    if (kIsWeb) {
      response = await http
          .get(
        uri,
        headers: headers,
      )
          .timeout(
        const Duration(seconds: 60),
      );
    } else {
      final client = await _getClient();

      response = await client
          .get(
        uri,
        headers: headers,
      )
          .timeout(
        const Duration(seconds: 60),
      );
    }

    return _processResponse(response);
  }

  // ------------------------------------------------------------
  // POST
  // ------------------------------------------------------------
  @override
  Future<http.Response> postRequest(
      String endpoint,
      Map<String, dynamic> bodyData,
      ) async {
    final token = await SecureStorageHelper.getToken();

    final headers = _buildHeaders(token);

    final encryptedBody = _encryptRequestBody(bodyData);

    final uri = Uri.parse(
      '${AppConstants.apiUrl}$endpoint',
    );

    try {
      late http.Response response;

      if (kIsWeb) {
        // WEB:
        // Browser handles SSL/TLS.
        response = await http
            .post(
          uri,
          headers: headers,
          body: encryptedBody,
        )
            .timeout(
          const Duration(seconds: 60),
        );
      } else {
        // ANDROID / IOS:
        // Use SSL pinned client.
        final client = await _getClient();

        response = await client
            .post(
          uri,
          headers: headers,
          body: encryptedBody,
        )
            .timeout(
          const Duration(seconds: 60),
        );
      }

      return _processResponse(response);
    } catch (e) {
      print('❌ POST request error: $e');
      rethrow;
    }
  }

  // ------------------------------------------------------------
  // PUT
  // ------------------------------------------------------------
  @override
  Future<http.Response> putRequest(
      String endpoint,
      Map<String, dynamic> bodyData,
      ) async {
    final token = await SecureStorageHelper.getToken();

    final headers = _buildHeaders(token);

    final encryptedBody = _encryptRequestBody(bodyData);

    final uri = Uri.parse(
      '${AppConstants.apiUrl}$endpoint',
    );

    try {
      late http.Response response;

      if (kIsWeb) {
        response = await http
            .put(
          uri,
          headers: headers,
          body: encryptedBody,
        )
            .timeout(
          const Duration(seconds: 60),
        );
      } else {
        final client = await _getClient();

        response = await client
            .put(
          uri,
          headers: headers,
          body: encryptedBody,
        )
            .timeout(
          const Duration(seconds: 60),
        );
      }

      return _processResponse(response);
    } catch (e) {
      print('❌ PUT request error: $e');
      rethrow;
    }
  }

  // ------------------------------------------------------------
  // DELETE
  // ------------------------------------------------------------
  @override
  Future<http.Response> deleteRequest(
      String endpoint,
      Map<String, dynamic> bodyData,
      ) async {
    final token = await SecureStorageHelper.getToken();

    final headers = _buildHeaders(token);

    final encryptedBody = _encryptRequestBody(bodyData);

    final uri = Uri.parse(
      '${AppConstants.apiUrl}$endpoint',
    );

    try {
      late http.Response response;

      if (kIsWeb) {
        response = await http
            .delete(
          uri,
          headers: headers,
          body: encryptedBody,
        )
            .timeout(
          const Duration(seconds: 60),
        );
      } else {
        final client = await _getClient();

        response = await client
            .delete(
          uri,
          headers: headers,
          body: encryptedBody,
        )
            .timeout(
          const Duration(seconds: 60),
        );
      }

      return _processResponse(response);
    } catch (e) {
      print('❌ DELETE request error: $e');
      rethrow;
    }
  }

  // ------------------------------------------------------------
  // CLEANUP
  // ------------------------------------------------------------
  void dispose() {
    _client?.close();
    _client = null;
  }
}

/*
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
}*/
