import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'exam_result_page.dart';

class ExamResultListPage extends StatefulWidget {
  final int studentId;

  const ExamResultListPage({super.key, required this.studentId});

  @override
  State<ExamResultListPage> createState() => _ExamResultListPageState();
}

class _ExamResultListPageState extends State<ExamResultListPage> {
  List<dynamic> results = [];
  List<dynamic> exams = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadResults();
  }

  Future<void> loadResults() async {
    try {
      final resResult = await http.get(
        Uri.parse(
          'https://api-ielts-cgn8.onrender.com/api/Result/student/${widget.studentId}',
        ),
      );
      final resExam = await http.get(
        Uri.parse('https://api-ielts-cgn8.onrender.com/api/Exam/all'),
      );

      if (resResult.statusCode == 200 && resExam.statusCode == 200) {
        final resultList = jsonDecode(resResult.body);
        final examList = jsonDecode(resExam.body);

        setState(() {
          results = resultList;
          exams = examList;
          isLoading = false;
        });
      } else {
        throw Exception("Lỗi khi tải dữ liệu.");
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  Map<String, dynamic>? findExamById(int examId) {
    return exams.firstWhere((e) => e['examId'] == examId, orElse: () => null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Danh sách kết quả")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : results.isEmpty
          ? const Center(child: Text("Bạn chưa làm bài thi nào."))
          : ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index];
                final exam = findExamById(result['examId']) ?? {};
                final examTitle = exam['title'] ?? "Không rõ";
                final timestamp = DateTime.tryParse(result['timestamp'] ?? "");

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(examTitle),
                    subtitle: Text(
                      "Điểm: ${result['score']} | Nộp: ${timestamp != null ? "${timestamp.day}/${timestamp.month}/${timestamp.year}" : 'Không rõ'}",
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExamResultPage(
                            exam: exam,
                            studentId: widget.studentId,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
