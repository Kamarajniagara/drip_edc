
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import '../utils/helpers/encryption_helper.dart';
import '../utils/shared_preferences_helper.dart';
import 'api_service.dart';

/*class HttpService implements ApiService {
  @override
  Future<http.Response> getRequest(String endpoint, {String? type, Map<String, String>? queryParams}) async {
    final token = await PreferenceHelper.getToken();
    final uri = Uri.parse('${AppConstants.apiUrl}$endpoint').replace(queryParameters: queryParams);
    print('uri:$uri');
    final headers = {
      'Content-Type': 'application/json',
      'auth_token': token?.isNotEmpty == true ? token! : 'default_token',
    };

    return type == 'MQTTCONFIG'
        ? http.get(Uri.parse(endpoint), headers: headers)
        : http.get(uri, headers: headers);
  }

  @override
  Future<http.Response> postRequest(String endpoint, Map<String, dynamic> bodyData) async {

    print('bodyData : ${jsonEncode(bodyData)}');
    print('${AppConstants.apiUrl}$endpoint');
    final token = await PreferenceHelper.getToken();

    final headers = {
      'Content-Type': 'application/json',
      'auth_token': token?.isNotEmpty == true ? token! : 'default_token',
    };

    return http.post(
      Uri.parse('${AppConstants.apiUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(bodyData),
    );

  }

  @override
  Future<http.Response> putRequest(String endpoint, Map<String, dynamic> bodyData) async {
    final token = await PreferenceHelper.getToken();

    final headers = {
      'Content-Type': 'application/json',
      'auth_token': token?.isNotEmpty == true ? token! : 'default_token',
    };

    return http.put(
      Uri.parse('${AppConstants.apiUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(bodyData),
    );
  }

  @override
  Future<http.Response> deleteRequest(String endpoint, Map<String, dynamic> bodyData) async {
    final token = await PreferenceHelper.getToken();

    final headers = {
      'Content-Type': 'application/json',
      'auth_token': token?.isNotEmpty == true ? token! : 'default_token',
    };

    return http.delete(
      Uri.parse('${AppConstants.apiUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(bodyData),
    );
  }
}*/



class HttpService implements ApiService {

  // Initialize encryption helper
  HttpService() {
    EncryptionHelper.init();
  }

  // Helper method to encrypt request body
  String _encryptRequestBody(Map<String, dynamic> bodyData) {
    try {
      final jsonString = jsonEncode(bodyData);
      print('Original JSON: $jsonString');

      final encryptedData = EncryptionHelper.encrypt(jsonString);
      print('✅ Request body encrypted successfully');

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
          print('✅ Response decrypted successfully');

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
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = response.body;

      print('Raw response body: $body');

      if (body.isNotEmpty) {
        try {
          final decryptedData = _decryptResponseBody(body);

          // Create new response with decrypted body as JSON string
          return http.Response(
            jsonEncode(decryptedData),
            response.statusCode,
            headers: response.headers,
            request: response.request,
          );
        } catch (e) {
          print('❌ Failed to process response: $e');
          return response;
        }
      }
    }
    return response;
  }

  @override
  Future<http.Response> getRequest(String endpoint, {String? type, Map<String, String>? queryParams}) async {
    final token = await PreferenceHelper.getToken();
    final uri = Uri.parse('${AppConstants.apiUrl}$endpoint').replace(queryParameters: queryParams);
    print('uri:$uri');

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
    print('Original bodyData: $bodyData');
    print('URL: ${AppConstants.apiUrl}$endpoint');

    final token = await PreferenceHelper.getToken();

    final headers = {
      'Content-Type': 'application/json',
      'auth_token': token?.isNotEmpty == true ? token! : 'default_token',
    };

    // Encrypt the request body
    final encryptedBody = _encryptRequestBody(bodyData);
    print('Encrypted body: $encryptedBody');

    try {
      http.Response response = await http.post(
        Uri.parse('${AppConstants.apiUrl}$endpoint'),
        headers: headers,
        body: encryptedBody,
      ).timeout(const Duration(seconds: 30));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      return await _processResponse(response);
    } catch (e) {
      print('Request error: $e');
      rethrow;
    }
  }

  @override
  Future<http.Response> putRequest(String endpoint, Map<String, dynamic> bodyData) async {
    final token = await PreferenceHelper.getToken();

    final headers = {
      'Content-Type': 'application/json',
      'auth_token': token?.isNotEmpty == true ? token! : 'default_token',
    };

    final encryptedBody = _encryptRequestBody(bodyData);

    http.Response response = await http.put(
      Uri.parse('${AppConstants.apiUrl}$endpoint'),
      headers: headers,
      body: encryptedBody,
    ).timeout(const Duration(seconds: 30));

    return await _processResponse(response);
  }

  @override
  Future<http.Response> deleteRequest(String endpoint, Map<String, dynamic> bodyData) async {
    final token = await PreferenceHelper.getToken();

    final headers = {
      'Content-Type': 'application/json',
      'auth_token': token?.isNotEmpty == true ? token! : 'default_token',
    };

    final encryptedBody = _encryptRequestBody(bodyData);

    http.Response response = await http.delete(
      Uri.parse('${AppConstants.apiUrl}$endpoint'),
      headers: headers,
      body: encryptedBody,
    ).timeout(const Duration(seconds: 30));

    return await _processResponse(response);
  }
}
