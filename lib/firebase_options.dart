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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDUVC1-2oLkvwQ5o6iw-IZDjoS4sAF6aM4',
    appId: '1:324748181774:ios:14f1c481aaa5e5fc5b975f',
    messagingSenderId: '324748181774',
    projectId: 'khayal-ai0',
    storageBucket: 'khayal-ai0.firebasestorage.app',
    androidClientId: '324748181774-859sakiim4ec8bh1p6i3qrdhpb5h1bij.apps.googleusercontent.com',
    iosClientId: '324748181774-88ugvemcp9v1sm1snbqnu2l8509hk7u2.apps.googleusercontent.com',
    iosBundleId: 'com.henry.flutterMvvmRiverpod',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCVRAYJ8LoYb54Bw8FJR-GhvGRgnVfsIWY',
    appId: '1:324748181774:android:b3956a214f281c915b975f',
    messagingSenderId: '324748181774',
    projectId: 'khayal-ai0',
    storageBucket: 'khayal-ai0.firebasestorage.app',
  );

}