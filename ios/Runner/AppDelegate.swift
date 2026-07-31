import UIKit
import Flutter
import flutter_local_notifications
import GoogleMaps
import Firebase
import FirebaseAuth
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if FirebaseApp.app() == nil {
      print("Configuring Firebase")
      FirebaseApp.configure()
    } else {
      print("Firebase already configured")
    }

    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }

    GeneratedPluginRegistrant.register(with: self)
    GMSServices.provideAPIKey("AIzaSyCfMo2V0inDY3xpp91BjfIrD4s-v6PPSzw")

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken // Set APNs token for FCM
      print("apnsToken device token is \(deviceToken)")
  }
 
  override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    Messaging.messaging().appDidReceiveMessage(userInfo) // Handle FCM notifications
    completionHandler(.newData)
  }

  // Security Fix: Prevent sensitive data from appearing in the app switcher snapshot
  override func applicationWillResignActive(_ application: UIApplication) {
    let blurEffect = UIBlurEffect(style: .extraLight)
    let blurEffectView = UIVisualEffectView(effect: blurEffect)
    blurEffectView.frame = window!.frame
    blurEffectView.tag = 221122
    self.window?.addSubview(blurEffectView)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    self.window?.viewWithTag(221122)?.removeFromSuperview()
  }
}
