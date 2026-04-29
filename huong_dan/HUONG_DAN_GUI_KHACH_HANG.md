# Gói tích hợp Flutter Module vào React Native (gửi khách hàng)

## 1) Nội dung gói đã chuẩn bị
Thư mục gốc: `huong_dan/`

- `FLUTTER_ADD_TO_APP_GUIDE.md` — tài liệu chi tiết kiến trúc + flow tích hợp.
- `source/modules/flutter_module_sip/` — source Flutter module (đã loại bỏ build artifact lớn và file nhạy cảm `.env`).
- `source/ios/Podfile`
- `source/ios/siprixreactnt.xcodeproj/project.pbxproj`
- `source/ios/siprixreactnt/AppDelegate.swift`
- `source/ios/siprixreactnt/SiprixBridge.swift`
- `source/ios/siprixreactnt/SiprixBridge.m`
- `source/android/settings.gradle`
- `source/android/app/src/main/java/com/anonymous/siprixreactnt/MainApplication.kt`
- `source/android/app/src/main/java/com/anonymous/siprixreactnt/SiprixBridge.kt`
- `source/android/app/src/main/java/com/anonymous/siprixreactnt/SiprixBridgePackage.kt`
- `source/app/(tabs)/index.tsx` (ví dụ gọi Native Module từ RN)

---

## 2) Cách tích hợp vào source React Native của khách hàng

### Bước A — Copy Flutter module
1. Copy `source/modules/flutter_module_sip` vào project RN đích tại:
   - `<RN_PROJECT_ROOT>/modules/flutter_module_sip`
2. Trong module Flutter, chạy:
   - `flutter pub get`

### Bước B — Android
1. Merge cấu hình từ `source/android/settings.gradle` vào `android/settings.gradle` của khách hàng:
   - include Flutter Gradle script: `modules/flutter_module_sip/.android/include_flutter.groovy`
   - nên dùng guard `if (flutterInclude.exists()) { ... }` để tránh lỗi khi module chưa copy.
2. `android/app/build.gradle`:
   - thêm `implementation project(':flutter')`
   - bật desugaring trong `compileOptions` (`coreLibraryDesugaringEnabled true`)
   - thêm dependency `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")`
3. `android/app/src/main/AndroidManifest.xml`:
   - khai báo `<activity android:name="io.flutter.embedding.android.FlutterActivity" .../>`
   - nếu thiếu sẽ gặp `ActivityNotFoundException` khi bấm call.
4. Thêm Native Module bridge:
   - `SiprixBridge.kt`
   - `SiprixBridgePackage.kt`
5. Đăng ký package trong `MainApplication.kt`:
   - `add(SiprixBridgePackage())`
6. Sync Gradle và build Android bằng:
   - `npx expo run:android`

### Bước C — iOS
1. Merge cấu hình từ `source/ios/Podfile`:
   - set `flutter_application_path = '../modules/flutter_module_sip'`
   - load `podhelper.rb`
   - gọi `install_all_flutter_pods(flutter_application_path)`
2. Copy bridge iOS:
   - `SiprixBridge.swift`
   - `SiprixBridge.m`
3. Merge logic `FlutterEngine` trong `AppDelegate.swift`.
4. Đối chiếu script build trong `project.pbxproj` (đã có mẫu trong gói) để đảm bảo gọi:
   - `xcode_backend.sh build`
   - `xcode_backend.sh embed_and_thin`
5. Chạy:
   - `cd ios && pod install`
   - Build lại bằng Xcode.

### Bước D — React Native call site
- Dùng `source/app/(tabs)/index.tsx` làm mẫu gọi:
  - `NativeModules.SiprixBridge.openSiprixCall(...)`

---

## 3) Ghi chú quan trọng khi bàn giao
- Gói này **không bao gồm** `modules/flutter_frameworks` (artifact build), vì có thể sinh lại khi build.
- Gói này **không bao gồm** `.env` trong Flutter module để tránh lộ thông tin nhạy cảm.
- Flutter module trong gói đã bỏ `integration_test` khỏi `dev_dependencies` để tránh kéo plugin test vào native Android build.
- Nếu dùng `siprix_voip_sdk_android` qua pub-cache, cần đảm bảo AAR được resolve đúng (`implementation files('libs/siprix_voip_sdk.aar')`) trong môi trường Gradle mới.
- Nếu khách hàng đổi package name/bundle id, cần update tương ứng trong bridge và cấu hình app của họ.
- iOS `SiprixBridge.swift` trong gói đã set `flutterViewController.modalPresentationStyle = .fullScreen` để tránh mở dạng sheet/màn hình đen.
- Flutter `home.dart` trong gói đã dùng `SystemNavigator.pop()` cho nút back để quay về React Native host.
