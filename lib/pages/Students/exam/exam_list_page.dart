import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ExamListPage extends StatefulWidget {
  final int studentClassId; // Class ID của học sinh

  const ExamListPage({Key? key, required this.studentClassId})
    : super(key: key);

  @override
  State<ExamListPage> createState() => _ExamListPageState();
}

class _ExamListPageState extends State<ExamListPage> {
  List<dynamic> exams = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchExams();
  }

  Future<void> fetchExams() async {
    final url = Uri.parse('https://api-ielts-cgn8.onrender.com/api/Exam/all');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final filtered = data
            .where((exam) => exam['idClass'] == widget.studentClassId)
            .toList();

        setState(() {
          exams = filtered;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load exams');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void goToExamDetail(Map<String, dynamic> exam) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExamDetailPage(exam: exam)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bài thi sẵn sàng")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : exams.isEmpty
          ? const Center(child: Text("Không có bài thi nào."))
          : ListView.builder(
              itemCount: exams.length,
              itemBuilder: (context, index) {
                final exam = exams[index];
                return ListTile(
                  title: Text(exam['title'] ?? 'Không có tiêu đề'),
                  subtitle: Text(
                    "Ngày thi: ${exam['examDate']?.toString().split('T')[0] ?? ''}",
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => goToExamDetail(exam),
                );
              },
            ),
    );
  }
}

class ExamDetailPage extends StatelessWidget {
  final Map<String, dynamic> exam;

  const ExamDetailPage({Key? key, required this.exam}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final examDate = exam['examDate']?.toString().split('T')[0] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết bài thi")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tiêu đề: ${exam['title']}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("Ngày thi: $examDate"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to Take Exam Page
              },
              child: const Text("Làm bài thi"),
            ),
          ],
        ),
      ),
    );
  }
}
