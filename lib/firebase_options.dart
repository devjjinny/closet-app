// Generated from GoogleService-Info.plist & google-services.json
// firebase_options.dart

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web is not supported');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA4LHJmZzUKHPFd3F9jwTWK8wDBEt7inxs',
    appId: '1:126009314241:android:9a072bde0187427da7fd40',
    messagingSenderId: '126009314241',
    projectId: 'closet-app-mvp',
    storageBucket: 'closet-app-mvp.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDZ6XzzXEXZ8nCPnWhXrihewH6AVsIEjyg',
    appId: '1:126009314241:ios:f1802f8ba5660ff5a7fd40',
    messagingSenderId: '126009314241',
    projectId: 'closet-app-mvp',
    storageBucket: 'closet-app-mvp.firebasestorage.app',
    iosBundleId: 'com.closetapp.closetApp',
  );
}
