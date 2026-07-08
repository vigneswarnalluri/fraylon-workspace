import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Conditionally initialize Firebase if enabled in environment declarations
  const useFirebase = bool.fromEnvironment('USE_FIREBASE', defaultValue: true);
  if (useFirebase) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Enable Firestore offline persistence for offline-first capabilities
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
      );

      // Request and setup Firebase Messaging push notification listeners
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground notification received: ${message.notification?.title}');
      });
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
    }
  }

  runApp(
    const ProviderScope(
      child: FraylonWorkspaceApp(),
    ),
  );
}
