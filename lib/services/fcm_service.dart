import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:road_rescue/services/api_client.dart';
import 'package:road_rescue/services/token_service.dart';
import 'package:road_rescue/services/request_state_manager.dart';
import 'package:road_rescue/services/socket_service.dart';

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

      // If socket is connected, ignore FCM because socket is primary real-time channel
      if (SocketService().isConnected) {
        print('[FcmService] Socket is connected, ignoring FCM message in foreground');
        return;
      }

      print('[FcmService] Socket disconnected, showing local notification fallback for FCM');
      if (message.notification != null) {
        _showLocalNotification(message);
      } else {
        // Fallback title/body if notification is empty
        _showLocalNotification(message, fallbackTitle: 'Update', fallbackBody: 'Request status updated');
      }
    });

    // Handle message open from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked from background!');
      _handleNavigation(message);
    });
  }

  /// Handle incoming job request — legacy, now handled by state manager
  static void _handleIncomingJobRequest(RemoteMessage message) {
    print('[FcmService] _handleIncomingJobRequest called (fallback)');
    RequestStateManager().loadActiveRequest(); // Fetch latest state
  }

  /// Accept a job request via API
  static Future<void> _acceptJob(String requestId, BuildContext context) async {
    // Moved to mechanic service and active job page
  }

  /// Decline a job request via API
  static Future<void> _declineJob(String requestId) async {
    // Moved mostly away, backend could handle decline via status
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
          _handleNotificationTap(response.payload!);
        }
      },
    );
  }

  /// Handle tapping on a local notification
  static void _handleNotificationTap(String payload) {
    try {
      print('[FcmService] Local notification tapped. Reloading active request...');
      RequestStateManager().loadActiveRequest(); // Fetch latest state
      
      final context = navigatorKey.currentContext;
      if (context != null) {
        // Force navigation to dashboard which will handle routing to active request
        final type = jsonDecode(payload)['type'] as String?;
        if (type == 'new_job' || type == 'job_update' || type == 'job_accepted') {
           // Assume proper navigation will happen via state manager updates listening to activeRequest changes
        }
      }
    } catch (e) {
      print('[FcmService] Error parsing notification payload: $e');
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message, {String? fallbackTitle, String? fallbackBody}) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    final title = notification?.title ?? fallbackTitle ?? 'Notification';
    final body = notification?.body ?? fallbackBody ?? 'New update';

    if (!kIsWeb) {
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
      
      // Serialize message data as payload so it's available on tap
      final payload = jsonEncode(message.data);

      await _localNotificationsPlugin.show(
        id: (notification.hashCode == 0) ? DateTime.now().millisecondsSinceEpoch ~/ 1000 : notification.hashCode,
        title: title,
        body: body,
        notificationDetails: platformChannelSpecifics,
        payload: payload,
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
        '/auth/register-device',
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
    print('[FcmService] Message opened from background, reloading active request...');
    RequestStateManager().loadActiveRequest(); // Fetch latest state
  }

  /// Handle job accepted notification — legacy, now handled by state manager
  static void _handleJobAccepted(RemoteMessage message) {
    print('[FcmService] _handleJobAccepted called (fallback)');
    RequestStateManager().loadActiveRequest(); // Fetch latest state
  }
}
