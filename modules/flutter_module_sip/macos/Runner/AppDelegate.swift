import Cocoa
import FlutterMacOS
import siprix
import UserNotifications
// Note: Firebase is not used on macOS - local notifications only

// Singleton to share Siprix instance between AppDelegate and Flutter plugin
class SiprixSharedInstance {
  static let shared = SiprixSharedInstance()
  var siprixModule: SiprixModule?
  var isInitialized = false
  
  private init() {}
}

// Empty delegate to satisfy Siprix SDK requirements
class EmptySiprixDelegate: NSObject, SiprixEventDelegate {
  func onTrialModeNotified() {}
  func onDevicesAudioChanged() {}
  func onAccountRegState(_ accId: Int, regState: RegState, response: String) {}
  func onNetworkState(_ name: String, netState: NetworkState) {}
  func onPlayerState(_ playerId: Int, playerState: PlayerState) {}
  func onRingerState(_ started: Bool) {}
  func onCallProceeding(_ callId: Int, response: String) {}
  func onCallTerminated(_ callId: Int, statusCode: Int) {}
  func onCallConnected(_ callId: Int, hdrFrom: String, hdrTo: String, withVideo: Bool) {}
  func onCallIncoming(_ callId: Int, accId: Int, withVideo: Bool, hdrFrom: String, hdrTo: String) {}
  func onCallDtmfReceived(_ callId: Int, tone: Int) {}
  func onCallSwitched(_ callId: Int) {}
  func onCallTransferred(_ callId: Int, statusCode: Int) {}
  func onCallRedirected(_ origCallId: Int, relatedCallId: Int, referTo: String) {}
  func onCallHeld(_ callId: Int, holdState: HoldState) {}
  func onCallVideoUpgraded(_ callId: Int, withVideo: Bool) {}
  func onCallVideoUpgradeRequested(_ callId: Int) {}
  func onSubscriptionState(_ subscrId: Int, subscrState: SubscrState, response: String) {}
  func onMessageSentState(_ messageId: Int, success: Bool, response: String) {}
  func onMessageIncoming(_ messageId: Int, accId: Int, hdrFrom: String, body: String) {}
  func onSipNotify(_ subscrId: Int, hdrEvent: String, body: String) {}
  func onVuMeterLevel(_ micLevel: Int, spkLevel: Int) {}
}

@NSApplicationMain
class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate {
  private var siprixDelegate: EmptySiprixDelegate?
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    NSLog("🔵 AppDelegate.applicationDidFinishLaunching called")
    super.applicationDidFinishLaunching(notification)
    
    // NOTE: Firebase/FCM is NOT supported on macOS
    // We use local notifications instead
    
    // Set notification center delegate
    UNUserNotificationCenter.current().delegate = self
    
    // Request notification permissions for local notifications
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      if let error = error {
        NSLog("❌ Notification permission error: \(error.localizedDescription)")
      } else {
        NSLog("✅ Notification permission granted: \(granted)")
      }
    }
    
    NSLog("🔵 AppDelegate ready, Flutter will initialize Siprix")
  }
  
  // Handle notification tap when app is in foreground or background
  func userNotificationCenter(_ center: UNUserNotificationCenter, 
                             didReceive response: UNNotificationResponse, 
                             withCompletionHandler completionHandler: @escaping () -> Void) {
    NSLog("🔔 Notification tapped: \(response.notification.request.identifier)")
    
    // Bring app to foreground
    NSApplication.shared.activate(ignoringOtherApps: true)
    
    // Bring all windows to front
    for window in NSApplication.shared.windows {
      window.makeKeyAndOrderFront(nil)
    }
    
    completionHandler()
  }
  
  // Show notification even when app is in foreground
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                             willPresent notification: UNNotification,
                             withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    NSLog("📬 Notification received while app in foreground")
    // Show notification even when app is active
    if #available(macOS 11.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      // For macOS 10.15, use .alert instead of .banner
      completionHandler([.alert, .sound, .badge])
    }
  }
  
  private func initializeSiprixSDK() {
    let sharedInstance = SiprixSharedInstance.shared
    
    guard !sharedInstance.isInitialized else {
      NSLog("Siprix already initialized, skipping")
      return
    }
    
    NSLog("=== Starting Siprix SDK initialization ===")
    
    // Get documents directory for log files
    guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      NSLog("ERROR: Could not get documents directory")
      return
    }
    
    let homeFolder = documentsURL.path + "/"
    NSLog("Siprix homeFolder: \(homeFolder)")
    
    // Create Siprix module instance and delegate (store in singleton)
    sharedInstance.siprixModule = SiprixModule()
    siprixDelegate = EmptySiprixDelegate()
    
    // Set initialization parameters
    let iniData = SiprixIniData()
    iniData.license = "LicensedTo[Internation_Distribution_Corporation]_Platforms[WIN_ANDR_IOS_OSX_LIN]_Features[V_MC_MA_MSG]_SupportTill[20260719]_UpdatesTill[20260719]_Key[MC0CFFkvOliKHLf/W7rkgasgYkDEs88pAhUAwpIH1r8ECvWm9HgnESfX8yCBweA=]"
    iniData.homeFolder = homeFolder
    iniData.singleCallMode = NSNumber(value: false)
    iniData.logLevelIde = NSNumber(value: LogLevel.debug.rawValue)
    iniData.logLevelFile = NSNumber(value: LogLevel.info.rawValue)
    iniData.tlsVerifyServer = NSNumber(value: false)
    
    NSLog("Calling siprixModule.initialize()...")
    
    // Initialize SDK with empty delegate
    guard let delegate = siprixDelegate else {
      NSLog("ERROR: Could not create delegate")
      return
    }
    let errCode = sharedInstance.siprixModule?.initialize(delegate, iniData: iniData) ?? -1
    
    NSLog("siprixModule.initialize() returned: \(errCode)")
    
    if errCode == kErrorCodeEOK {
      sharedInstance.isInitialized = true
      if let version = sharedInstance.siprixModule?.version() {
        NSLog("✓ Siprix SDK initialized successfully. Version: \(version)")
      }
    } else {
      let errorText = sharedInstance.siprixModule?.getErrorText(errCode) ?? "Unknown error"
      NSLog("✗ Siprix SDK initialization failed with code: \(errCode) - \(errorText)")
    }
  }
  
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false // Keep app running when last window is closed
  }

  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
      for window in sender.windows {
        window.makeKeyAndOrderFront(self)
      }
    }
    return true
  }

  override func applicationWillTerminate(_ notification: Notification) {
    // Uninitialize Siprix SDK when app terminates
    let sharedInstance = SiprixSharedInstance.shared
    if sharedInstance.isInitialized {
      NSLog("Uninitializing Siprix SDK...")
      sharedInstance.siprixModule?.unInitialize()
      sharedInstance.isInitialized = false
    }
  }
  
  // Note: Remote notifications (APNs/FCM) are not supported on macOS
  // We use local notifications only
  
  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
