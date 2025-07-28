import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String classId;
  final String userId;
  final String userName;
  final List<Map<String, dynamic>> classmates; // {userId, name}

  const ChatPage({
    Key? key,
    required this.classId,
    required this.userId,
    required this.userName,
    required this.classmates,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  String? _selectedReceiverId;
  String? _selectedReceiverName;

  late DatabaseReference _chatRef;

  @override
  void initState() {
    super.initState();
    _setClassChat();
  }

  void _setClassChat() {
    setState(() {
      _selectedReceiverId = null;
      _selectedReceiverName = null;
      _chatRef = _dbRef.child('chats/class/${widget.classId}');
    });
  }

  void _setPrivateChat(String receiverId, String receiverName) {
    final ids = [widget.userId, receiverId]..sort();
    final path = 'chats/private/${ids.join('-')}';
    setState(() {
      _selectedReceiverId = receiverId;
      _selectedReceiverName = receiverName;
      _chatRef = _dbRef.child(path);
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final message = {
      'senderId': widget.userId,
      'senderName': widget.userName,
      'content': text,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _chatRef.push().set(message);
    _messageController.clear();
  }

  Widget _buildMessageTile(Map msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                msg['senderName'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            Text(msg['content'] ?? ''),
            const SizedBox(height: 4),
            Text(
              _formatTime(msg['timestamp']),
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String? timestamp) {
    try {
      final dt = DateTime.parse(timestamp!);
      return DateFormat('HH:mm dd/MM').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatTitle = _selectedReceiverId == null
        ? '💬 Chat lớp ${widget.classId}'
        : '📩 ${_selectedReceiverName}';

    return Scaffold(
      appBar: AppBar(
        title: Text(chatTitle),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.group),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'class', child: Text('💬 Chat lớp')),
              ...widget.classmates
                  .where((s) => s['userId'] != widget.userId)
                  .map(
                    (s) => PopupMenuItem(
                      value: s['userId'],
                      child: Text(s['name']),
                    ),
                  ),
            ],
            onSelected: (val) {
              if (val == 'class') {
                _setClassChat();
              } else {
                final selected = widget.classmates.firstWhere(
                  (s) => s['userId'] == val,
                );
                _setPrivateChat(selected['userId'], selected['name']);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _chatRef.orderByChild('timestamp').onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text('Chưa có tin nhắn'));
                }

                final data = Map<String, dynamic>.from(
                  snapshot.data!.snapshot.value as Map,
                );

                final messages =
                    data.entries.map((e) {
                      final msg = Map<String, dynamic>.from(e.value);
                      return {...msg, 'key': e.key};
                    }).toList()..sort(
                      (a, b) => (a['timestamp'] ?? '').compareTo(
                        b['timestamp'] ?? '',
                      ),
                    );

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMe = msg['senderId'] == widget.userId;
                    return _buildMessageTile(msg, isMe);
                  },
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                  ),
                ),
              ),
              IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
            ],
          ),
        ],
      ),
    );
  }
}
