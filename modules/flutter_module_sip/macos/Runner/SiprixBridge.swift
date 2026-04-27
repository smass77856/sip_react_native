import Cocoa
import FlutterMacOS
import siprix

// Bridge to expose shared Siprix instance to Flutter
class SiprixBridge {
  static let shared = SiprixBridge()
  
  private init() {}
  
  func getSiprixModule() -> SiprixModule? {
    return SiprixSharedInstance.shared.siprixModule
  }
  
  func isInitialized() -> Bool {
    return SiprixSharedInstance.shared.isInitialized
  }
}
