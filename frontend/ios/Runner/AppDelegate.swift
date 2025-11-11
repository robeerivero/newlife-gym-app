import Flutter
import UIKit
import flutter_local_notifications // <-- SÍ MANTENEMOS ESTE

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // --- Configuración de flutter_local_notifications ---
    // Esto es necesario para que las notificaciones se muestren si la app está en foreground
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    
    // --- Workmanager ELIMINADO ---
    // Hemos quitado las líneas de WorkmanagerPlugin.setPluginRegistrantCallback
    // y registerBGProcessingTask porque nuestro main.dart solo
    // usa workmanager en Android.

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}