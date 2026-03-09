import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:path/path.dart';

class FirebaseStorageService {
  static Future<String> uploadUserPhoto({
    required File file,
    required String uid,
    required UserPhotoType type,
  }) async {
    final fileName = basename(file.path);

    final ref = FirebaseStorage.instance
        .ref()
        .child('users')
        .child(uid)
        .child(type == UserPhotoType.avatar ? 'avatar_$fileName' : 'cover_$fileName');

    final uploadTask = await ref.putFile(file);

    final downloadUrl = await uploadTask.ref.getDownloadURL();

    return downloadUrl;
  }
}