import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';
import 'package:mobile_app/services/firebase_messaging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;
import 'homepage.dart';
import 'information_page.dart';
import 'calendar_page.dart';

class MainNavigation extends StatefulWidget {
  final Map student;
  final List classes;
  final List studyDays;
  final List exams;

  const MainNavigation({
    Key? key,
    required this.student,
    required this.classes,
    required this.studyDays,
    required this.exams,
  }) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  late Map student;
  late List classes;
  late List studyDays;
  late List exams;
  List results = [];

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    student = widget.student;
    classes = List.from(widget.classes);
    studyDays = List.from(widget.studyDays);
    exams = List.from(widget.exams);
    FirebaseMessagingService.initialize(context);
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      List newClasses = [];
      List newStudyDays = [];
      List newExams = [];
      List newResults = [];

      var classField = student['class'];
      List classIds = [];
      if (classField is List) {
        classIds = classField;
      } else if (classField is String && classField.isNotEmpty) {
        classIds = [classField];
      }

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

      final resultRes = await http.get(
        Uri.parse(
          'https://api-ielts-cgn8.onrender.com/api/Result/student/${student['id']}',
        ),
      );
      if (resultRes.statusCode == 200) {
        newResults = json.decode(resultRes.body);
      }

      setState(() {
        classes = newClasses;
        studyDays = newStudyDays;
        exams = newExams;
        results = newResults;
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    final uid = student['id'].toString();
    await FirebaseDatabase.instance.ref('presence/online/$uid').remove();

    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  List<Widget> get pages => [
        HomePage(
          student: student,
          classes: classes,
          studyDays: studyDays,
          exams: exams,
          results: results,
        ),
        InformationPage(student: student, onLogout: _logout),
        CalendarPage(studyDays: studyDays),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Info'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
        ],
      ),
    );
  }
}
