import UIKit
import Flutter
import flutter_local_notifications
import GoogleMaps
import Firebase
import FirebaseAuth
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {

  private var blurView: UIVisualEffectView?

 
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        GeneratedPluginRegistrant.register(with: self)

        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
            GeneratedPluginRegistrant.register(with: registry)
        }

 
        NotificationCenter.default.addObserver(
               self,
               selector: #selector(screenshotTaken),
               name: UIApplication.userDidTakeScreenshotNotification,
               object: nil
           )
        return super.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
    }
    @objc private func screenshotTaken() {
        
     }

  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }
 
  override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    Messaging.messaging().appDidReceiveMessage(userInfo)
    completionHandler(.newData)
  }

  // Finding 6: Background Snapshot Protection
  override func applicationWillResignActive(_ application: UIApplication) {
    let blurEffect = UIBlurEffect(style: .extraLight)
    let blurView = UIVisualEffectView(effect: blurEffect)
    blurView.frame = self.window?.frame ?? UIScreen.main.bounds
    blurView.tag = 221122
    self.window?.addSubview(blurView)
    self.blurView = blurView
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    self.window?.viewWithTag(221122)?.removeFromSuperview()
    self.blurView = nil
  }

  // Finding 4: Handle Screen Recording
    @objc private func screenCaptureChanged() {
        if SecurityUtils.isScreenBeingCaptured() {
            showPrivacyOverlay()
        } else {
            hidePrivacyOverlay()
        }
    }
    
    private func showPrivacyOverlay() {
        guard blurView == nil else { return }

        let blurEffect = UIBlurEffect(style: .systemChromeMaterial)
        let view = UIVisualEffectView(effect: blurEffect)

        view.frame = self.window?.bounds ?? UIScreen.main.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.tag = 221122

        self.window?.addSubview(view)
        self.blurView = view
    }

    private func hidePrivacyOverlay() {
        self.blurView?.removeFromSuperview()
        self.blurView = nil
    }
}
