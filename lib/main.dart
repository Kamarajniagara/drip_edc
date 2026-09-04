import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager_plus/flutter_windowmanager_plus.dart';

import 'package:oro_drip_irrigation/modules/PumpController/state_management/pump_controller_provider.dart';
import 'package:oro_drip_irrigation/modules/bluetooth_low_energy/state_management/ble_service.dart';
import 'package:oro_drip_irrigation/providers/button_loading_provider.dart';
import 'package:oro_drip_irrigation/providers/user_provider.dart';
import 'package:oro_drip_irrigation/repository/repository.dart';
import 'package:oro_drip_irrigation/services/bluetooth/bluetooth_ble_service.dart';
import 'package:oro_drip_irrigation/services/bluetooth/bluetooth_classic_service.dart';
import 'package:oro_drip_irrigation/services/communication_service.dart';
import 'package:oro_drip_irrigation/services/http_service.dart';
import 'package:oro_drip_irrigation/services/mqtt_service.dart';
import 'package:oro_drip_irrigation/utils/network_utils.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:screen_security/screen_security.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'Constants/notifi_service.dart';
import 'StateManagement/search_provider.dart';
import 'app/app.dart';
import 'StateManagement/customer_provider.dart';
import 'firebase_options.dart';

import 'flavors.dart';
import 'modules/IrrigationProgram/state_management/irrigation_program_provider.dart';
import 'modules/Preferences/state_management/preference_provider.dart';
import 'modules/SystemDefinitions/state_management/system_definition_provider.dart';
import 'modules/config_maker/state_management/config_maker_provider.dart';
import 'StateManagement/mqtt_payload_provider.dart';
import 'StateManagement/overall_use.dart';
import 'modules/constant/state_management/constant_provider.dart';



// ============================================================
// GLOBAL VARIABLES
// ============================================================

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey =
GlobalKey<NavigatorState>();


// ============================================================
// PLATFORM HELPER
// ============================================================

bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;


// ============================================================
// FIREBASE BACKGROUND MESSAGE HANDLER
// ============================================================

Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp();
}


// ============================================================
// REQUEST APP PERMISSIONS
// ============================================================

Future<void> requestAppPermissions() async {
  // Notifications
  final notifStatus = await Permission.notification.request();

  // Android-specific permissions
  if (isAndroid) {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    // Open app settings if permissions are permanently denied
    if (notifStatus.isPermanentlyDenied ||
        statuses.values.any(
              (status) => status.isPermanentlyDenied,
        )) {
      await openAppSettings();
    }
  }
}


// ============================================================
// ENABLE SECURE SCREEN
// ============================================================
//
// FLAG_SECURE is Android-specific.
// It prevents screenshots / screen recording on Android.
//
// IMPORTANT:
// flutter_windowmanager is NOT called on Flutter Web.
//

Future<void> enableSecureScreen() async {
  if (!isAndroid) {
    return;
  }

  await FlutterWindowManagerPlus.addFlags(
    FlutterWindowManagerPlus.FLAG_SECURE,
  );
}


// ============================================================
// FIREBASE + NOTIFICATION INITIALIZATION
// ============================================================

Future<void> initializeFirebaseAndNotifications() async {
  // Firebase and notification plugins are not initialized on Web.
  if (kIsWeb) {
    return;
  }

  // ----------------------------------------------------------
  // Firebase
  // ----------------------------------------------------------

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ----------------------------------------------------------
  // Firebase Messaging
  // ----------------------------------------------------------

  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // ----------------------------------------------------------
  // iOS Notification Settings
  // ----------------------------------------------------------

  const DarwinInitializationSettings initializationSettingsIOS =
  DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  // ----------------------------------------------------------
  // Android Notification Settings
  // ----------------------------------------------------------

  const AndroidInitializationSettings androidInit =
  AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );

  // ----------------------------------------------------------
  // Combined Notification Settings
  // ----------------------------------------------------------

  const InitializationSettings initSettings =
  InitializationSettings(
    android: androidInit,
    iOS: initializationSettingsIOS,
  );

  // ----------------------------------------------------------
  // Local Notifications Initialization
  // ----------------------------------------------------------

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (details) {
      // Handle notification click if required.
    },
  );

  // ----------------------------------------------------------
  // Firebase Background Messaging
  // ----------------------------------------------------------

  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  // ----------------------------------------------------------
  // Firebase Foreground Messaging
  // ----------------------------------------------------------

  FirebaseMessaging.onMessage.listen(
        (RemoteMessage message) {
      if (message.notification != null) {
        NotificationService().showNotification(
          title: message.notification!.title,
          body: message.notification!.body,
        );
      }
    },
  );

  // ----------------------------------------------------------
  // Firebase Notification Opened App
  // ----------------------------------------------------------

  FirebaseMessaging.onMessageOpenedApp.listen(
        (RemoteMessage message) {
      // Handle notification navigation if required.
    },
  );
}


