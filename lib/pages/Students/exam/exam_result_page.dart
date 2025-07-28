import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ExamResultPage extends StatefulWidget {
  final Map<String, dynamic> exam;
  final int studentId;

  const ExamResultPage({Key? key, required this.exam, required this.studentId})
    : super(key: key);

  @override
  State<ExamResultPage> createState() => _ExamResultPageState();
}

class _ExamResultPageState extends State<ExamResultPage> {
  Map<String, dynamic>? resultData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchResult();
  }

  Future<void> fetchResult() async {
    final examId = widget.exam['examId'];
    final url =
        "https://api-ielts-cgn8.onrender.com/api/Result/student/${widget.studentId}/exam/$examId";

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        setState(() {
          resultData = jsonDecode(res.body);
          isLoading = false;
        });
      } else {
        throw Exception("Result not found.");
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  Widget _buildAnswerDisplay(Map<String, dynamic> question, String userAnswer) {
    final isMultipleChoice = question['isMultipleChoice'] == true;
    final correctAnswerIndex = question['correctAnswerIndex'];
    final correctInputAnswer = question['correctInputAnswer'];

    bool isCorrect = false;

    if (isMultipleChoice) {
      isCorrect = int.tryParse(userAnswer) == correctAnswerIndex;
    } else {
      isCorrect =
          correctInputAnswer?.toLowerCase().trim() ==
          userAnswer.toLowerCase().trim();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMultipleChoice && question['choices'] != null)
          Text(
            "✔ Đáp án đúng: ${correctAnswerIndex != null && correctAnswerIndex < question['choices'].length ? question['choices'][correctAnswerIndex] : 'Không rõ'}",
            style: const TextStyle(color: Colors.green),
          ),
        if (!isMultipleChoice && correctInputAnswer != null)
          Text(
            "✔ Đáp án đúng: $correctInputAnswer",
            style: const TextStyle(color: Colors.green),
          ),
        const SizedBox(height: 4),
        Text(
          "❌ Câu trả lời của bạn: ${isMultipleChoice ? (int.tryParse(userAnswer) != null && int.parse(userAnswer) < question['choices'].length ? question['choices'][int.parse(userAnswer)] : "Không hợp lệ") : userAnswer}",
          style: TextStyle(color: isCorrect ? Colors.green : Colors.red),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.exam['questions'] as List<dynamic>?;

    return Scaffold(
      appBar: AppBar(title: const Text("Kết quả bài thi")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (resultData == null)
          ? const Center(child: Text("Không tìm thấy kết quả"))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "🎯 Điểm số: ${resultData!['score']} / ${resultData!['totalScore']}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "⏱️ Thời gian làm bài: ${_formatDuration(resultData!['durationSeconds'])}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    "🕒 Nộp lúc: ${_formatTimestamp(resultData!['timestamp'])}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Chi tiết câu hỏi:",
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: questions?.length ?? 0,
                      itemBuilder: (context, index) {
                        final question = questions![index];
                        final userAnswers = resultData!['answers'] ?? [];
                        final userAnswer = index < userAnswers.length
                            ? userAnswers[index].toString()
                            : '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Câu ${index + 1}: ${question['content']}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildAnswerDisplay(question, userAnswer),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.home),
                      label: const Text("Quay lại trang chính"),
                      onPressed: () =>
                          Navigator.popUntil(context, (route) => route.isFirst),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return "${twoDigits(h)}:${twoDigits(m)}:${twoDigits(s)}";
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "Không xác định";
    }
  }
}
