import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future initialize() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
     });

    FirebaseMessaging.onBackgroundMessage(backgroundHandler);

    // Get the token
    await getToken();
  }

  Future<void> backgroundHandler(RemoteMessage message) async {
    print('Handling a background message ');
  }

  Future<String?> getToken() async {
    String? token = await _fcm.getToken();
    return token;
  }
  Future<void> setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Retrieve the APNS token
    // String? apnsToken = await messaging.getAPNSToken();

    // Retrieve the FCM token
    String? fcmToken = await messaging.getToken();
  }

}





