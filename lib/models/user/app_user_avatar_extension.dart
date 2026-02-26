import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:kid_manager/models/app_user.dart';

extension AppUserAvatar on AppUser {

  Future<Uint8List> loadAvatarBytes() async {
    try {
      // Nếu có avatarUrl
      if (photoUrl != null && photoUrl!.isNotEmpty) {
        final res = await http.get(Uri.parse(photoUrl!));
        if (res.statusCode == 200) {
          return res.bodyBytes;
        }
      }

      // Nếu không có avatarUrl → dùng mặc định
      final data = await rootBundle.load("assets/images/avatar_default.png");
      print("BYTE LENGTH: ${data.lengthInBytes}");
      return data.buffer.asUint8List();

    } catch (e) {
      // Nếu lỗi mạng → fallback default
      final data = await rootBundle.load("assets/images/avatar_default.png");
      return data.buffer.asUint8List();
    }
  }
}