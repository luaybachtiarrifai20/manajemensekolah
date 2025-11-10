import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:manajemensekolah/services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Top-level function untuk handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('📩 Background message received: ${message.messageId}');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');
  }
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  bool _isInitialized = false;
  String? _fcmToken;

  // Initialize FCM
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) print('FCM already initialized');
      return;
    }

    try {
      // Request permission
      await _requestPermission();

      // Get FCM token
      await _getFCMToken();

      // Configure foreground notification presentation (iOS)
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from notification (when terminated)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _isInitialized = true;
      if (kDebugMode) print('✅ FCM initialized successfully');
    } catch (e) {
      if (kDebugMode) print('❌ FCM initialization error: $e');
    }
  }

  // Request notification permission
  Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        print('FCM Permission status: ${settings.authorizationStatus}');
      }

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        if (kDebugMode) print('User denied notification permission');
      }
    } catch (e) {
      if (kDebugMode) print('Error requesting permission: $e');
    }
  }


  // Get and register FCM token
  Future<void> _getFCMToken() async {
    try {
      // iOS: APNS token might not be ready immediately
      // Retry with exponential backoff
      _fcmToken = await _getTokenWithRetry();
      
      if (_fcmToken != null) {
        if (kDebugMode) print('📱 FCM Token: $_fcmToken');
        
        // Register token with backend
        await _registerTokenWithBackend(_fcmToken!);
        
        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          if (kDebugMode) print('🔄 FCM Token refreshed: $newToken');
          _registerTokenWithBackend(newToken);
        });
      } else {
        if (kDebugMode) print('⚠️ Failed to get FCM token after retries');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error getting FCM token: $e');
    }
  }

  // Get token with retry logic for iOS APNS delay
  Future<String?> _getTokenWithRetry({int maxRetries = 10}) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        // On iOS, first try to get APNS token explicitly
        if (Platform.isIOS && attempt > 0) {
          try {
            final apnsToken = await _messaging.getAPNSToken();
            if (apnsToken != null && kDebugMode) {
              print('✅ APNS token received: ${apnsToken.substring(0, 20)}...');
            }
          } catch (e) {
            if (kDebugMode) print('⚠️ APNS token not ready yet');
          }
        }

        final token = await _messaging.getToken();
        if (token != null) {
          if (kDebugMode) print('✅ FCM token obtained on attempt ${attempt + 1}');
          return token;
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Token attempt ${attempt + 1}/$maxRetries failed: $e');
        }
        
        // If APNS token not ready on iOS, wait and retry
        if (e.toString().contains('apns-token-not-set')) {
          if (attempt < maxRetries - 1) {
            // Exponential backoff with max 30s: 1s, 2s, 4s, 8s, 16s, 30s, 30s...
            final baseDelay = (1 << attempt);
            final delay = Duration(seconds: baseDelay > 30 ? 30 : baseDelay);
            if (kDebugMode) print('⏳ Waiting ${delay.inSeconds}s for APNS token...');
            await Future.delayed(delay);
            continue;
          } else {
            // Last attempt failed, log detailed info
            if (kDebugMode) {
              print('❌ All $maxRetries attempts failed to get APNS token');
              print('💡 Suggestions:');
              print('   1. Close app completely and reopen');
              print('   2. Check internet connection');
              print('   3. Check Settings → General → Date & Time → Set Automatically');
              print('   4. Try switching between WiFi and cellular');
              print('   5. Wait a few minutes and try again');
            }
          }
        }
        
        // Other errors, throw
        if (attempt == maxRetries - 1) {
          rethrow;
        }
      }
    }
    return null;
  }

  // Register FCM token with backend
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      if (kDebugMode) print('🔄 Attempting to register FCM token with backend...');
      
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('token');
      
      if (userToken == null) {
        if (kDebugMode) print('❌ No auth token found, skipping FCM registration');
        return;
      }

      if (kDebugMode) {
        print('📡 Sending to: ${ApiService.baseUrl}/fcm/register');
        print('📱 Device type: ${Platform.isAndroid ? 'android' : 'ios'}');
        print('🔑 FCM Token length: ${token.length} chars');
      }

      final apiService = ApiService();
      final response = await apiService.post('/fcm/register', {
        'token': token,
        'device_type': Platform.isAndroid ? 'android' : 'ios',
        'device_info': Platform.operatingSystem,
      });

      if (kDebugMode) {
        print('✅ FCM token registered successfully with backend');
        print('📊 Response: $response');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error registering FCM token: $e');
        print('❌ Error type: ${e.runtimeType}');
        if (e is Exception) {
          print('❌ Exception details: ${e.toString()}');
        }
      }
    }
  }

  // Handle foreground message (when app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('📩 Foreground message received: ${message.messageId}');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
    }
    // Notification will be automatically displayed by FCM
    // iOS: setForegroundNotificationPresentationOptions will handle it
    // Android: notification will show automatically
  }

  // Handle notification tap (from FCM)
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('📲 Notification tapped: ${message.messageId}');
      print('Data: ${message.data}');
    }

    // Navigate to appropriate screen based on notification type
    final type = message.data['type'];
    final referenceId = message.data['reference_id'];

    _navigateToScreen(type, referenceId);
  }


  // Navigate to appropriate screen based on notification type
  void _navigateToScreen(String? type, String? referenceId) {
    // TODO: Implement navigation logic based on notification type
    // Example:
    // if (type == 'tagihan') {
    //   navigatorKey.currentState?.pushNamed('/tagihan', arguments: referenceId);
    // } else if (type == 'pembayaran') {
    //   navigatorKey.currentState?.pushNamed('/pembayaran-detail', arguments: referenceId);
    // }
    
    if (kDebugMode) {
      print('🧭 Navigate to $type screen with ID: $referenceId');
    }
  }

  // Unregister FCM token (on logout)
  Future<void> unregister() async {
    try {
      if (_fcmToken == null) return;

      final apiService = ApiService();
      await apiService.post('/fcm/unregister', {
        'token': _fcmToken,
      });

      if (kDebugMode) print('✅ FCM token unregistered');
      _fcmToken = null;
    } catch (e) {
      if (kDebugMode) print('❌ Error unregistering FCM token: $e');
    }
  }

  // Get current FCM token
  String? get fcmToken => _fcmToken;

  // Check if FCM is initialized
  bool get isInitialized => _isInitialized;
}
