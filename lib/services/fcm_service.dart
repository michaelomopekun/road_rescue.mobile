import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:road_rescue/services/api_client.dart';
import 'package:road_rescue/services/token_service.dart';
import 'package:road_rescue/features/mechanic/widgets/incoming_job_bottom_sheet.dart';

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

      final String? type = message.data['type'];

      // For new_job messages, show a bottom sheet instead of a notification
      if (type == 'new_job') {
        _handleIncomingJobRequest(message);
      } else {
        // For other types, show a standard local notification
        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
          _showLocalNotification(message);
        }
      }
    });

    // Handle message open from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked from background!');
      _handleNavigation(message);
    });
  }

  /// Handle incoming job request — show a bottom sheet to the mechanic
  static void _handleIncomingJobRequest(RemoteMessage message) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      print('[FcmService] No context available for bottom sheet, showing notification instead');
      _showLocalNotification(message);
      return;
    }

    // Extract job data from the FCM message
    final data = message.data;
    final String requestId = data['requestId'] ?? '';
    final String driverName = data['driverName'] ?? 'Unknown Driver';
    final String description = data['description'] ??
        message.notification?.body ??
        'Roadside assistance needed';
    final String location = data['location'] ?? 'Unknown location';
    final double distanceKm = double.tryParse(data['distanceKm'] ?? '') ?? 0.0;
    final String? driverPhone = data['driverPhone'];

    print('[FcmService] Showing incoming job bottom sheet for request: $requestId');

    // Show the bottom sheet
    IncomingJobBottomSheet.show(
      context,
      requestId: requestId,
      driverName: driverName,
      issueDescription: description,
      location: location,
      distanceKm: distanceKm,
      driverPhone: driverPhone,
    ).then((accepted) {
      if (accepted == true) {
        print('[FcmService] Mechanic ACCEPTED job: $requestId');
        _acceptJob(requestId, context);
      } else if (accepted == false) {
        print('[FcmService] Mechanic DECLINED job: $requestId');
        _declineJob(requestId);
      }
    });
  }

  /// Accept a job request via API
  static Future<void> _acceptJob(String requestId, BuildContext context) async {
    try {
      final response = await ApiClient.post(
        '/requests/respond',
        body: {
          'requestId': requestId,
          'response': 'APPROVE',
        },
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        print('[FcmService] Job accepted successfully');
        // Navigate to the active job or refresh the dashboard
        if (navigatorKey.currentContext != null) {
          Navigator.of(navigatorKey.currentContext!).pushNamed('/mechanic');
        }
      } else {
        print('[FcmService] Failed to accept job: ${response.statusCode}');
      }
    } catch (e) {
      print('[FcmService] Error accepting job: $e');
    }
  }

  /// Decline a job request via API
  static Future<void> _declineJob(String requestId) async {
    try {
      final response = await ApiClient.post(
        '/requests/respond',
        body: {
          'requestId': requestId,
          'response': 'DECLINE',
        },
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        print('[FcmService] Job declined successfully');
      } else {
        print('[FcmService] Failed to decline job: ${response.statusCode}');
      }
    } catch (e) {
      print('[FcmService] Error declining job: $e');
    }
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
      // Try to parse as JSON first
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final type = data['type'] as String?;
      final context = navigatorKey.currentContext;

      if (context == null || type == null) return;

      // If it's a new_job from a background notification tap, show the bottom sheet
      if (type == 'new_job') {
        final requestId = data['requestId'] ?? '';
        final driverName = data['driverName'] ?? 'Unknown Driver';
        final description = data['description'] ?? 'Roadside assistance needed';
        final location = data['location'] ?? 'Unknown location';
        final distanceKm = double.tryParse(data['distanceKm']?.toString() ?? '') ?? 0.0;

        IncomingJobBottomSheet.show(
          context,
          requestId: requestId,
          driverName: driverName,
          issueDescription: description,
          location: location,
          distanceKm: distanceKm,
        ).then((accepted) {
          if (accepted == true) {
            _acceptJob(requestId, context);
          } else if (accepted == false) {
            _declineJob(requestId);
          }
        });
      }
    } catch (e) {
      print('[FcmService] Error parsing notification payload: $e');
    }
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
      
      // Serialize message data as payload so it's available on tap
      final payload = jsonEncode(message.data);

      await _localNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
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
        // Show bottom sheet instead of just navigating
        _handleIncomingJobRequest(message);
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
