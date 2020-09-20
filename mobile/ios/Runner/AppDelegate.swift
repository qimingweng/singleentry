import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Flutter registration
    if let registrar = registrar(forPlugin: "Runner") {
      let viewFactory = FlutterUiKitCameraFactory(withRegistrar: registrar);
      registrar.register(viewFactory, withId: "FlutterUiKitCamera")
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
