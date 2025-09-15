import Flutter
import UIKit
import GoogleMaps
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback)
    } catch {
      print("Failed to set audio session category: \(error)")
    }
    do {
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("Failed to activate audio session: \(error)")
    }
    application.beginReceivingRemoteControlEvents()
    GMSServices.provideAPIKey("AIzaSyCWGXrDv1nBR5YWb4M2OTFcmwbPX7carIM")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
