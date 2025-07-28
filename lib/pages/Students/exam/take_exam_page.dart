import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TakeExamPage extends StatefulWidget {
  final Map exam;
  final int studentId;

  const TakeExamPage({super.key, required this.exam, required this.studentId});

  @override
  State<TakeExamPage> createState() => _TakeExamPageState();
}

class _TakeExamPageState extends State<TakeExamPage> {
  List<Map<String, dynamic>> questions = [];
  Map<int, dynamic> answers = {};
  bool isLoading = true;
  Timer? countdownTimer;
  Duration remaining = Duration.zero;

  DateTime? startTime;
  DateTime? endTime;

  // ✅ KHÔNG ép UTC – giữ nguyên giờ như từ backend (giờ VN)
  DateTime parseVietnamTime(String timeStr) {
    return DateTime.parse(timeStr); // Không ép toUtc(), giữ nguyên giờ VN
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchQuestions();
    });
  }

  Future<void> fetchQuestions() async {
    try {
      final examId = widget.exam['examId'] ?? widget.exam['id'];
      if (examId == null) {
        _showError("Thiếu ExamId từ widget.exam");
        return;
      }

      try {
        startTime = parseVietnamTime(widget.exam['startTime']);
        endTime = parseVietnamTime(widget.exam['endTime']);
      } catch (_) {
        _showError("Sai định dạng thời gian Start hoặc End");
        return;
      }

      final now = DateTime.now(); // Local time (VN Time)

      debugPrint("StartTime (VN): $startTime");
      debugPrint("EndTime   (VN): $endTime");
      debugPrint("Now       (VN): $now");

      if (now.isBefore(startTime!)) {
        _showError("Bài thi chưa bắt đầu");
        return;
      }
      if (now.isAfter(endTime!)) {
        _showError("Bài thi đã kết thúc");
        return;
      }

      final res = await http.get(
        Uri.parse(
          'https://api-ielts-cgn8.onrender.com/api/Exam/$examId/questions',
        ),
      );

      if (res.statusCode != 200) {
        _showError("Không tải được câu hỏi");
        return;
      }

      final data = json.decode(res.body);
      if (data is! List) {
        _showError("Phản hồi từ API không đúng định dạng danh sách");
        return;
      }

      final List raw = data;
      setState(() {
        questions = raw.map((q) => Map<String, dynamic>.from(q)).toList();
        isLoading = false;
        remaining = endTime!.difference(now);
      });

      startCountdown();
    } catch (e) {
      _showError("Lỗi: $e");
    }
  }

  void startCountdown() {
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (remaining.inSeconds <= 1) {
          timer.cancel();
          _submitAnswers(auto: true);
        } else {
          remaining = remaining - const Duration(seconds: 1);
        }
      });
    });
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  void _showError(String msg) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Lỗi"),
          content: Text(msg),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("OK", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    });
  }

  String formatTime(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "${d.inHours.toString().padLeft(2, '0')}:$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final examTitle = widget.exam['title'] ?? 'Exam';

    return Scaffold(
      appBar: AppBar(
        title: Text(examTitle),
        actions: [
          if (!isLoading)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  "Còn lại: ${formatTime(remaining)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : questions.isEmpty
          ? const Center(child: Text("Không có câu hỏi nào."))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final q = questions[index];
                  return _buildQuestionWidget(q, index + 1);
                },
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () => _submitAnswers(),
          child: const Text("Nộp Bài"),
        ),
      ),
    );
  }

  Widget _buildQuestionWidget(Map q, int number) {
    final qId = q['questionId'];
    final selected = answers[qId];
    final isMultiple = q['isMultipleChoice'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Câu $number: ${q['content']}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            isMultiple
                ? Column(
                    children: List.generate(
                      q['choices']?.length ?? 0,
                      (i) => RadioListTile(
                        title: Text(q['choices'][i].toString()),
                        value: i,
                        groupValue: selected,
                        onChanged: (val) => setState(() => answers[qId] = val),
                      ),
                    ),
                  )
                : TextFormField(
                    initialValue: selected?.toString(),
                    onChanged: (val) => answers[qId] = val,
                    decoration: const InputDecoration(labelText: "Câu trả lời"),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitAnswers({bool auto = false}) async {
    final examId = widget.exam['examId'] ?? widget.exam['id'];
    final int totalQuestions = questions.length;

    List<String> answerList = [];

    for (var q in questions) {
      final ans = answers[q['questionId']];
      if (ans == null) {
        answerList.add("");
      } else if (q['isMultipleChoice'] == true) {
        final cleaned = q['choices'][ans]?.toString().trim() ?? "";
        answerList.add(cleaned);
      } else {
        answerList.add(ans.toString().trim());
      }
    }

    final now = DateTime.now(); // VN time
    final int durationSeconds = now.difference(startTime!).inSeconds;

    final body = {
      "studentId": widget.studentId,
      "examId": examId,
      "answers": answerList,
      "durationSeconds": durationSeconds,
    };

    try {
      final res = await http.post(
        Uri.parse(
          "https://api-ielts-cgn8.onrender.com/api/Exam/$examId/submit",
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint("Status Code: ${res.statusCode}");
      debugPrint("Response Body: ${res.body}");
      debugPrint("Request body: ${jsonEncode(body)}");

      if (res.statusCode == 200) {
        final result = json.decode(res.body);
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Kết quả"),
            content: Text(
              "Điểm: ${result['score']}/${result['totalScore']}\n${result['remark']}",
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } else {
        throw Exception("Nộp bài thất bại");
      }
    } catch (e) {
      if (!mounted) return;
      _showError("Lỗi khi nộp bài: $e");
    }
  }
}
