import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class InformationPage extends StatefulWidget {
  final Map student;
  final VoidCallback onLogout;
  const InformationPage({
    super.key,
    required this.student,
    required this.onLogout,
  });

  @override
  State<InformationPage> createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  late Map student;

  @override
  void initState() {
    super.initState();
    student = Map.from(widget.student);
  }

  Future<void> _logout() async {
    widget.onLogout();
  }

  Future<String?> _uploadToCloudinary(File imageFile) async {
    const cloudName = 'df8kdfa66';
    const uploadPreset = 'ml_default';

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      final data = json.decode(respStr);
      return data['secure_url'];
    }
    return null;
  }

  Future<void> _showEditDialog() async {
    final avatarController = TextEditingController(
      text: student['avatar'] ?? '',
    );
    final emailController = TextEditingController(text: student['email'] ?? '');
    final passwordController = TextEditingController();
    final phoneController = TextEditingController(
      text: student['phoneNumber'] ?? '',
    );

    File? pickedImage;
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text('Edit Information'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            pickedImage = File(picked.path);
                          });
                        }
                      },
                      child: CircleAvatar(
                        radius: 44,
                        backgroundImage: pickedImage != null
                            ? FileImage(pickedImage!)
                            : (avatarController.text.isNotEmpty
                                      ? NetworkImage(avatarController.text)
                                      : null)
                                  as ImageProvider<Object>?,
                        child:
                            pickedImage == null && avatarController.text.isEmpty
                            ? const Icon(Icons.camera_alt, size: 40)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload),
                      label: const Text('Upload Image'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.blueGrey[700],
                      ),
                      onPressed: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            pickedImage = File(picked.path);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (emailController.text.trim().isEmpty ||
                              !emailController.text.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a valid email.'),
                              ),
                            );
                            return;
                          }
                          if (phoneController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a phone number.'),
                              ),
                            );
                            return;
                          }

                          setStateDialog(() => isSaving = true);

                          String? avatarUrl = avatarController.text.trim();
                          if (pickedImage != null) {
                            final uploadedUrl = await _uploadToCloudinary(
                              pickedImage!,
                            );
                            if (uploadedUrl != null) avatarUrl = uploadedUrl;
                          }

                          Map<String, dynamic> updated = {
                            "studentId": student['studentId'],
                            "name": student['name'],
                            "class": student['class'].toString(),
                            "score": student['score'],
                            "studyingCourse": student['studyingCourse'],
                            "avatar": avatarUrl,
                            "email": emailController.text.trim().isNotEmpty
                                ? emailController.text.trim()
                                : student['email'],
                            "username": emailController.text.trim().isNotEmpty
                                ? emailController.text.trim()
                                : student['username'],
                            "password":
                                passwordController.text.trim().isNotEmpty
                                ? passwordController.text.trim()
                                : student['password'],
                            "phoneNumber":
                                phoneController.text.trim().isNotEmpty
                                ? phoneController.text.trim()
                                : student['phoneNumber'],
                          };

                          final res = await http.put(
                            Uri.parse(
                              'https://api-ielts-cgn8.onrender.com/api/Student/${student['studentId']}',
                            ),
                            headers: {'Content-Type': 'application/json'},
                            body: json.encode(updated),
                          );

                          setStateDialog(() => isSaving = false);

                          if (res.statusCode == 200) {
                            setState(() {
                              student = {...student, ...updated};
                            });
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Update successful!'),
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Update failed: ${res.body}'),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Information'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _showEditDialog),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Logout"),
                  content: const Text("Are you sure you want to log out?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Logout"),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                widget.onLogout();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showEditDialog,
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(student['avatar'] ?? ''),
                    radius: 56,
                    child: student['avatar'] == null
                        ? const Icon(Icons.camera_alt, size: 40)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to edit photo',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              student['name'] ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              student['email'] ?? '',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInfoTile(
                    icon: Icons.class_,
                    title: 'Class',
                    value: student['class']?.toString() ?? '',
                  ),
                  const Divider(height: 1),
                  _buildInfoTile(
                    icon: Icons.phone,
                    title: 'Phone Number',
                    value: student['phoneNumber'] ?? '',
                  ),
                  const Divider(height: 1),
                  _buildInfoTile(
                    icon: Icons.score,
                    title: 'Score',
                    value: student['score']?.toString() ?? '',
                  ),
                  const Divider(height: 1),
                  _buildInfoTile(
                    icon: Icons.person_outline,
                    title: 'Username',
                    value: student['username'] ?? '',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blueGrey.withOpacity(0.1),
            child: Icon(icon, color: Colors.blueGrey, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
