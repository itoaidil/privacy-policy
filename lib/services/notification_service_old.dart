import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';  // Temporarily disabled
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📭 Background message: ${message.notification?.title}');
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  // static final FlutterLocalNotificationsPlugin _localNotifications =
  //     FlutterLocalNotificationsPlugin();  // Temporarily disabled

  // Update this with your Railway API URL
  static const String baseUrl =
      'https://travel-api-production-23ae.up.railway.app/api';

  static bool _initialized = false;

  /// Initialize Firebase and Notifications
  static Future<void> initialize() async {
    if (_initialized) {
      print('⚠️  Notification service already initialized');
      return;
    }

    try {
      // Initialize Firebase
      await Firebase.initializeApp();
      print('✅ Firebase initialized');

      // Request permissions (iOS & Android 13+)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Notification permissions granted');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('⚠️  Notification permissions provisional');
      } else {
        print('❌ Notification permissions denied');
        return; // Don't proceed if permissions denied
      }

      // Initialize local notifications
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      print('✅ Local notifications initialized');

      // Create notification channel (Android)
      const channel = AndroidNotificationChannel(
        'travel_booking_channel',
        'Travel Booking Notifications',
        description: 'Notifications for travel bookings and updates',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      print('✅ Android notification channel created');

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification opened app
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Check if app was opened from notification
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      _initialized = true;
      print('✅ Notification service initialized successfully');
    } catch (e) {
      print('❌ Error initializing notification service: $e');
    }
  }

  /// Register device token to backend
  static Future<bool> registerToken(int userId, String appType) async {
    try {
      // Get FCM token
      String? token = await _messaging.getToken();
      if (token == null) {
        print('❌ Failed to get FCM token');
        return false;
      }

      print('📱 FCM Token: ${token.substring(0, 20)}...');

      // Save token locally for debugging
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);

      // Register to backend
      final response = await http
          .post(
            Uri.parse('$baseUrl/notifications/register-token'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'userId': userId,
              'deviceToken': token,
              'appType': appType, // 'customer', 'driver', or 'po_admin'
              'deviceType': 'android',
            }),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Timeout registering token'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Device token registered: ${data['message']}');
        return true;
      } else {
        print('❌ Failed to register token: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error registering token: $e');
      return false;
    }
  }

  /// Handle foreground message (app is open)
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📬 Foreground message received');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');

    // Show local notification
    const androidDetails = AndroidNotificationDetails(
      'travel_booking_channel',
      'Travel Booking Notifications',
      channelDescription: 'Notifications for travel bookings and updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
      details,
      payload: jsonEncode(message.data),
    );

    // Update badge count
    await _updateBadgeCount();
  }

  /// Handle background message opened app
  static Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('🔔 Notification opened app');
    print('Title: ${message.notification?.title}');
    print('Data: ${message.data}');

    // TODO: Navigate to specific screen based on message.data
    // Example:
    // if (message.data['type'] == 'booking_created') {
    //   navigatorKey.currentState?.pushNamed('/booking-detail', arguments: message.data);
    // }
  }

  /// Handle notification tap
  static Future<void> _onNotificationTapped(
      NotificationResponse response) async {
    print('🔔 Notification tapped');

    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        print('Payload: $data');

        // TODO: Navigate based on payload
        // Example:
        // if (data['type'] == 'booking_created') {
        //   navigatorKey.currentState?.pushNamed('/booking-detail', arguments: data);
        // }
      } catch (e) {
        print('Error parsing payload: $e');
      }
    }
  }

  /// Get notifications from backend
  static Future<List<Map<String, dynamic>>> getNotifications(
    int userId, {
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        'offset': offset.toString(),
        if (unreadOnly) 'unreadOnly': 'true',
      };

      final uri = Uri.parse('$baseUrl/notifications/$userId')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Timeout getting notifications'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['notifications'] ?? []);
      }

      print('❌ Failed to get notifications: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ Error getting notifications: $e');
      return [];
    }
  }

  /// Get unread count
  static Future<int> getUnreadCount(int userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/notifications/$userId/unread-count'),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Timeout getting unread count'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  static Future<bool> markAsRead(int notificationId, int userId) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/notifications/$notificationId/read'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'userId': userId}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Timeout marking as read'),
          );

      if (response.statusCode == 200) {
        await _updateBadgeCount();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error marking as read: $e');
      return false;
    }
  }

  /// Mark all as read
  static Future<bool> markAllAsRead(int userId) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/notifications/$userId/read-all'),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Timeout marking all as read'),
          );

      if (response.statusCode == 200) {
        await _updateBadgeCount();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error marking all as read: $e');
      return false;
    }
  }

  /// Update badge count
  static Future<void> _updateBadgeCount() async {
    // This would need a platform channel implementation
    // For now, just log
    print('🔔 Badge count update requested');
  }

  /// Listen to token refresh
  static void listenToTokenRefresh(int userId, String appType) {
    _messaging.onTokenRefresh.listen((newToken) async {
      print('🔄 FCM token refreshed');
      await registerToken(userId, appType);
    });
  }

  /// Get current FCM token (for debugging)
  static Future<String?> getCurrentToken() async {
    return await _messaging.getToken();
  }

  /// Clear all local notifications
  static Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
    print('🧹 All local notifications cleared');
  }
}
