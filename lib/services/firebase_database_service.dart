import 'package:firebase_database/firebase_database.dart';

class FirebaseDatabaseService {
  static final _db = FirebaseDatabase.instance;

  static Future<void> saveToken(String studentId, String token) async {
    await _db.ref('Tokens/$studentId/fcmToken').set(token);
  }
}
