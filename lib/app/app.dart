import'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oro_drip_irrigation/Constants/notifications_service.dart';
import 'package:oro_drip_irrigation/utils/Theme/agritel_theme.dart';
import '../Screens/login_screenOTP/login_screenotp.dart';
import '../flavors.dart';
import '../security/device_security.dart';
import '../utils/Theme/smart_comm_theme.dart';
import '../utils/Theme/oro_theme.dart';
import '../utils/routes.dart';
import '../utils/secure_storage_helper.dart';
import '../views/common/login/login_screen.dart';
import '../views/screen_controller.dart';
import '../views/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {

  bool _showPrivacyOverlay = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    if (DeviceSecurity.isRooted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = navigatorKey.currentContext; // or your root context
        if (context != null) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 36),
              title: const Text('Security Notice'),
              content: const Text(
                'This device appears to be rooted. Some features like login, '
                    'report export, and threshold changes are disabled.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      });
    }

     if(!kIsWeb){
      NotificationServiceCall().initialize();
      NotificationServiceCall().configureFirebaseMessaging();
     }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // Show privacy overlay before iOS takes the app-switcher snapshot
      setState(() => _showPrivacyOverlay = true);
    } else if (state == AppLifecycleState.resumed) {
      setState(() => _showPrivacyOverlay = false);
    }
  }


    /// Decide the initial route based on whether a token exists
  Future<String> getInitialRoute() async {
    try {
      final token = await SecureStorageHelper.getToken();
      if (token != null && token.trim().isNotEmpty) {
        return Routes.dashboard;
      } else {
        return Routes.login;
      }
    } catch (e) {
      print("Error in getInitialRoute: $e");
      return Routes.login;
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return FutureBuilder<String>(
      future: getInitialRoute(),
      builder: (context, snapshot) {
        var isOro = F.appFlavor?.name.contains('oro') ?? false;
        var isATel = F.appFlavor?.name.contains('agritel') ?? false;

        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: isOro ? OroTheme.lightTheme : isATel ? ATelTheme.lightTheme :
          SmartCommTheme.lightTheme,
          darkTheme: isOro ? OroTheme.darkTheme : isATel ? ATelTheme.darkTheme :
          SmartCommTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: navigateToInitialScreen(snapshot.data ?? Routes.login),
          onGenerateRoute: Routes.generateRoute,
          // Wraps EVERY screen in the app, including ones reached via
          // onGenerateRoute, with the privacy overlay
          builder: (context, child) {
            return Stack(
              children: [
                if (child != null) child,
                if (_showPrivacyOverlay)
                  Positioned.fill(
                    child: Container(
                      color: Theme.of(context).primaryColor,
                      child: Center(
                        child: F.appFlavor!.name.contains('oro') ? Image.asset("assets/png/oro_logo_white.png"):
                        Image.asset("assets/png/company_logo.png"),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  /*@override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return FutureBuilder<String>(
      future: getInitialRoute(),
      builder: (context, snapshot) {

        var isOro = F.appFlavor?.name.contains('oro') ?? false;
        var isATel = F.appFlavor?.name.contains('agritel') ?? false;

        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: isOro ? OroTheme.lightTheme : isATel ? ATelTheme.lightTheme :
          SmartCommTheme.lightTheme,
          darkTheme: isOro ? OroTheme.darkTheme : isATel ? ATelTheme.darkTheme :
          SmartCommTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: navigateToInitialScreen(snapshot.data ?? Routes.login),
          onGenerateRoute: Routes.generateRoute,
        );
      },
    );
  }*/
}

/// Helper function to navigate to the appropriate screen
Widget navigateToInitialScreen(String route) {
  final isOro = F.appFlavor!.name.contains('oro');

  switch (route) {
    case Routes.login:
      return kIsWeb ? const LoginScreen() : isOro ? LoginScreenOTP() : const LoginScreen();
    case Routes.dashboard:
      return const ScreenController();
    default:
      return const SplashScreen();
  }
}