// ============================================================
// MAIN
// ============================================================

Future<void> main() async {
  runZonedGuarded(
        () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Screen security - skip Web
      if (!kIsWeb) {
        final screenSecurity = ScreenSecurity();
        await screenSecurity.enable();
      }

      FlutterError.onError = (
          FlutterErrorDetails details,
          ) {
        debugPrint(
          'FlutterError: ${details.exception}',
        );
      };

      tz.initializeTimeZones();

      F.appFlavor = Flavor.smartComm;

      await enableSecureScreen();

      if (isAndroid) {
        await requestAppPermissions();
      }

      await NetworkUtils.initialize();

      await initializeFirebaseAndNotifications();

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => UserProvider(),
            ),

            ChangeNotifierProvider(
              create: (_) => CustomerProvider(),
            ),

            ChangeNotifierProvider(
              create: (_) => ConfigMakerProvider(),
            ),

            ChangeNotifierProvider(
              create: (_) =>
                  IrrigationProgramMainProvider(),
            ),

            ChangeNotifierProvider(
              create: (_) => MqttPayloadProvider(),
            ),

            ChangeNotifierProvider(
              create: (_) => OverAllUse(),
            ),

            ChangeNotifierProvider(
              create: (_) => PreferenceProvider(),
            ),

            ChangeNotifierProvider(
              create: (_) =>
                  SystemDefinitionProvider(),
            ),

            ChangeNotifierProvider(
              create: (_) => ConstantProvider(),
            ),

            ChangeNotifierProvider(
              create: (_) =>
                  PumpControllerProvider(),
            ),

            ChangeNotifierProvider(
              create: (_) => BleProvider(),
            ),

            ChangeNotifierProvider(
              create: (_) => SearchProvider(),
            ),

            ChangeNotifierProvider(
              create: (_) => ButtonLoadingProvider(),
            ),

            ProxyProvider2<
                MqttPayloadProvider,
                CustomerProvider,
                CommunicationService>(
              update: (
                  BuildContext context,
                  MqttPayloadProvider mqttProvider,
                  CustomerProvider customer,
                  CommunicationService? previous,
                  ) {
                return CommunicationService(
                  mqttService: MqttService(),
                  blueService:
                  BluetoothClassicService(),
                  bleService:
                  BluetoothBleService(),
                  customerProvider: customer,
                );
              },
            ),

            Provider<HttpService>(
              create: (_) => HttpService(),
            ),

            Provider<ApiRepository>(
              create: (context) =>
                  RepositoryImpl(
                    context.read<HttpService>(),
                  ),
            ),
          ],
          child: const MyApp(),
        ),
      );
    },
        (
        Object error,
        StackTrace stack,
        ) {
      debugPrint(
        'Uncaught error: $error',
      );

      debugPrint(
        'StackTrace: $stack',
      );
    },
  );
}

