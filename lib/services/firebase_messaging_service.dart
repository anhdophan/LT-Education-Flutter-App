import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobile_app/pages/Students/global_user_info.dart';
import 'package:mobile_app/services/firebase_database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/Students/chatpage.dart';

class FirebaseMessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize(BuildContext context) async {
    // Cấu hình kênh notification
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null) {
          _handleNotificationClick(context, payload);
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Gửi token FCM lên server Firebase
    _messaging.getToken().then((token) async {
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        final studentId = prefs.getString("studentId");
        if (studentId != null) {
          print("🔥 FCM Token: $token");
          await FirebaseDatabaseService.saveToken(studentId, token);
        }
      }
    });

    // Lắng nghe khi app đang mở
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
      _incrementUnreadBadge(); // ➕ tăng badge mỗi khi nhận chat
    });

    // Khi app được mở từ background bằng thông báo
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final payload = message.data['type'];
      if (payload != null) {
        _handleNotificationClick(context, payload);
      }
    });

    // Khi app khởi động từ terminated state do click thông báo
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null && initialMessage.data['type'] != null) {
      _handleNotificationClick(context, initialMessage.data['type']!);
    }
  }

  static void _handleNotificationClick(BuildContext context, String payload) {
    if (payload == "chat") {
      final classId = GlobalUserInfo.classId;
      final userId = GlobalUserInfo.studentId;
      final userName = GlobalUserInfo.studentName;

      if (classId != null && userId != null && userName != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(
              classId: classId,
              userId: userId,
              userName: userName,
              classmates: [], // bạn có thể load danh sách nếu cần
            ),
          ),
        );
      } else if (payload == "exam") {
        print("Thiếu thông tin để mở ExamDetailPage.");
      }
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? data['title'] ?? "Thông báo mới";
    final body = notification?.body ?? data['body'] ?? data['message'] ?? "";

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      platformDetails,
      payload: data['type'] ?? '',
    );
    print("🔥 Showing notification with title: $title and body: $body");
  }

  static Future<void> _incrementUnreadBadge() async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt("unread_count") ?? 0;
    prefs.setInt("unread_count", current + 1);
  }

  static Future<int> getUnreadBadgeCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("unread_count") ?? 0;
  }

  static Future<void> resetUnreadBadge() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("unread_count", 0);
  }
}
