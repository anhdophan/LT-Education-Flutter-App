import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/pages/Students/global_user_info.dart';
import 'chatpage.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import './exam/exam_detail_page.dart';
import './study_session_detail_page.dart';

class HomePage extends StatefulWidget {
  final Map student;
  final List classes;
  final List studyDays;
  final List exams;
  final List results;

  const HomePage({
    super.key,
    required this.student,
    required this.classes,
    required this.studyDays,
    required this.exams,
    required this.results,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List _studySessions = [];
  bool _loadingSession = true;

  TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredExams = [];

  @override
  void initState() {
    super.initState();
    _fetchStudySessions();
    _filteredExams = widget.exams.map((e) {
      final m = Map<String, dynamic>.from(e);
      m['id'] ??= m['examId'];
      return m;
    }).toList();
  }

  void _searchExams(String query) {
    final exams = widget.exams.map((e) {
      final m = Map<String, dynamic>.from(e);
      m['id'] ??= m['examId'];
      return m;
    }).toList();

    setState(() {
      _filteredExams = exams.where((exam) {
        final title = (exam['title'] ?? '').toString().toLowerCase();
        final date = (exam['examDate'] ?? '').toString().split('T')[0];
        return title.contains(query.toLowerCase()) || date.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchStudySessions() async {
    final classField = widget.student['class'];
    final classId = classField is List ? classField.first : classField;

    if (classId == null || classId.toString().isEmpty) {
      setState(() => _loadingSession = false);
      return;
    }

    final url =
        'https://api-ielts-cgn8.onrender.com/api/StudySession/class?classId=$classId';

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        setState(() {
          _studySessions = json.decode(res.body);
          _loadingSession = false;
        });
      } else {
        setState(() => _loadingSession = false);
      }
    } catch (e) {
      setState(() => _loadingSession = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: AppColors.primary,
                expandedHeight: 140,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  title: Text(
                    'Hi, ${widget.student['name'] ?? 'Student'}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppColors.white,
                    ),
                  ),
                  background: _buildHeaderInfo(),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildTimelineSection(context),
                    const SizedBox(height: 12),
                    _buildClassSection(context),
                    const SizedBox(height: 12),
                    _buildStudySessionSection(context),
                    const SizedBox(height: 12),
                    _buildCalendarSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Row(
      children: [
        const SizedBox(width: 16),
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: 26,
            backgroundImage: widget.student['avatar'] != null
                ? NetworkImage(widget.student['avatar'])
                : null,
            child: widget.student['avatar'] == null
                ? const Icon(Icons.person, size: 30)
                : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              widget.student['email'] ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildTimelineSection(BuildContext context) {
    final completedExamIds = widget.results.map((r) => r['idExam']).toSet();

    return _SectionCard(
      title: 'Upcoming Exams',
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Tìm kiếm bài thi theo tên hoặc ngày (yyyy-mm-dd)',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            onChanged: _searchExams,
          ),
          const SizedBox(height: 8),
          if (_filteredExams.isEmpty)
            const Text("Không có bài thi nào phù hợp."),
          ..._filteredExams.take(5).map((exam) {
            final date = exam['examDate']?.split('T')[0] ?? 'Unknown';
            final isCompleted = completedExamIds.contains(exam['id']);

            return ListTile(
              leading: Icon(
                Icons.assignment,
                color: isCompleted ? Colors.green : AppColors.primary,
              ),
              title: Row(
                children: [
                  Expanded(child: Text(exam['title'] ?? 'No title')),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Text(
                        'Đã làm',
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ),
                ],
              ),
              subtitle: Text('Ngày thi: $date'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExamDetailPage(
                      exam: exam,
                      studentId: widget.student['studentId'],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildClassSection(BuildContext context) {
    final className =
        widget.classes.isNotEmpty ? widget.classes.first['name'] : 'Unknown';

    final classId = () {
      if (widget.classes.isNotEmpty && widget.classes.first['id'] != null) {
        return widget.classes.first['id'];
      }
      final studentClass = widget.student['class'];
      if (studentClass is List && studentClass.isNotEmpty) {
        return studentClass.first;
      } else if (studentClass is String && studentClass.isNotEmpty) {
        return studentClass;
      }
      return null;
    }();
    print('DEBUG: classId = $classId');
    print('classId runtimeType: ${classId.runtimeType}');
    print('classes type: ${widget.classes.runtimeType}');
    print('classId type: ${classId.runtimeType}');
    print('classId: $classId');

    final studentId = widget.student['studentId'];
    final studentName = widget.student['name'] ?? 'Student';
    GlobalUserInfo.classId = classId?.toString();
    GlobalUserInfo.studentId = studentId?.toString();
    GlobalUserInfo.studentName = studentName;

    print('studentName: $studentName');
    print('studentId: $studentId');
    return _SectionCard(
      title: 'Classroom Chat',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            className,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          if (classId != null)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      classId: classId.toString(),
                      userId: studentId.toString(),
                      userName: studentName,
                      classmates: [],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Chat with your class'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            )
          else
            const Text(
              "You haven't been assigned to a class yet.",
              style: TextStyle(color: Colors.redAccent),
            ),
        ],
      ),
    );
  }

  Widget _buildStudySessionSection(BuildContext context) {
    return _SectionCard(
      title: 'Study Sessions',
      child: _loadingSession
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          : (_studySessions.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No sessions found'),
                )
              : Column(
                  children: _studySessions.map((s) {
                    return ListTile(
                      leading: const Icon(
                        Icons.menu_book,
                        color: AppColors.primary,
                      ),
                      title: Text('Material: ${s['material']}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                StudySessionDetailPage(sessionId: s['id']),
                          ),
                        );
                      },
                    );
                  }).toList(),
                )),
    );
  }

  Widget _buildCalendarSection() {
    final now = DateTime.now();
    final week = List.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day - now.weekday + i + 1),
    );

    return _SectionCard(
      title: 'Study Calendar',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: week.map((day) {
          final matched = widget.studyDays.firstWhere(
            (d) =>
                d['date'] != null &&
                DateTime.tryParse(d['date']) != null &&
                DateUtils.isSameDay(DateTime.parse(d['date']), day),
            orElse: () => null,
          );
          final isToday = DateUtils.isSameDay(day, now);
          return Column(
            children: [
              Text(
                [
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thu',
                  'Fri',
                  'Sat',
                  'Sun'
                ][day.weekday - 1],
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              CircleAvatar(
                radius: 18,
                backgroundColor: isToday
                    ? AppColors.primary
                    : matched != null
                        ? Colors.green
                        : Colors.grey[300],
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isToday || matched != null
                        ? Colors.white
                        : AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
