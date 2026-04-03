
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import '../utils/helpers/encryption_helper.dart';
import '../utils/shared_preferences_helper.dart';
import 'api_service.dart';

class HttpService implements ApiService {
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

    print('bodyData : $bodyData');
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
}



/*class HttpService implements ApiService {

  // Initialize encryption helper
  HttpService() {
    EncryptionHelper.init();
  }

  // Helper method to process response (decrypt if needed)
  Future<http.Response> _processResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = response.body;

      // Check if response body is encrypted
      if (body.isNotEmpty && EncryptionHelper.isEncrypted(body)) {
        try {
          final decryptedBody = EncryptionHelper.decrypt(body);
          print('✅ Response decrypted successfully');

          // Create new response with decrypted body
          return http.Response(
            decryptedBody,
            response.statusCode,
            headers: response.headers,
            request: response.request,
          );
        } catch (e) {
          print('❌ Failed to decrypt response: $e');
          // Return original response if decryption fails
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

    // Process and decrypt response if needed
    return await _processResponse(response);
  }

  @override
  Future<http.Response> postRequest(String endpoint, Map<String, dynamic> bodyData) async {
    print('bodyData : $bodyData');
    print('${AppConstants.apiUrl}$endpoint');

    final token = await PreferenceHelper.getToken();

    final headers = {
      'Content-Type': 'application/json',
      'auth_token': token?.isNotEmpty == true ? token! : 'default_token',
    };

    http.Response response = await http.post(
      Uri.parse('${AppConstants.apiUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(bodyData),
    );

    // Process and decrypt response if needed
    return await _processResponse(response);
  }

  @override
  Future<http.Response> putRequest(String endpoint, Map<String, dynamic> bodyData) async {
    final token = await PreferenceHelper.getToken();

    final headers = {
      'Content-Type': 'application/json',
      'auth_token': token?.isNotEmpty == true ? token! : 'default_token',
    };

    http.Response response = await http.put(
      Uri.parse('${AppConstants.apiUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(bodyData),
    );

    // Process and decrypt response if needed
    return await _processResponse(response);
  }

  @override
  Future<http.Response> deleteRequest(String endpoint, Map<String, dynamic> bodyData) async {
    final token = await PreferenceHelper.getToken();

    final headers = {
      'Content-Type': 'application/json',
      'auth_token': token?.isNotEmpty == true ? token! : 'default_token',
    };

    http.Response response = await http.delete(
      Uri.parse('${AppConstants.apiUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(bodyData),
    );

    // Process and decrypt response if needed
    return await _processResponse(response);
  }
}*/
