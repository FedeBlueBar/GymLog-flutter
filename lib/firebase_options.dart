import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can configure them using the FlutterFire CLI.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAlv2DQivyHhiLdLausgqS-7qBaAepwasI',
    appId: '1:157548367622:android:31eb49d02800dbe96f9887',
    messagingSenderId: '157548367622',
    projectId: 'gymlog2-e589e',
    storageBucket: 'gymlog2-e589e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBb-BuLuEYLQMKFEv3BO4OJrze1Q-oXJpg',
    appId: '1:157548367622:ios:b6a541b4b90ef2066f9887',
    messagingSenderId: '157548367622',
    projectId: 'gymlog2-e589e',
    storageBucket: 'gymlog2-e589e.firebasestorage.app',
    iosBundleId: 'com.example.gymlogFlutter',
    iosClientId: '157548367622-0iuq7n6efri28nfvnj9r7fpl2r16nggd.apps.googleusercontent.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBb-BuLuEYLQMKFEv3BO4OJrze1Q-oXJpg',
    appId: '1:157548367622:ios:b6a541b4b90ef2066f9887',
    messagingSenderId: '157548367622',
    projectId: 'gymlog2-e589e',
    storageBucket: 'gymlog2-e589e.firebasestorage.app',
    iosBundleId: 'com.example.gymlogFlutter',
    iosClientId: '157548367622-0iuq7n6efri28nfvnj9r7fpl2r16nggd.apps.googleusercontent.com',
  );
}
