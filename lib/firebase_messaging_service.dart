import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_service.dart';

// Background message handler must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');
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
        print('Attempt ${i + 1} failed to get FCM token: $e');
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

      print('User granted permission: ${settings.authorizationStatus}');

      // Wait a bit for APNS token on iOS
      await Future.delayed(const Duration(milliseconds: 1000));

      // Get FCM token with retry logic
      _fcmToken = await _getTokenWithRetry();
      subscribeToTopic('general'); // Subscribe to a default topic
      print('FCM Token: $_fcmToken');
    } catch (e) {
      print('Error initializing FCM: $e');
      // Try to get token later
      Future.delayed(const Duration(seconds: 3), () async {
        try {
          _fcmToken = await _firebaseMessaging.getToken();
          print('FCM Token (delayed): $_fcmToken');
        } catch (e) {
          print('Failed to get token after retry: $e');
        }
      });
    }

    // Listen to token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      print('FCM Token refreshed: $newToken');
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
    print('Received foreground message: ${message.messageId}');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');

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
    print('Notification tapped: ${message.messageId}');
    print('Data: ${message.data}');

    // Handle navigation based on notification data
    // Example: Navigate to specific screen based on data
    if (message.data.containsKey('screen')) {
      String screen = message.data['screen'];
      print('Navigate to screen: $screen');
      // Add your navigation logic here
    }
  }

  // Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }

  // Delete FCM token
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      print('FCM token deleted');
    } catch (e) {
      print('Error deleting token: $e');
    }
  }
}
