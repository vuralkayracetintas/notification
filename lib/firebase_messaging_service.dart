import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'notification_service.dart';

// Background message handler must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
}

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final NotificationService _notificationService = NotificationService();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<String?> _getTokenWithRetry({int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          return token;
        }
      } catch (e) {
        debugPrint('Attempt ${i + 1} failed to get FCM token: $e');
        if (i < maxRetries - 1) {
          await Future.delayed(Duration(seconds: i + 2));
        }
      }
    }
    return null;
  }

  Future<void> initialize({bool autoSubscribeToAll = true}) async {
    try {
      // Request notification permissions
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

      debugPrint('User granted permission: ${settings.authorizationStatus}');

      // Wait a bit for APNS token on iOS
      await Future.delayed(const Duration(milliseconds: 1000));

      // Get FCM token with retry logic
      _fcmToken = await _getTokenWithRetry();
      subscribeToTopic('general'); // Subscribe to a default topic
      debugPrint('FCM Token: $_fcmToken');
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
      // Try to get token later
      Future.delayed(const Duration(seconds: 3), () async {
        try {
          _fcmToken = await _firebaseMessaging.getToken();
          debugPrint('FCM Token (delayed): $_fcmToken');
        } catch (e) {
          debugPrint('Failed to get token after retry: $e');
        }
      });
    }

    // Listen to token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      debugPrint('FCM Token refreshed: $newToken');
      // Send token to your server here
    });

    // Configure foreground notification presentation
    // Set to false to prevent duplicate notifications
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: false, // Disable automatic notification display
      badge: true,
      sound: false, // We'll handle sound in local notification
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle notification tap when app was terminated
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Auto-subscribe to 'all_users' topic for broadcast messages
    if (autoSubscribeToAll) {
      await subscribeToTopic('all_users');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // Show local notification when app is in foreground
    if (message.notification != null) {
      _notificationService.showNotification(
        title: message.notification!.title ?? 'New Message',
        body: message.notification!.body ?? '',
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.messageId}');
    debugPrint('Data: ${message.data}');

    // Handle navigation based on notification data
    // Example: Navigate to specific screen based on data
    if (message.data.containsKey('screen')) {
      String screen = message.data['screen'];
      debugPrint('Navigate to screen: $screen');
      // Add your navigation logic here
    }
  }

  // Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  // Delete FCM token
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      debugPrint('FCM token deleted');
    } catch (e) {
      debugPrint('Error deleting token: $e');
    }
  }

  // Get unique device ID
  Future<String?> getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString('device_id');

      if (deviceId == null) {
        // Generate new device ID
        final deviceInfo = DeviceInfoPlugin();

        if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId =
              iosInfo.identifierForVendor ??
              'ios_${DateTime.now().millisecondsSinceEpoch}';
        } else if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
        } else {
          deviceId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
        }

        // Save to SharedPreferences
        await prefs.setString('device_id', deviceId);
      }

      return deviceId;
    } catch (e) {
      debugPrint('Error getting device ID: $e');
      return null;
    }
  }
}
