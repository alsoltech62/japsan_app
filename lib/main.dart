import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'core/theme.dart';
import 'core/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/app_lock_screen.dart';

import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'core/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    await FirebaseService.initialize();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // Note: User needs to add google-services.json to android/app and configured for iOS
  }
  
  // Log Facebook activated app event
  await FacebookAppEvents().activateApp();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApiService()),
      ],
      child: const JapsanPayApp(),
    ),
  );
}

class JapsanPayApp extends StatelessWidget {
  const JapsanPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Japsan Pay Ecosystem',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Consumer<ApiService>(
        builder: (context, api, _) {
          if (api.isAuthenticated) {
            return const AppLockScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
