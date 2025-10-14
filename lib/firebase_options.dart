import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyCiMOzQ0FlR3o3DIC4GHe8D8Mnh01r_2LI",
    authDomain: "inventory-fa052.firebaseapp.com",
    projectId: "inventory-fa052",
    storageBucket: "inventory-fa052.firebasestorage.app",
    messagingSenderId: "985279272231",
    appId: "1:985279272231:web:7d9d4bfb453ed975eb8502",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "YOUR_ANDROID_API_KEY",
    appId: "YOUR_ANDROID_APP_ID",
    messagingSenderId: "YOUR_ANDROID_SENDER_ID",
    projectId: "inventory-fa052",
    storageBucket: "inventory-fa052.firebasestorage.app",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "YOUR_IOS_API_KEY",
    appId: "YOUR_IOS_APP_ID",
    messagingSenderId: "YOUR_IOS_SENDER_ID",
    projectId: "inventory-fa052",
    storageBucket: "inventory-fa052.firebasestorage.app",
    iosBundleId: "com.example.inventorySystem",
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: "YOUR_IOS_API_KEY",
    appId: "YOUR_IOS_APP_ID",
    messagingSenderId: "YOUR_IOS_SENDER_ID",
    projectId: "inventory-fa052",
    storageBucket: "inventory-fa052.firebasestorage.app",
    iosBundleId: "com.example.inventorySystem",
  );
}
