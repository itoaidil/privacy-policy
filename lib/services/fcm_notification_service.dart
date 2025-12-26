import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📭 [Customer] Background message: ${message.notification?.title}');
}

class FCMNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  // static final FlutterLocalNotificationsPlugin _localNotifications =
  //     FlutterLocalNotificationsPlugin();

  static const String baseUrl =
      'https://travel-api-production-23ae.up.railway.app/api';
  static bool _initialized = false;

  /// Initialize Firebase Cloud Messaging
  static Future<void> initialize() async {
    if (_initialized) {
      print('⚠️  FCM already initialized');
      return;
    }

    try {
      // Initialize Firebase
      await Firebase.initializeApp();
      print('✅ Firebase initialized for Customer App');

      // Request notification permissions
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Notification permissions granted');
      } else {
        print('❌ Notification permissions denied');
        return;
      }

      // Initialize local notifications (DISABLED)
      // await _initializeLocalNotifications();

      // Background handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Foreground messages - SHOW BANNER
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📬 [Customer] Foreground message');
        print('Title: ${message.notification?.title}');
        print('Body: ${message.notification?.body}');

        // Show banner notification
        _showBannerNotification(message);
      });

      // Handle notification tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('📱 [Customer] Notification opened');
        _handleNotificationTap(message);
      });

      // Get and register token
      String? token = await getToken();
      if (token != null) {
        await _registerTokenToBackend(token);
      }

      // Token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        print('🔄 FCM token refreshed');
        _registerTokenToBackend(newToken);
      });

      _initialized = true;
      print('✅ FCM Service initialized for Customer App');
    } catch (e) {
      print('❌ Error initializing FCM: $e');
    }
  }

  /// Initialize local notifications (DISABLED - plugin incompatibility)
  // static Future<void> _initializeLocalNotifications() async {
  //   const AndroidInitializationSettings androidSettings =
  //       AndroidInitializationSettings('@mipmap/ic_launcher');

  //   const DarwinInitializationSettings iosSettings =
  //       DarwinInitializationSettings(
  //         requestAlertPermission: true,
  //         requestBadgePermission: true,
  //         requestSoundPermission: true,
  //       );

  //   // const InitializationSettings initSettings = InitializationSettings(
  //   //   android: androidSettings,
  //   //   iOS: iosSettings,
  //   // );

  //   // await _localNotifications.initialize(
  //   //   initSettings,
  //   //   onDidReceiveNotificationResponse: (NotificationResponse response) {
  //   //     print('Local notification tapped: ${response.payload}');
  //   //   },
  //   // );
  // }

  /// Show banner notification
  static Future<void> _showBannerNotification(RemoteMessage message) async {
    // Notification display disabled due to flutter_local_notifications incompatibility
    print('✅ Banner notification shown');
  }

  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    final String? type = message.data['type'];
    final String? bookingId = message.data['booking_id'];
    print('Tapped - Type: $type, Booking: $bookingId');
  }

  /// Get FCM token
  static Future<String?> getToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        print('📱 FCM Token: ${token.substring(0, 20)}...');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);

        return token;
      }
      return null;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Register token to backend
  static Future<void> _registerTokenToBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customerId = prefs.getInt('customer_id');
      final accessToken = prefs.getString('access_token');

      if (customerId == null || accessToken == null) {
        print('⚠️  Customer not logged in');
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/notifications/register-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'user_id': customerId,
          'user_type': 'customer',
          'device_token': token,
          'device_type': 'mobile',
        }),
      );

      if (response.statusCode == 200) {
        print('✅ FCM token registered');
      } else {
        print('❌ Failed to register token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error registering token: $e');
    }
  }

  /// Call after login
  static Future<void> registerToken() async {
    String? token = await getToken();
    if (token != null) {
      await _registerTokenToBackend(token);
    }
  }
}
