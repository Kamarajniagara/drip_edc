import 'package:oro_drip_irrigation/utils/secure_storage_helper.dart';
import '../models/user_model.dart';
import 'enums.dart';

class AuthPrefChecker {
  static Future<UserModel?> getLoggedInUser() async {
    final token = await SecureStorageHelper.getToken();
    final mobile = await SecureStorageHelper.getMobileNumber();
    final userId = await SecureStorageHelper.getUserId();
    final roleString = await SecureStorageHelper.getUserRole();

    if (token == null || token.isEmpty) return null;
    if (mobile == null || mobile.isEmpty) return null;
    if (userId == null || userId == 0) return null;
    if (roleString == null || roleString.isEmpty) return null;

    return UserModel(
      token: token,
      id: userId,
      name: await SecureStorageHelper.getUserName() ?? '',
      role: getRoleFromString(roleString),
      countryCode: await SecureStorageHelper.getCountryCode() ?? '',
      mobileNo: mobile,
      email: await SecureStorageHelper.getEmail() ?? '',
      configPermission:
      await SecureStorageHelper.getConfigPermission() ?? false,
      password: await SecureStorageHelper.getUserPassword() ?? '',
    );
  }

  static UserRole getRoleFromString(String role) {
    switch (role) {
      case '0':
        return UserRole.superAdmin;
      case '1':
        return UserRole.admin;
      case '2':
        return UserRole.dealer;
      case '3':
        return UserRole.customer;
      default:
        return UserRole.customer;
    }
  }
}