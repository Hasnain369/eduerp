import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError catch (_) {
    debugPrint(
      'Firebase configuration is not complete yet. Update lib/firebase_options.dart and platform config files before running with real authentication.',
    );
  } catch (error) {
    debugPrint('Firebase initialization skipped: $error');
  }

  runApp(const ProviderScope(child: App()));
}
