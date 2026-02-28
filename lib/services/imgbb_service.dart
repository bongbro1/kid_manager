import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ImgBBService {
  static const String apiKey = '4b19f58fc08dff27c48d9728434fac5b';

  static Future<String> updateUserPhoto({
    required File file,
    required String field,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');

    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);

    final uri = Uri.parse('https://api.imgbb.com/1/upload');

    final res = await http.post(
      uri,
      body: {
        'key': apiKey,
        'image': base64Image,
      },
    );

    if (res.statusCode != 200) {
      throw Exception('ImgBB upload failed: ${res.statusCode}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>?;
    final url = data?['url'] as String?;

    if (url == null || url.isEmpty) {
      throw Exception('ImgBB response missing url');
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        field: url,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return url;
  }
}