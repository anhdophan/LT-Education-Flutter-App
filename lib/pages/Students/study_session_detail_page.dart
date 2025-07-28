// ------------------- study_session_detail_page.dart -------------------
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class StudySessionDetailPage extends StatefulWidget {
  final int sessionId;
  const StudySessionDetailPage({super.key, required this.sessionId});

  @override
  State<StudySessionDetailPage> createState() => _StudySessionDetailPageState();
}

class _StudySessionDetailPageState extends State<StudySessionDetailPage> {
  Map? _session;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final url =
        'https://api-ielts-cgn8.onrender.com/api/StudySession/${widget.sessionId}';
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        setState(() {
          _session = json.decode(res.body);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        appBar: AppBar(title: const Text('Study Session')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _session == null
            ? const Center(child: Text('Cannot load session data'))
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailRow('Material', _session!['material']),
                        _detailRow('Detail', _session!['detail']),
                        _detailRow(
                          'Created',
                          _session!['dateCreated']
                                  ?.toString()
                                  .split('T')
                                  .first ??
                              '',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Expanded(child: Text(value ?? '')),
        ],
      ),
    );
  }
}
