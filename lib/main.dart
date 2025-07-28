import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'theme/app_theme.dart';
import './pages/role_selection_page.dart';
import './pages/Students/main_navigation.dart';
import './pages/Students/loginpage.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/firebase_messaging_service.dart';

// 🔔 Handler khi có message ở background (notification dạng data-only)
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("📦 Background FCM: ${message.messageId}");
  print("📦 Data: ${message.data}");
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Đăng ký background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  // ✅ Xử lý khi app bị kill và mở từ notification
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    print(
        "📦 App launched from terminated by notification: ${initialMessage.messageId}");
    print("📦 Data: ${initialMessage.data}");
    // TODO: Navigate tùy thuộc vào nội dung tin nhắn
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final studentId = prefs.getString('studentId');
    print("📍 studentId from prefs: $studentId");
    final studentStr = prefs.getString('student');

    if (studentStr != null) {
      try {
        final student = json.decode(studentStr);
        final studentId = student['id'].toString();

        // 🔔 Khởi động FCM sau khi đã có studentId
        await FirebaseMessagingService.initialize(navigatorKey.currentContext!);

        // Xử lý classIds an toàn
        List classIds = [];
        if (student['class'] is List) {
          classIds = student['class'];
        } else if (student['class'] is String && student['class'].isNotEmpty) {
          classIds = [student['class']];
        }

        List newClasses = [];
        List newStudyDays = [];
        List newExams = [];

        for (var classId in classIds) {
          final classRes = await http.get(
            Uri.parse('https://api-ielts-cgn8.onrender.com/api/Class/$classId'),
          );

          if (classRes.statusCode == 200) {
            final classDetail = json.decode(classRes.body);
            newClasses.add(classDetail);

            final studyRes = await http.get(
              Uri.parse(
                'https://api-ielts-cgn8.onrender.com/api/Class/$classId/studydays',
              ),
            );
            if (studyRes.statusCode == 200) {
              final studyList = json.decode(studyRes.body);
              for (var s in studyList) {
                s['classId'] = classId;
                newStudyDays.add(s);
              }
            }

            final examRes = await http.get(
              Uri.parse('https://api-ielts-cgn8.onrender.com/api/Exam/all'),
            );
            if (examRes.statusCode == 200) {
              final examList = json.decode(examRes.body);
              final classExams = examList
                  .where((e) => e['idClass'].toString() == classId.toString())
                  .toList();
              newExams.addAll(classExams);
            }
          }
        }

        return MainNavigation(
          student: student,
          classes: newClasses,
          studyDays: newStudyDays,
          exams: newExams,
        );
      } catch (e) {
        print('❌ Lỗi khi decode student hoặc gọi API: $e');
      }
    }

    return const RoleSelectionPage();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getInitialScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        } else if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(body: Center(child: Text('Lỗi: ${snapshot.error}'))),
          );
        } else if (snapshot.hasData) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey, // 🔑 Quan trọng để FCM điều hướng
            theme: AppTheme.lightTheme,
            home: snapshot.data!,
            routes: {
              '/login': (context) => const LoginPage(),
            },
          );
        } else {
          return const MaterialApp(home: RoleSelectionPage());
        }
      },
    );
  }
}
