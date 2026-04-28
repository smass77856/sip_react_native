import Foundation
import UIKit
import React
import Flutter

@objc(SiprixBridge)
class SiprixBridge: NSObject {

  @objc(openSiprixCall:username:password:)
  func openSiprixCall(_ phone: String, username: String, password: String) {
    DispatchQueue.main.async { [weak self] in
      // NOTE: This assumes FlutterEngine is set up in AppDelegate.
      // If it is not set up, we fallback to Deep Linking as a safety net.
      let appDelegate = UIApplication.shared.delegate as? AppDelegate
      let flutterEngine = appDelegate?.flutterEngine
      
      if let engine = flutterEngine {
        engine.navigationChannel.invokeMethod("pushRoute", arguments: "/call_screen?phone=\(phone)")
        let flutterViewController = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
        flutterViewController.modalPresentationStyle = .fullScreen
        let rootViewController = UIApplication.shared.keyWindow?.rootViewController
        rootViewController?.present(flutterViewController, animated: true, completion: nil)
      } else {
          // Fallback to deep link
          if let url = URL(string: "flutter-siprix://call?number=\(phone)") {
              UIApplication.shared.open(url, options: [:], completionHandler: nil)
          }
      }
    }
  }

  @objc static func requiresMainQueueSetup() -> Bool {
    return true
  }
}
