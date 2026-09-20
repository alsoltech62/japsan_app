import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/notifications_screen.dart';
import 'theme.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('Handling background message: ${message.messageId}');
  } catch (e) {
    debugPrint('Background message initialization error: $e');
  }
}

class FirebaseService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static GlobalKey<NavigatorState>? navigatorKey;

  static Future<void> initialize({GlobalKey<NavigatorState>? navKey}) async {
    navigatorKey = navKey;

    try {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // Set foreground notification presentation options for iOS
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    // Android High Importance Channel for Heads-Up / Popup Notification
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'japsan_high_importance_channel',
      'Japsan Pay Notifications',
      description: 'High importance popup notifications for Japsan Pay users',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _localNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
    }

    await _localNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationClick(response.payload);
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
      _showInAppPopup(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(json.encode(message.data));
    });

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Save FCM token
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
        debugPrint('FCM Token: $token');
      }
    } catch (e) {
      debugPrint('Error fetching FCM token: $e');
    }
    
    // Subscribe to topics for Admin Broadcast Notifications
    try {
      await _firebaseMessaging.subscribeToTopic('all_users');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }

    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', newToken);
      } catch (e) {
        debugPrint('Error storing refreshed FCM token: $e');
      }
    });
  }

  static void _showLocalNotification(RemoteMessage message) async {
    try {
      RemoteNotification? notification = message.notification;
      String? title = notification?.title ?? message.data['title'] ?? 'Japsan Pay Alert';
      String? body = notification?.body ?? message.data['message'] ?? message.data['body'] ?? '';

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'japsan_high_importance_channel',
        'Japsan Pay Notifications',
        channelDescription: 'High importance popup notifications for Japsan Pay users',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        ticker: 'ticker',
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      );

      final int notificationId = notification?.hashCode ??
          (DateTime.now().millisecondsSinceEpoch % 100000);

      await _localNotificationsPlugin.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: platformDetails,
        payload: json.encode(message.data),
      );
    } catch (e) {
      debugPrint('Error displaying local notification: $e');
    }
  }

  static void _showInAppPopup(RemoteMessage message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey?.currentContext;
      if (context == null) return;

      final title = message.notification?.title ?? message.data['title'] ?? 'New Notification';
      final body = message.notification?.body ?? message.data['message'] ?? message.data['body'] ?? '';
      
      String? imageUrl = message.notification?.android?.imageUrl ?? message.data['image_url'] ?? message.data['image'];
      if (imageUrl == null && body.contains('[IMG:')) {
        final match = RegExp(r'\[IMG:(.+?)\]').firstMatch(body);
        if (match != null && match.groupCount >= 1) {
          imageUrl = match.group(1)?.trim();
        }
      }
      if (imageUrl != null && imageUrl.isNotEmpty) {
        if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
          String cleanPath = imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl;
          imageUrl = cleanPath.startsWith('backend/') ? 'https://japsanpay.com/$cleanPath' : 'https://japsanpay.com/backend/$cleanPath';
        }
      }

      final cleanBody = body.replaceAll(RegExp(r'\[IMG:.+?\]'), '').trim();

      if (title.isEmpty && cleanBody.isEmpty && (imageUrl == null || imageUrl.isEmpty)) return;

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0x20C89B3C),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active, color: AppTheme.premiumGold, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cleanBody.isNotEmpty)
                  Text(
                    cleanBody,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
                  ),
                if (imageUrl != null && imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Dismiss', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                navigatorKey?.currentState?.push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
      );
    });
  }

  static void _handleNotificationClick(String? payload) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigatorKey?.currentState != null) {
        navigatorKey?.currentState?.push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
      }
    });
  }
}
