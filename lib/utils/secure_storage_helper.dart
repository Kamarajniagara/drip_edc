
import '../services/secure_storage_service.dart';

class SecureStorageHelper {
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
    final storage = SecureStorageService.instance;
    await storage.write(_authTokenKey, token);
    await storage.write(_passwordKey, password);
    await storage.write(_userIdKey, userId.toString());
    await storage.write(_userNameKey, userName);
    await storage.write(_roleKey, role);
    await storage.write(_countryCodeKey, countryCode);
    await storage.write(_mobileNumberKey, mobileNumber);
    await storage.write(_emailKey, email);
    await storage.write(_confPermissionKey, configPermission.toString());
  }

  static Future<String?> getToken() async {
    return SecureStorageService.instance.read(_authTokenKey);
  }

  static Future<int?> getUserId() async {
    final value = await SecureStorageService.instance.read(_userIdKey);
    return value != null ? int.tryParse(value) : null;
  }

  static Future<String?> getUserRole() async {
    return SecureStorageService.instance.read(_roleKey);
  }

  static Future<String?> getUserName() async {
    return SecureStorageService.instance.read(_userNameKey);
  }

  static Future<String?> getCountryCode() async {
    return SecureStorageService.instance.read(_countryCodeKey);
  }

  static Future<String?> getMobileNumber() async {
    return SecureStorageService.instance.read(_mobileNumberKey);
  }

  static Future<String?> getEmail() async {
    return SecureStorageService.instance.read(_emailKey);
  }

  static Future<void> clearAll() async {
    await SecureStorageService.instance.deleteAll();
  }

  static Future<void> saveDeviceToken(String token) async {
    await SecureStorageService.instance.write(_deviceTokenKey, token);
  }

  static Future<String?> getDeviceToken() async {
    return SecureStorageService.instance.read(_deviceTokenKey);
  }

  static Future<bool?> getConfigPermission() async {
    final value = await SecureStorageService.instance.read(_confPermissionKey);
    if (value == null) return null;
    return value == 'true';
  }

  static Future<String?> getUserPassword() async {
    return SecureStorageService.instance.read(_passwordKey);
  }
}