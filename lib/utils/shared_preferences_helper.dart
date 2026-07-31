import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PreferenceHelper {
  static const String _authTokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _roleKey = 'user_role';
  static const String _countryCodeKey = 'country_code';
  static const String _mobileNumberKey = 'mobile_number';
  static const String _emailKey = 'email';
  static const String _deviceTokenKey = 'deviceToken';
  static const String _confPermissionKey = 'permissionDenied';
  static const String _passwordKey = 'password';

  static const _storage = FlutterSecureStorage();

  static Future<void> saveUserDetails({
    required String token,
    required int userId,
    required String userName,
    required String role,
    required String countryCode,
    required String mobileNumber,
    required String email,
    required bool configPermission,
    required String password,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Non-sensitive data in SharedPreferences
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_userNameKey, userName);
    await prefs.setString(_roleKey, role);
    await prefs.setString(_countryCodeKey, countryCode);
    await prefs.setBool(_confPermissionKey, configPermission);

    // Sensitive data in Secure Storage
    await _storage.write(key: _authTokenKey, value: token);
    await _storage.write(key: _mobileNumberKey, value: mobileNumber);
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _passwordKey, value: password);
    
    // Remove sensitive data from SharedPreferences if it was there before (migration)
    await prefs.remove(_authTokenKey);
    await prefs.remove(_mobileNumberKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_passwordKey);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _authTokenKey);
  }

  static Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  static Future<String?> getUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  static Future<String?> getUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<String?> getCountryCode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_countryCodeKey);
  }

  static Future<String?> getMobileNumber() async {
    return await _storage.read(key: _mobileNumberKey);
  }

  static Future<String?> getEmail() async {
    return await _storage.read(key: _emailKey);
  }

  static Future<void> clearAll() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _storage.deleteAll();
  }

  static Future<String?> getDeviceToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceTokenKey);
  }

  static Future<bool?> getConfigPermission() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_confPermissionKey);
  }

  static Future<String?> getUserPassword() async {
    return await _storage.read(key: _passwordKey);
  }
}
