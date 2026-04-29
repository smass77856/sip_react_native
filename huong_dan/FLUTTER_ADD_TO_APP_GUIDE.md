# 🚀 Hướng dẫn: Tích hợp Flutter Module vào React Native (Add-to-App)

> **Mục tiêu**: Chạy một màn hình Flutter bên trong ứng dụng React Native (Expo) dưới dạng **1 App duy nhất** — người dùng chỉ cần cài một ứng dụng.

---

## 📋 Mục lục

1. [Kiến trúc tổng quan](#1-kiến-trúc-tổng-quan)
2. [Chuẩn bị Flutter Module](#2-chuẩn-bị-flutter-module)
3. [Cấu hình iOS (CocoaPods)](#3-cấu-hình-ios-cocoapods)
4. [Cấu hình Android (Gradle)](#4-cấu-hình-android-gradle)
5. [Viết Native Bridge — iOS (Swift)](#5-viết-native-bridge--ios-swift)
6. [Viết Native Bridge — Android (Kotlin)](#6-viết-native-bridge--android-kotlin)
7. [Gọi từ React Native (TypeScript)](#7-gọi-từ-react-native-typescript)
8. [Flutter nhận route và hiển thị](#8-flutter-nhận-route-và-hiển-thị)
9. [Xử lý lỗi CocoaPods Firebase](#9-xử-lý-lỗi-cocoapods-firebase)
10. [Luồng hoạt động tổng thể](#10-luồng-hoạt-động-tổng-thể)

---

## 1. Kiến trúc tổng quan

```
┌─────────────────────────────────────────────┐
│             React Native App (Expo)         │
│                                             │
│  [Dial Screen] → handleCall()               │
│         ↓                                   │
│  NativeModules.SiprixBridge                 │
│         ↓                                   │
│  ┌──────────────────────────────────────┐   │
│  │         Native Bridge Layer          │   │
│  │  iOS: SiprixBridge.swift             │   │
│  │  Android: SiprixBridge.kt            │   │
│  └──────────────────────────────────────┘   │
│         ↓                                   │
│  ┌──────────────────────────────────────┐   │
│  │         Flutter Engine               │   │
│  │  iOS: FlutterViewController          │   │
│  │  Android: FlutterActivity            │   │
│  └──────────────────────────────────────┘   │
│         ↓                                   │
│  [Flutter UI - SIP Call Screen]             │
└─────────────────────────────────────────────┘
```

---

## 2. Chuẩn bị Flutter Module

### Bước 1: Đảm bảo project Flutter là dạng `module`

Kiểm tra file `.metadata`:
```yaml
# modules/flutter_module_sip/.metadata
project_type: module   # ← phải là 'module', không phải 'app'
```

### Bước 2: Thêm block `module:` vào `pubspec.yaml`

```yaml
# modules/flutter_module_sip/pubspec.yaml
flutter:
  uses-material-design: true

  module:
    androidX: true
    androidPackage: com.siprix.voip_sdk_example    # package Android
    iosBundleIdentifier: com.siprix.voipSdkExample # bundle iOS
```

### Bước 3: Chạy `flutter pub get` để sinh ra `.android/` và `.ios/`

```bash
cd modules/flutter_module_sip
flutter pub get
```

Sau lệnh này, bạn sẽ thấy xuất hiện:
- `.android/include_flutter.groovy` → dùng cho Gradle
- `.ios/Flutter/podhelper.rb` → dùng cho CocoaPods

---

## 3. Cấu hình iOS (CocoaPods)

### File: `ios/Podfile`

```ruby
require File.join(File.dirname(`node --print "require.resolve('expo/package.json')"`), "scripts/autolinking")
require File.join(File.dirname(`node --print "require.resolve('react-native/package.json')"`), "scripts/react_native_pods")

require 'json'
podfile_properties = JSON.parse(File.read(File.join(__dir__, 'Podfile.properties.json'))) rescue {}

# 1. Khai báo đường dẫn tới Flutter module
flutter_application_path = '../modules/flutter_module_sip'

# 2. Load công cụ build của Flutter
load File.join(flutter_application_path, '.ios', 'Flutter', 'podhelper.rb')

platform :ios, podfile_properties['ios.deploymentTarget'] || '15.1'
prepare_react_native_project!

target 'siprixreactnt' do
  use_expo_modules!

  config = use_native_modules!(...)

  # 3. Cài đặt tất cả Flutter pods (flutter engine + plugins)
  install_all_flutter_pods(flutter_application_path)

  # 4. Fix lỗi Firebase + Flutter static library conflict
  pod 'GoogleUtilities',      :modular_headers => true
  pod 'FirebaseCore',         :modular_headers => true
  pod 'FirebaseCoreInternal', :modular_headers => true
  pod 'FirebaseInstallations', :modular_headers => true
  pod 'FirebaseMessaging',    :modular_headers => true
  pod 'GoogleDataTransport',  :modular_headers => true
  pod 'nanopb',               :modular_headers => true

  use_react_native!(...)

  post_install do |installer|
    react_native_post_install(installer, ...)
    # 5. Chạy post install script của Flutter
    flutter_post_install(installer) if defined?(flutter_post_install)
  end
end
```

> **Lý do cần `modular_headers`**: Khi Flutter mang Firebase vào dưới dạng static library, Xcode yêu cầu các pods phụ thuộc (`GoogleUtilities`, `FirebaseMessaging`...) phải có module maps mới import được từ Swift. Không khai báo sẽ gặp lỗi `Module 'FirebaseMessaging' not found`.

---

## 4. Cấu hình Android (Gradle)

### File: `android/settings.gradle`

```groovy
// ... (existing code) ...

include ':app'
includeBuild(expoAutolinking.reactNativeGradlePlugin)

// Load Flutter module generated settings (an toàn khi module chưa copy)
def flutterInclude = new File(settingsDir.getParentFile(), "modules/flutter_module_sip/.android/include_flutter.groovy")
if (flutterInclude.exists()) {
  setBinding(new Binding([gradle: this]))
  evaluate(flutterInclude)
}
```

### File: `android/app/build.gradle`

```groovy
android {
  compileOptions {
    sourceCompatibility JavaVersion.VERSION_17
    targetCompatibility JavaVersion.VERSION_17
    coreLibraryDesugaringEnabled true
  }
}

dependencies {
  implementation("com.facebook.react:react-android")

  // Flutter module
  implementation project(':flutter')

  // Bắt buộc cho một số Flutter plugins (vd: flutter_local_notifications)
  coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
```

### File: `android/app/src/main/AndroidManifest.xml`

```xml
<application ...>
  <activity
    android:name="io.flutter.embedding.android.FlutterActivity"
    android:exported="false"
    android:theme="@style/AppTheme"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    android:hardwareAccelerated="true"
    android:windowSoftInputMode="adjustResize" />
</application>
```

> Nếu thiếu khai báo này, khi bấm call sẽ lỗi: `ActivityNotFoundException ... io.flutter.embedding.android.FlutterActivity`.

---

## 5. Viết Native Bridge — iOS (Swift)

### File: `ios/siprixreactnt/AppDelegate.swift`

Khởi tạo `FlutterEngine` **một lần duy nhất** khi app khởi động. Điều này giúp Flutter load nhanh khi được gọi, không bị delay.

```swift
import Expo
import React
import ReactAppDependencyProvider
import Flutter
import FlutterPluginRegistrant   // ← quan trọng: đăng ký Flutter plugins

@UIApplicationMain
public class AppDelegate: ExpoAppDelegate {
  var window: UIWindow?
  var flutterEngine: FlutterEngine?   // ← giữ engine trong suốt vòng đời app

  public override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    // Khởi tạo Flutter Engine
    flutterEngine = FlutterEngine(name: "siprix flutter engine")
    flutterEngine?.run()
    if let engine = flutterEngine {
        GeneratedPluginRegistrant.register(with: engine)
    }

    // ... (Expo/RN setup code) ...
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### File: `ios/siprixreactnt/SiprixBridge.swift`

```swift
import Foundation
import UIKit
import React
import Flutter   // ← bắt buộc để dùng FlutterViewController

@objc(SiprixBridge)
class SiprixBridge: NSObject {

  @objc(openSiprixCall:username:password:)
  func openSiprixCall(_ phone: String, username: String, password: String) {
    DispatchQueue.main.async { [weak self] in
      let appDelegate = UIApplication.shared.delegate as? AppDelegate
      let flutterEngine = appDelegate?.flutterEngine
      
      if let engine = flutterEngine {
        // Điều hướng Flutter tới đúng màn hình
        engine.navigationChannel.invokeMethod("pushRoute", arguments: "/call_screen?phone=\(phone)")
        
        // Present Flutter ViewController lên trên RN
        let flutterViewController = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
        let rootViewController = UIApplication.shared.keyWindow?.rootViewController
        rootViewController?.present(flutterViewController, animated: true, completion: nil)
      } else {
        // Fallback: mở bằng Deep Link nếu engine chưa sẵn sàng
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
```

### File: `ios/siprixreactnt/SiprixBridge.m`

File Objective-C bắt buộc để React Native nhận diện Swift module:

```objc
#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(SiprixBridge, NSObject)

RCT_EXTERN_METHOD(openSiprixCall:(NSString *)phone
                  username:(NSString *)username
                  password:(NSString *)password)

@end
```

> **Quan trọng**: Cả `SiprixBridge.swift` và `SiprixBridge.m` phải được **thêm vào Xcode project** (`project.pbxproj`). Nếu chỉ tạo file trong thư mục mà không thêm vào project, Xcode sẽ bỏ qua hoàn toàn.

---

## 6. Viết Native Bridge — Android (Kotlin)

### File: `android/app/.../SiprixBridge.kt`

```kotlin
package com.anonymous.siprixreactnt

import android.net.Uri
import android.util.Log
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import io.flutter.embedding.android.FlutterActivity

class SiprixBridge(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {

    override fun getName(): String = "SiprixBridge"

    @ReactMethod
    fun openSiprixCall(phoneNumber: String, username: String, pass: String, promise: Promise) {
        val activity = reactApplicationContext.currentActivity
        if (activity == null) {
            promise.reject("NO_ACTIVITY", "Current activity is null")
            return
        }

        try {
            val encodedPhone = Uri.encode(phoneNumber)
            val encodedUser = Uri.encode(username)
            val initialRoute = "/call?phone=$encodedPhone&user=$encodedUser"

            val intent = FlutterActivity
                .withNewEngine()
                .initialRoute(initialRoute)
                .build(activity)

            activity.startActivity(intent)
            promise.resolve("presented")
        } catch (e: Exception) {
            Log.e("SiprixBridge", "Failed to open Flutter screen: ${e.message}", e)
            promise.reject("OPEN_CALL_FAILED", e.message, e)
        }
    }
}
```

### File: `android/app/.../SiprixBridgePackage.kt`

```kotlin
package com.anonymous.siprixreactnt

import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager

class SiprixBridgePackage : ReactPackage {
    override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> {
        return listOf(SiprixBridge(reactContext))
    }
    override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
        return emptyList()
    }
}
```

### File: `android/app/.../MainApplication.kt`

```kotlin
override fun getPackages(): List<ReactPackage> =
    PackageList(this).packages.apply {
        add(SiprixBridgePackage())   // ← đăng ký package mới
    }
```

---

## 7. Gọi từ React Native (TypeScript)

### File: `app/(tabs)/index.tsx`

```typescript
import { NativeModules } from 'react-native';

const handleCall = () => {
  if (!phoneNumber) return;
  
  const { SiprixBridge } = NativeModules;
  if (SiprixBridge) {
    // Gọi native method — iOS sẽ present FlutterViewController
    //                    — Android sẽ start FlutterActivity
    SiprixBridge.openSiprixCall(phoneNumber, 'username', 'password');
  } else {
    console.warn('SiprixBridge module not found');
  }
};
```

> **Lưu ý**: Không dùng `import('react-native')` (dynamic import). Luôn dùng static import ở đầu file để tránh crash với React Native New Architecture.

---

## 8. Flutter nhận route và hiển thị

### File: `modules/flutter_module_sip/lib/main.dart`

```dart
@override
Widget build(BuildContext context) {
  final defaultRouteName = WidgetsBinding.instance.platformDispatcher.defaultRouteName;

  return MaterialApp(
    initialRoute: defaultRouteName != '/' ? defaultRouteName : null,
    onGenerateRoute: (settings) {
      final uri = Uri.parse(settings.name ?? '/');

      if (uri.path == '/call') {
        final phone = uri.queryParameters['phone'];
        final user = uri.queryParameters['user'];
        return MaterialPageRoute(
          builder: (_) => CallAddPage(true),
          settings: settings,
        );
      }

      return MaterialPageRoute(builder: (_) => const HomePage(), settings: settings);
    },
    home: const HomePage(),
  );
}
```

---

## 9. Xử lý lỗi CocoaPods Firebase

Khi tích hợp Flutter module có Firebase vào React Native (static library), bạn sẽ gặp các lỗi sau và cách fix:

| Lỗi | Nguyên nhân | Fix |
|---|---|---|
| `The Swift pod FirebaseCoreInternal depends upon GoogleUtilities, which does not define modules` | Firebase Swift pod cần module maps | `pod 'GoogleUtilities', :modular_headers => true` |
| `Module 'FirebaseMessaging' not found` | Static library không thể import Firebase | Thêm `modular_headers => true` cho tất cả Firebase pods |
| `no such module 'Flutter'` | File Swift chưa import Flutter | Thêm `import Flutter` + chạy `pod install` trước khi build |
| `cannot find 'FlutterViewController' in scope` | Thiếu `import Flutter` trong Bridge file | Thêm `import Flutter` vào `SiprixBridge.swift` |

---

## 10. Luồng hoạt động tổng thể

```
User bấm "Make Call" trên React Native
        ↓
handleCall() trong index.tsx
        ↓
NativeModules.SiprixBridge.openSiprixCall(phone, user, pass)
        ↓
[iOS]                              [Android]
SiprixBridge.swift                 SiprixBridge.kt
        ↓                                  ↓
engine.navigationChannel           FlutterActivity.withNewEngine()
.invokeMethod("pushRoute",         .initialRoute("/call?phone=...&user=...")
"/call_screen?phone=...")          .build(activity)
        ↓                                  ↓
FlutterViewController              FlutterActivity
.present(animated: true)           .startActivity(intent)
        ↓                                  ↓
Flutter app khởi động với route "/call?phone=...&user=..."
        ↓
onGenerateRoute -> Uri.parse(route).path == '/call'
        ↓
Giao diện SIP Call hiện ra!
```

---

## 📁 Cấu trúc file quan trọng

```
siprix-react-nt/
├── app/(tabs)/index.tsx              # RN: gọi NativeModules.SiprixBridge
│
├── ios/
│   ├── Podfile                       # iOS: cấu hình Flutter + Firebase pods
│   └── siprixreactnt/
│       ├── AppDelegate.swift         # iOS: khởi tạo FlutterEngine
│       ├── SiprixBridge.swift        # iOS: Native Module Swift
│       └── SiprixBridge.m            # iOS: Obj-C bridge để RN nhận diện
│
├── android/
│   ├── settings.gradle               # Android: include Flutter module
│   └── app/
│       ├── build.gradle              # Android: implementation project(':flutter')
│       └── src/main/java/.../
│           ├── SiprixBridge.kt       # Android: Native Module Kotlin
│           ├── SiprixBridgePackage.kt # Android: Package registration
│           └── MainApplication.kt    # Android: add(SiprixBridgePackage())
│
└── modules/
    └── flutter_module_sip/
        ├── .metadata                 # Flutter: project_type: module
        ├── pubspec.yaml              # Flutter: module block
        ├── .ios/Flutter/podhelper.rb # Flutter: sinh ra sau flutter pub get
        ├── .android/include_flutter.groovy # Flutter: sinh ra sau flutter pub get
        └── lib/main.dart             # Flutter: xử lý initialRoute
```

---

## ⚡️ Lệnh build

```bash
# 1) Đồng bộ Flutter module (sau khi đổi pubspec)
cd modules/flutter_module_sip && flutter pub get && cd ../..

# 2) iOS
cd ios && pod install && cd ..
npx expo run:ios

# 3) Android
npx expo run:android
```

> Nếu Android báo lỗi cache Gradle cũ, chạy thêm: `cd android && ./gradlew clean && cd ..` rồi build lại.
