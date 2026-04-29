import Foundation
import UIKit
import React
import Flutter

@objc(SiprixBridge)
class SiprixBridge: NSObject {

  @objc(openSiprixCall:username:password:resolver:rejecter:)
  func openSiprixCall(
    _ phone: String,
    username: String,
    password: String,
    resolver resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: @escaping RCTPromiseRejectBlock
  ) {
    DispatchQueue.main.async {
      let route = "/call_screen?phone=\(phone)"
      let flutterViewController = FlutterViewController(project: nil, nibName: nil, bundle: nil)
      flutterViewController.setInitialRoute(route)
      flutterViewController.modalPresentationStyle = .fullScreen

      guard let presenter = Self.topViewController() else {
        resolve("no_presenter")
        return
      }

      presenter.present(flutterViewController, animated: true) {
        resolve("presented_project")
      }
    }
  }

  private static func topViewController(base: UIViewController? = nil) -> UIViewController? {
    let root = base ?? UIApplication.shared
      .connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first(where: { $0.isKeyWindow })?
      .rootViewController

    if let nav = root as? UINavigationController {
      return topViewController(base: nav.visibleViewController)
    }

    if let tab = root as? UITabBarController {
      return topViewController(base: tab.selectedViewController)
    }

    if let presented = root?.presentedViewController {
      return topViewController(base: presented)
    }

    return root
  }

  @objc static func requiresMainQueueSetup() -> Bool {
    return true
  }
}
