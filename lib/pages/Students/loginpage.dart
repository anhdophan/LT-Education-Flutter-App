import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../theme/app_colors.dart';
import 'main_navigation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    Future<void> _setupFirebaseUser(Map student) async {
      final uid = student['id'].toString(); // sử dụng ID làm uid
      final name = student['fullName'] ?? student['username'];
      final classIds =
          student['class'] is List ? student['class'] : [student['class']];

      final ref = FirebaseDatabase.instance.ref();

      await ref.child('users/$uid').set({
        'name': name,
        'role': 'student',
        'classIds': classIds,
      });

      await ref.child('presence/online/$uid').set(true);
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('https://api-ielts-cgn8.onrender.com/api/Student/all'),
      );

      if (response.statusCode == 200) {
        final students = json.decode(response.body);
        final username = _usernameController.text.trim();
        final password = _passwordController.text.trim();

        final matchedStudent = students.firstWhere(
          (student) =>
              student['username'] == username &&
              student['password'] == password,
          orElse: () => null,
        );

        if (matchedStudent != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('student', json.encode(matchedStudent));
          await prefs.setString('studentId',
              matchedStudent['studentId'].toString()); // Lưu studentId

          await _setupFirebaseUser(matchedStudent);
          var classField = matchedStudent['class'];
          List classIds = [];
          if (classField is List) {
            classIds = classField;
          } else if (classField is String && classField.isNotEmpty) {
            classIds = [classField];
          }

          List classDetails = [];
          List allStudyDays = [];
          List allExams = [];

          for (var classId in classIds) {
            final classRes = await http.get(
              Uri.parse(
                'https://api-ielts-cgn8.onrender.com/api/Class/$classId',
              ),
            );
            if (classRes.statusCode == 200) {
              final classDetail = json.decode(classRes.body);
              classDetails.add(classDetail);

              final studyDays = await fetchStudyDays(classId);
              for (var day in studyDays) {
                day['classId'] = classId;
                allStudyDays.add(day);
              }

              final exams = await fetchExamsForClass(classId);
              allExams.addAll(exams);
            }
          }

          setState(() => _isLoading = false);

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => MainNavigation(
                student: matchedStudent,
                classes: classDetails,
                studyDays: allStudyDays,
                exams: allExams,
              ),
            ),
          );
        } else {
          setState(() => _isLoading = false);
          _showError('Sai tài khoản hoặc mật khẩu!');
        }
      } else {
        setState(() => _isLoading = false);
        _showError('Lỗi máy chủ. Vui lòng thử lại sau.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Đã xảy ra lỗi. Vui lòng kiểm tra kết nối mạng.');
    }
  }

  Future<List> fetchExamsForClass(dynamic classId) async {
    final res = await http.get(
      Uri.parse('https://api-ielts-cgn8.onrender.com/api/Exam/all'),
    );
    if (res.statusCode == 200) {
      List exams = json.decode(res.body);
      return exams
          .where((e) => e['idClass'].toString() == classId.toString())
          .toList();
    }
    return [];
  }

  Future<List> fetchStudyDays(String classId) async {
    final res = await http.get(
      Uri.parse(
        'https://api-ielts-cgn8.onrender.com/api/Class/$classId/studydays',
      ),
    );
    if (res.statusCode == 200) {
      return json.decode(res.body);
    }
    return [];
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Lỗi đăng nhập'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/header_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xCC000000), Color(0x00FFFFFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Login form
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Card(
                  elevation: 10,
                  color: Colors.white.withOpacity(0.95),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: AppColors.primary,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Image.asset('assets/lt_logo.png', height: 70),
                        const SizedBox(height: 12),
                        const Text(
                          'HỆ THỐNG HỌC TRỰC TUYẾN\nL&T EDUCATION',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Username
                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Tên đăng nhập',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Mật khẩu',
                            prefixIcon: Icon(Icons.lock),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Đăng nhập',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