/*
FutureOr<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

// Enable protection for the entire app from the start

  if (!kIsWeb) {
    final screenSecurity = ScreenSecurity();
    await screenSecurity.enable();
  }


  // ----------------------------------------------------------
  // Flutter Error Handling
  // ----------------------------------------------------------

  FlutterError.onError = (
      FlutterErrorDetails details,
      ) {
    // Don't crash, just log.
    debugPrint(
      'FlutterError: ${details.exception}',
    );
  };

  // ----------------------------------------------------------
  // Initialize Timezone
  // ----------------------------------------------------------

  tz.initializeTimeZones();
  F.appFlavor = Flavor.smartComm;
  // ----------------------------------------------------------
  // Enable Secure Screen
  // ----------------------------------------------------------
  //
  // This is safe for Web because enableSecureScreen()
  // checks isAndroid before accessing flutter_windowmanager.

  await enableSecureScreen();

  // ----------------------------------------------------------
  // Request Permissions
  // ----------------------------------------------------------
  if (isAndroid) {
    await requestAppPermissions();
  }

  // ----------------------------------------------------------
  // Initialize Network Utils
  // ----------------------------------------------------------
  await NetworkUtils.initialize();

  // ----------------------------------------------------------
  // Firebase + Notifications
  // ----------------------------------------------------------
  await initializeFirebaseAndNotifications();

  // ----------------------------------------------------------
  // Run Application
  // ----------------------------------------------------------

  runZonedGuarded(
        () {
      runApp(
        MultiProvider(
          providers: [

            // ------------------------------------------------
            // USER
            // ------------------------------------------------

            ChangeNotifierProvider(
              create: (_) => UserProvider(),
            ),

            // ------------------------------------------------
            // CUSTOMER
            // ------------------------------------------------

            ChangeNotifierProvider(
              create: (_) => CustomerProvider(),
            ),

            // ------------------------------------------------
            // CONFIG MAKER
            // ------------------------------------------------

            ChangeNotifierProvider(
              create: (_) => ConfigMakerProvider(),
            ),

            // ------------------------------------------------
            // IRRIGATION PROGRAM
            // ------------------------------------------------

            ChangeNotifierProvider(
              create: (_) =>
                  IrrigationProgramMainProvider(),
            ),

            // ------------------------------------------------
            // MQTT PAYLOAD
            // ------------------------------------------------

            ChangeNotifierProvider(
              create: (_) => MqttPayloadProvider(),
            ),

            // ------------------------------------------------
            // OVERALL USE
            // ------------------------------------------------

            ChangeNotifierProvider(
              create: (_) => OverAllUse(),
            ),

            // ------------------------------------------------
            // PREFERENCE
            // ------------------------------------------------

            ChangeNotifierProvider(
              create: (_) => PreferenceProvider(),
            ),

            // ------------------------------------------------
            // SYSTEM DEFINITIONS
            // ------------------------------------------------

            ChangeNotifierProvider(
              create: (_) =>
                  SystemDefinitionProvider(),
            ),

            // ------------------------------------------------
            // CONSTANT
            // ------------------------------------------------

            ChangeNotifierProvider(
              create: (_) => ConstantProvider(),
            ),

            // ------------------------------------------------
            // PUMP CONTROLLER
            // ------------------------------------------------

            ChangeNotifierProvider(
              create: (_) =>
                  PumpControllerProvider(),
            ),

            // ------------------------------------------------
            // BLE
            // ------------------------------------------------

            ChangeNotifierProvider(
              create: (_) => BleProvider(),
            ),

            // ------------------------------------------------
            // SEARCH
            // ------------------------------------------------

            ChangeNotifierProvider(
              create: (_) => SearchProvider(),
            ),

            // ------------------------------------------------
            // BUTTON LOADING
            // ------------------------------------------------

            ChangeNotifierProvider(
              create: (_) => ButtonLoadingProvider(),
            ),

            // ------------------------------------------------
            // COMMUNICATION SERVICE
            // ------------------------------------------------

            ProxyProvider2<
                MqttPayloadProvider,
                CustomerProvider,
                CommunicationService>(
              update: (
                  BuildContext context,
                  MqttPayloadProvider mqttProvider,
                  CustomerProvider customer,
                  CommunicationService? previous,
                  ) {
                return CommunicationService(
                  mqttService: MqttService(),
                  blueService: BluetoothClassicService(),
                  bleService: BluetoothBleService(),
                  customerProvider: customer,
                );
              },
            ),

            // ------------------------------------------------
            // HTTP SERVICE
            // ------------------------------------------------

            Provider<HttpService>(
              create: (_) => HttpService(),
            ),

            // ------------------------------------------------
            // API REPOSITORY
            // ------------------------------------------------

            Provider<ApiRepository>(
              create: (context) => RepositoryImpl(
                    context.read<HttpService>(),
                  ),
            ),
          ],

          child: const MyApp(),
        ),
      );
    },
        (
        Object error,
        StackTrace stack,
        ) {
      debugPrint(
        'Uncaught error: $error',
      );

      debugPrint(
        'StackTrace: $stack',
      );
    },
  );
}*/
