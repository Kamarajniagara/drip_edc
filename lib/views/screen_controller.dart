import 'package:flutter/material.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:provider/provider.dart';
import '../layouts/layout_selector.dart';
import '../providers/user_provider.dart';
import '../repository/repository.dart';
import '../utils/auth_pref_checker.dart';
import '../utils/secure_storage_helper.dart';
import 'common/login/login_screen.dart';

class ScreenController extends StatelessWidget {
  const ScreenController({super.key});

  static bool _versionChecked = false;

  Future<bool> initializeUser(BuildContext context) async {

    final user = await AuthPrefChecker.getLoggedInUser();

    if (user == null) return false;

    context.read<UserProvider>().setLoggedInUser(user);
    context.read<UserProvider>().pushViewedCustomer(user);

    // Validate ONLY password-login users
    if (user.password.isNotEmpty) {
      try {
        final response = await context.read<ApiRepository>().validateUser({
          'userId': user.id,
          'password': user.password,
        });
        if (response.statusCode == 200) {
          return true;
        }else{
          await SecureStorageHelper.clearAll();
          return false;
        }
      } catch (e) {
        //debugPrint('Validation skipped: $e');
        await SecureStorageHelper.clearAll();
        return false;
      }
    }

    return true;
  }

  /// VERSION CHECK HERE (Safe)
  void checkVersionDialog(BuildContext context) async {
    if (_versionChecked) return; // avoid multiple calls
    _versionChecked = true;

    final newVersion = NewVersionPlus(
      androidId: "com.niagaraautomations.oroDripirrigation",
      iOSId: "com.niagaraautomations.oroDripirrigation",
    );

    final status = await newVersion.getVersionStatus();
        //print("status:${status?.storeVersion},${status?.localVersion},${status?.originalStoreVersion}");
    if (status != null && status.canUpdate) {
      newVersion.showUpdateDialog(
        context: context,
        versionStatus: status,
        dialogTitle: "New Update Available",
        // dialogText:
        // "A new version (${status.storeVersion}) is available.\nPlease update for better performance.",
        updateButtonText: "Update Now",
        dismissButtonText: "Later",
        allowDismissal: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<bool>(
      future: initializeUser(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data != true) {
          return const LoginScreen();
        }

        final userData = context.read<UserProvider>().loggedInUser;

        return UserLayoutSelector(userRole: userData.role);
      },
    );
  }
}
