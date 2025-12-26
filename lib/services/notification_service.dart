import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📭 Background message: ${message.notification?.title}');
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Update this with your Railway API URL
  static const String baseUrl =
      'https://travel-api-production-23ae.up.railway.app/api';

  static bool _initialized = false;

  // Stream controller for notification updates
  static final _notificationController =
      StreamController<RemoteMessage>.broadcast();
  static Stream<RemoteMessage> get onNotificationReceived =>
      _notificationController.stream;

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
      }

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Handle foreground messages - emit to stream for UI updates
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📬 Foreground message received');
        print('Title: ${message.notification?.title}');
        print('Body: ${message.notification?.body}');
        print('Data: ${message.data}');

        // Emit notification to stream for real-time UI updates
        _notificationController.add(message);
      });

      // Handle notification opened app
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('📱 Notification opened app');
        print('Data: ${message.data}');
      });

      _initialized = true;
      print('✅ Notification service initialized');
    } catch (e) {
      print('❌ Error initializing notifications: $e');
    }
  }

  /// Get FCM token
  static Future<String?> getToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        print('📱 FCM Token: $token');
        return token;
      } else {
        print('❌ Failed to get FCM token');
        return null;
      }
    } catch (e) {
      print('❌ Error getting token: $e');
      return null;
    }
  }

  /// Register device token to backend
  static Future<bool> registerToken({
    required int userId,
    required String appType,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        print('❌ No token to register');
        return false;
      }

      final url = Uri.parse('$baseUrl/notifications/register-token');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'deviceToken': token,
          'appType': appType, // 'customer', 'po', or 'driver'
          'deviceType': 'android',
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Device token registered to backend');

        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
        await prefs.setInt('fcm_user_id', userId);

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

  /// Get notifications from backend
  static Future<List<Map<String, dynamic>>> getNotifications({
    required int userId,
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    try {
      final url = Uri.parse(
          '$baseUrl/notifications/$userId?limit=$limit&offset=$offset${unreadOnly ? '&unreadOnly=true' : ''}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['notifications']);
        }
      }
      return [];
    } catch (e) {
      print('❌ Error getting notifications: $e');
      return [];
    }
  }

  /// Get unread count
  static Future<int> getUnreadCount({required int userId}) async {
    try {
      final url = Uri.parse('$baseUrl/notifications/$userId/unread-count');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['count'] as int;
        }
      }
      return 0;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  static Future<bool> markAsRead({required int notificationId}) async {
    try {
      final url = Uri.parse('$baseUrl/notifications/$notificationId/read');
      final response = await http.put(url);

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error marking as read: $e');
      return false;
    }
  }

  /// Mark all as read
  static Future<bool> markAllAsRead({required int userId}) async {
    try {
      final url = Uri.parse('$baseUrl/notifications/$userId/read-all');
      final response = await http.put(url);

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error marking all as read: $e');
      return false;
    }
  }

  /// Send test notification (for testing)
  static Future<bool> sendTestNotification({required int userId}) async {
    try {
      final url = Uri.parse('$baseUrl/notifications/test');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error sending test notification: $e');
      return false;
    }
  }
}
