import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:free_rasp/free_rasp.dart';
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


// Initialize local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background message handler for Firebase
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  //print("Handling a background message: ${message.messageId}");
}

// Permissions request
Future<void> requestAppPermissions() async {
  //debugPrint("Requesting permissions...");

  // Notifications (iOS + Android 13+)
  final notifStatus = await Permission.notification.request();
  //debugPrint("Notification permission: $notifStatus");

  if (Platform.isAndroid) {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse, // better than generic .location
    ].request();

    //debugPrint("BLE + Location permissions: $statuses");

    // Handle permanently denied
    if (notifStatus.isPermanentlyDenied ||
        statuses.values.any((s) => s.isPermanentlyDenied)) {
      await openAppSettings();
    }
  }
}

Future<void> initSecurityChecks() async {
  if (kIsWeb) return;

  // Jailbreak Detection
  bool jailbroken = await FlutterJailbreakDetection.jailbroken;
  if (jailbroken) {
    // Handle jailbroken device (e.g., exit app or show warning)
    if (Platform.isIOS) {
       exit(0);
    }
  }

  // Screen Protection
  await ScreenProtector.preventScreenshotOn();
  await ScreenProtector.protectDataLeakageWithBlur();

  // RASP Implementation (Talsec/Free RASP)
  final config = TalsecConfig(
    androidConfig: AndroidConfig(
      packageName: 'com.niagaraautomations.oroDripirrigation', // Update as per flavor if needed
      signingCertHashes: ['YOUR_SIGNING_CERT_HASH'],
    ),
    iosConfig: IOSConfig(
      bundleIds: ['com.niagaraautomations.oroDripirrigation'],
      teamId: 'YOUR_TEAM_ID',
    ),
    watcherMail: 'security@niagaraautomation.com',
  );

  final callback = TalsecCallback(
    onControlFlowTamper: () => exit(0),
    onDebugger: () => exit(0),
    onEmulator: () => exit(0),
    onJailbreak: () => exit(0),
    onDeviceBindingTamper: () => exit(0),
    onHook: () => exit(0),
    onUntrustedInstallationSource: () => exit(0),
  );

  Talsec.instance.attachCallback(callback);
  await Talsec.instance.start(config);
}

FutureOr<void> main() async {

  FlutterError.onError = (FlutterErrorDetails details) {
    // debugPrint('Flutter Error: ${details.exception}');
    // Don't crash, just log
  };

  WidgetsFlutterBinding.ensureInitialized();

  await initSecurityChecks();

  tz.initializeTimeZones();
  F.appFlavor = Flavor.smartComm;
  await NetworkUtils.initialize();
  // await dotenv.load(fileName: ".env.apikey");

  // Request runtime permissions before providers start
  if (!kIsWeb && Platform.isAndroid) {
    await requestAppPermissions();
  }
  // Firebase init
  if (!kIsWeb) {
    // Firebase init
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // Firebase Messaging
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    const initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true);
    // Local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
        android: androidInit, iOS: initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(initSettings);


    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        //debugPrint("Notification tapped: ${details.payload}");
      },
    );


    // Background messaging
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        NotificationService().showNotification(
          title: message.notification!.title,
          body: message.notification!.body,
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      //debugPrint("Message clicked: ${message.messageId}");
    });
  }

  runZonedGuarded(() {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => CustomerProvider()),
          ChangeNotifierProvider(create: (_) => ConfigMakerProvider()),
          ChangeNotifierProvider(create: (_) => IrrigationProgramMainProvider()),
          ChangeNotifierProvider(create: (_) => MqttPayloadProvider()),
          ChangeNotifierProvider(create: (_) => OverAllUse()),
          ChangeNotifierProvider(create: (_) => PreferenceProvider()),
          ChangeNotifierProvider(create: (_) => SystemDefinitionProvider()),
          ChangeNotifierProvider(create: (_) => ConstantProvider()),
          ChangeNotifierProvider(create: (_) => PumpControllerProvider()),
          ChangeNotifierProvider(create: (_) => BleProvider()),
          ChangeNotifierProvider(create: (_) => SearchProvider()),
          ChangeNotifierProvider(create: (_) => ButtonLoadingProvider()),
          ProxyProvider2<MqttPayloadProvider, CustomerProvider, CommunicationService>(
            update: (BuildContext context, MqttPayloadProvider mqttProvider,
                CustomerProvider customer, CommunicationService? previous) {
              return CommunicationService(
                mqttService: MqttService(),
                blueService: BluetoothClassicService(),
                bleService: BluetoothBleService(),
                customerProvider: customer,
              );
            },
          ),
          Provider<HttpService>(create: (_) => HttpService()),
          Provider<ApiRepository>(create: (context) =>
              RepositoryImpl(context.read<HttpService>()),
          ),
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    // debugPrint('Zone Error: $error');
    // Handle errors gracefully
  });



}