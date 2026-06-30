// GENERATED FILE — replace with output from: flutterfire configure
// Run: dart pub global activate flutterfire_cli
//      flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
//
// Until then, these are placeholder values that allow the project to compile.
// The app will crash at runtime until real values are filled in.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  // -----------------------------------------------------------------------
  // REPLACE all placeholder values below with your real Firebase project
  // config. Get them from: Firebase Console → Project Settings → Your apps.
  // -----------------------------------------------------------------------

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WITH_WEB_API_KEY',
    appId: 'REPLACE_WITH_WEB_APP_ID',
    messagingSenderId: 'REPLACE_WITH_SENDER_ID',
    projectId: 'REPLACE_WITH_PROJECT_ID',
    authDomain: 'REPLACE_WITH_PROJECT_ID.firebaseapp.com',
    storageBucket: 'REPLACE_WITH_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBmhzn9u3G2ZyZFoarAUtsx51-S1yVjsKk',
    appId: '1:204019052123:android:1bbdae20c59b5b1b20197e',
    messagingSenderId: '204019052123',
    projectId: 'snapprint-5076c',
    storageBucket: 'snapprint-5076c.firebasestorage.app',
  );
  // iOS: add com.snapprint.app in Firebase Console → Project Settings → Add app → iOS
  // then replace these values with the real GoogleService-Info.plist values.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBmhzn9u3G2ZyZFoarAUtsx51-S1yVjsKk',
    appId: '1:204019052123:ios:REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: '204019052123',
    projectId: 'snapprint-5076c',
    storageBucket: 'snapprint-5076c.firebasestorage.app',
    iosBundleId: 'com.snapprint.app',
  );

}
