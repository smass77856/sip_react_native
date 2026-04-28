// File generated using FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB-x6Y0fJ9bUc-zv0sBj3Uh4Jx19VcNuSc',
    appId: '1:1050109101043:android:3f7bffcc0f9492fd8d0886',
    messagingSenderId: '1050109101043',
    projectId: 'sipvoip-4e692',
    storageBucket: 'sipvoip-4e692.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBI6dXdhHc_PCawp6Etbml4Vi4vhA4Ea1s',
    appId: '1:1050109101043:ios:4926e95ee5ce6c008d0886',
    messagingSenderId: '1050109101043',
    projectId: 'sipvoip-4e692',
    storageBucket: 'sipvoip-4e692.firebasestorage.app',
    iosBundleId: 'com.example.siprixVoipSdkExample',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBI6dXdhHc_PCawp6Etbml4Vi4vhA4Ea1s',
    appId: '1:1050109101043:ios:31788fb6a6460efc8d0886',
    messagingSenderId: '1050109101043',
    projectId: 'sipvoip-4e692',
    storageBucket: 'sipvoip-4e692.firebasestorage.app',
    iosBundleId: 'com.idb.siprix',
  );

}