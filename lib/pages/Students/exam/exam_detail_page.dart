import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'take_exam_page.dart';

class ExamDetailPage extends StatefulWidget {
  final Map<String, dynamic> exam;
  final int studentId;

  const ExamDetailPage({
    super.key,
    required this.exam,
    required this.studentId,
  });

  @override
  State<ExamDetailPage> createState() => _ExamDetailPageState();
}

class _ExamDetailPageState extends State<ExamDetailPage> {
  bool hasTaken = false;
  Map<String, dynamic>? resultData;
  List<dynamic> questions = [];
  bool isLoading = true;
  bool showAnswers = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final examId = widget.exam['examId'] ?? widget.exam['id'];
    final studentId = widget.studentId;

    try {
      final checkRes = await http.get(
        Uri.parse(
          'https://api-ielts-cgn8.onrender.com/api/Exam/$examId/student/$studentId/check',
        ),
      );
      if (checkRes.statusCode == 200) {
        final check = json.decode(checkRes.body);
        if (check['hasTaken'] == true) {
          setState(() => hasTaken = true);
          await _fetchResult(examId, studentId);
          await _fetchQuestions(examId);
        }
      }
    } catch (e) {
      debugPrint("Lỗi kiểm tra trạng thái: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchResult(int examId, int studentId) async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://api-ielts-cgn8.onrender.com/api/Result/student/$studentId/exam/$examId',
        ),
      );
      if (res.statusCode == 200) {
        resultData = json.decode(res.body);
      }
    } catch (e) {
      debugPrint("Lỗi lấy kết quả: $e");
    }
  }

  Future<void> _fetchQuestions(int examId) async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://api-ielts-cgn8.onrender.com/api/Exam/$examId/questions',
        ),
      );
      if (res.statusCode == 200) {
        questions = json.decode(res.body);
      }
    } catch (e) {
      debugPrint("Lỗi lấy câu hỏi: $e");
    }
  }

  void _startExam() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TakeExamPage(exam: widget.exam, studentId: widget.studentId),
      ),
    );
  }

  Widget _buildAnswerDetails() {
    final answers = resultData?['answers'];
    if (questions.isEmpty || answers == null) {
      return const Text("Không thể hiển thị chi tiết câu trả lời.");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(questions.length, (index) {
        final q = questions[index];
        final userAnswer = answers.length > index ? answers[index] : "";
        final isMultiple = q['isMultipleChoice'] == true;
        final correctAnswer = isMultiple
            ? (q['choices']?[q['correctAnswerIndex']] ?? "")
            : (q['correctInputAnswer'] ?? "");

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text("Câu ${index + 1}: ${q['content']}"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text("📝 Bạn chọn: $userAnswer"),
                Text(
                  "✅ Đáp án đúng: $correctAnswer",
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildResultSection() {
    if (resultData == null) return const Text("Không tìm thấy kết quả.");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "✅ Bạn đã làm bài thi này",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  "📊 Điểm: ${resultData!['score']} / ${resultData!['totalScore']}",
                ),
                Text("🕒 Thời gian: ${resultData!['durationSeconds']} giây"),
                Text("🗓 Nộp lúc: ${resultData!['timestamp']}"),
                Text("📝 Ghi chú: ${resultData!['remark']}"),
              ],
            ),
          ),
        ),
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() => showAnswers = !showAnswers),
            icon: Icon(showAnswers ? Icons.visibility_off : Icons.visibility),
            label: Text(
              showAnswers ? "Ẩn câu trả lời" : "Xem chi tiết câu trả lời",
            ),
          ),
        ),
        if (showAnswers) _buildAnswerDetails(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final examTitle = widget.exam['title'] ?? 'Exam';
    final examDate = widget.exam['examDate'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin bài thi')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("📝 Tên bài thi:", style: _boldStyle),
                        const SizedBox(height: 4),
                        Text(examTitle),
                        const SizedBox(height: 12),
                        Text("📅 Ngày thi:", style: _boldStyle),
                        const SizedBox(height: 4),
                        Text(examDate),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                hasTaken
                    ? _buildResultSection()
                    : FilledButton(
                        onPressed: _startExam,
                        child: const Text("Làm bài"),
                      ),
              ],
            ),
    );
  }

  TextStyle get _boldStyle =>
      const TextStyle(fontWeight: FontWeight.bold, fontSize: 16);
}
