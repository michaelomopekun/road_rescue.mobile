import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:road_rescue/services/api_client.dart';
import 'package:road_rescue/services/token_service.dart';
import 'package:road_rescue/main.dart'; // import to access navigatorKey

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class FcmService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Set up background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permissions
    await requestPermissions();

    // Set up local notifications for foreground
    await _initLocalNotifications();

    // Listen to token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      registerDevice(newToken);
    });

    // Get current token and register device
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await registerDevice(token);
      }
    } catch (e) {
      print('Firebase Messaging Token error: $e');
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message);
      }
    });

    // Handle message open from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked from background!');
      _handleNavigation(message);
    });
  }

  static Future<void> requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print('User granted FCm permission: ${settings.authorizationStatus}');
  }

  static Future<void> _initLocalNotifications() async {
    // Initialization Settings for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          print('Local notification tapped with payload: ${response.payload}');
          // Route based on assumed string payload from message.data
          // In a real app, map this correctly
        }
      },
    );
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null && !kIsWeb) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
      );
      
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
      
      await _localNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: platformChannelSpecifics,
        payload: message.data.toString(),
      );
    }
  }

  static Future<void> registerDevice(String? token) async {
    if (token == null) return;

    final isAuth = await TokenService.isAuthenticated();
    if (!isAuth) return; // Don't register if not logged in

    try {
      // final platform = kIsWeb ? 'web' : Platform.operatingSystem;
      await ApiClient.post(
        '/users/register-device',
        body: {
          'deviceToken': token,
          // 'platform': platform,
        },
        requiresAuth: true,
      );
      print('Successfully registered device token: $token');
    } catch (e) {
      print('Failed to register device token: $e');
    }
  }

  static void _handleNavigation(RemoteMessage message) {
    if (message.data.isEmpty) return;
    
    final String? type = message.data['type'];
    final context = navigatorKey.currentContext;
    
    if (context == null) {
      print('Warning: No current context for navigation');
      return;
    }

    switch (type) {
      case 'new_job':
        Navigator.of(context).pushNamed('/mechanic');
        break;
      case 'job_accepted':
        Navigator.of(context).pushNamed('/driver/map');
        break;
      case 'verification_approved':
        Navigator.of(context).pushReplacementNamed('/mechanic');
        break;
      case 'job_update':
        final role = message.data['role']; // e.g. DRIVER or PROVIDER
        if (role == 'DRIVER') {
          Navigator.of(context).pushNamed('/driver/history');
        } else {
          Navigator.of(context).pushNamed('/mechanic/history');
        }
        break;
      default:
        print('Unknown notification type: $type');
    }
  }
}
