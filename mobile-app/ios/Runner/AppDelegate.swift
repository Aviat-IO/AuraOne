import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Setup ML Kit GenAI channel
    let controller = window?.rootViewController as! FlutterViewController
    let mlkitChannel = FlutterMethodChannel(
      name: "com.auraone.mlkit_genai",
      binaryMessenger: controller.binaryMessenger
    )

    mlkitChannel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "checkAvailability":
        // iOS on-device AI APIs not yet implemented
        // Future: Integrate with Apple Intelligence or similar
        result(false)

      case "downloadFeatures":
        result(FlutterError(
          code: "NOT_AVAILABLE",
          message: "iOS on-device AI not yet supported",
          details: nil
        ))

      case "generateSummary":
        result(FlutterError(
          code: "NOT_AVAILABLE",
          message: "iOS on-device AI not yet supported",
          details: nil
        ))

      case "describeImage":
        result(FlutterError(
          code: "NOT_AVAILABLE",
          message: "iOS on-device AI not yet supported",
          details: nil
        ))

      case "rewriteText":
        result(FlutterError(
          code: "NOT_AVAILABLE",
          message: "iOS on-device AI not yet supported",
          details: nil
        ))

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
