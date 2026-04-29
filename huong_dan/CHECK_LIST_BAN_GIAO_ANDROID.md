# CHECK LIST BÀN GIAO ANDROID (Flutter Add-to-App + React Native Expo)

> Dùng checklist này để bàn giao/tích hợp nhanh, tránh lỗi build/runtime thường gặp.

## 1) Chuẩn bị module Flutter
- [ ] Copy `modules/flutter_module_sip` vào `<RN_PROJECT_ROOT>/modules/flutter_module_sip`
- [ ] Chạy:
  - [ ] `cd modules/flutter_module_sip`
  - [ ] `flutter pub get`
- [ ] Xác nhận `pubspec.yaml` **không** còn `integration_test` trong `dev_dependencies`

## 2) Android settings.gradle
- [ ] Merge vào `android/settings.gradle`:
  - [ ] `include ':app'`
  - [ ] `includeBuild(expoAutolinking.reactNativeGradlePlugin)`
  - [ ] Guard load Flutter script:

```groovy
def flutterInclude = new File(settingsDir.getParentFile(), "modules/flutter_module_sip/.android/include_flutter.groovy")
if (flutterInclude.exists()) {
  setBinding(new Binding([gradle: this]))
  evaluate(flutterInclude)
}
```

## 3) Android app/build.gradle
- [ ] Trong `dependencies {}` có:
  - [ ] `implementation project(path: ':flutter')`
  - [ ] `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")`
- [ ] Trong `android { compileOptions { ... } }` có:
  - [ ] `coreLibraryDesugaringEnabled true`
  - [ ] `sourceCompatibility JavaVersion.VERSION_17`
  - [ ] `targetCompatibility JavaVersion.VERSION_17`

## 4) AndroidManifest
- [ ] Trong `android/app/src/main/AndroidManifest.xml` khai báo:

```xml
<activity
  android:name="io.flutter.embedding.android.FlutterActivity"
  android:exported="false"
  android:theme="@style/AppTheme"
  android:configChanges="orientation|keyboardHidden|keyboard|screenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
  android:hardwareAccelerated="true"
  android:windowSoftInputMode="adjustResize" />
```

## 5) Native Bridge files
- [ ] Copy/merge:
  - [ ] `android/app/src/main/java/com/anonymous/siprixreactnt/SiprixBridge.kt`
  - [ ] `android/app/src/main/java/com/anonymous/siprixreactnt/SiprixBridgePackage.kt`
- [ ] Đăng ký package trong `MainApplication.kt`:
  - [ ] `add(SiprixBridgePackage())`

## 6) Build & run
- [ ] Chạy `npx expo run:android`
- [ ] Nếu cache cũ gây lỗi:
  - [ ] `cd android && ./gradlew clean && cd ..`
  - [ ] chạy lại `npx expo run:android`

## 7) Smoke test runtime
- [ ] Mở app RN
- [ ] Bấm nút `make call`
- [ ] Kỳ vọng: mở được màn hình Flutter call
- [ ] Không còn lỗi:
  - [ ] `ClassNotFoundException: io.flutter.embedding.android.FlutterActivity`
  - [ ] `ActivityNotFoundException: ... FlutterActivity`

## 8) Lỗi thường gặp và cách xử lý nhanh
- [ ] `Could not find method profileImplementation()`
  - [ ] Bỏ `profileImplementation`, dùng `implementation project(':flutter')`
- [ ] `requires core library desugaring`
  - [ ] Bật `coreLibraryDesugaringEnabled true`
  - [ ] Thêm `desugar_jdk_libs`
- [ ] `Could not find :siprix_voip_sdk:.`
  - [ ] Kiểm tra plugin `siprix_voip_sdk_android` resolve AAR đúng
  - [ ] Nếu cần, dùng `implementation files('libs/siprix_voip_sdk.aar')`

## 9) Bàn giao cho khách hàng
- [ ] Gửi kèm:
  - [ ] `huong_dan/FLUTTER_ADD_TO_APP_GUIDE.md`
  - [ ] `huong_dan/HUONG_DAN_GUI_KHACH_HANG.md`
  - [ ] file checklist này
- [ ] Xác nhận lại trên máy thật Android trước khi bàn giao
