// File generated for Fraylon Workspace Web.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for android.',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCi_Otn1YjtSGosumCBIACgEzp8kliie6o',
    appId: '1:962787134274:web:d1ab5e0512d9cbb53fd6db',
    messagingSenderId: '962787134274',
    projectId: 'fraylon-workspace-44a89',
    authDomain: 'fraylon-workspace-44a89.firebaseapp.com',
    storageBucket: 'fraylon-workspace-44a89.firebasestorage.app',
    measurementId: 'G-Q2SRVD4NN9',
  );
}
