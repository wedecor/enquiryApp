import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' show PlatformDispatcher;
import 'package:wedecor_enquiries/firebase_options.dart';

class FirebaseBootstrap {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Configure emulators for local development
      if (kDebugMode) {
        await _configureEmulators();
      }

      // Set up error handling
      FlutterError.onError = (details) {
        if (kDebugMode) {
          print('Flutter Error: ${details.exception}');
        }
      };
      
      if (kIsWeb) {
        // Web-specific error handling
        PlatformDispatcher.instance.onError = (error, stack) {
          if (kDebugMode) {
            print('Platform Error: $error');
          }
          return true;
        };
      } else {
        // Mobile error handling
        PlatformDispatcher.instance.onError = (error, stack) {
          if (kDebugMode) {
            print('Platform Error: $error');
          }
          return true;
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firebase initialization error: $e');
      }
      // Continue without Firebase for demo purposes
    }
  }

  static Future<void> _configureEmulators() async {
    try {
      // Configure Auth emulator
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      
      // Configure Firestore emulator
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    } catch (e) {
      if (kDebugMode) {
        print('Emulator configuration error: $e');
      }
    }
  }
}
