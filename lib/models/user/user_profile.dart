import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserProfile {
  final String id;
  final String name;
  final String phone;
  final String gender;
  final String dob;
  final String address;
  final bool allowTracking;

  final String? role;

  // 🔥 thêm mới (nullable)
  final String? avatarUrl;
  final String? coverUrl;

  UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.gender,
    required this.dob,
    required this.address,
    required this.allowTracking,
    this.role,
    this.avatarUrl,
    this.coverUrl,
  });

  /// 🔹 Convert sang Firestore
  Map<String, dynamic> toMap() {
    final data = {
      "displayName": name, // đồng bộ với createChildAccount
      "phone": phone,
      "gender": gender,
      "dob": dob,
      "address": address,
      "allowTracking": allowTracking,
      "role": role,
      "avatarUrl": avatarUrl,
      "coverUrl": coverUrl,
    };

    // 🔥 tự động bỏ null field
    data.removeWhere((key, value) => value == null);

    return data;
  }

  /// 🔹 Tạo object từ Firestore
  factory UserProfile.fromMap(String id, Map<String, dynamic> data) {
    String dobStr = '';
    final rawDob = data['dob'];

    DateTime? date;

    if (rawDob is Timestamp) {
      date = rawDob.toDate();
    } else if (rawDob is int) {
      date = DateTime.fromMillisecondsSinceEpoch(rawDob);
    } else if (rawDob is String) {
      // nếu trước đó đã lưu dạng dd/MM/yyyy thì giữ nguyên
      try {
        date = DateTime.parse(rawDob); // trường hợp iso string
      } catch (_) {
        dobStr = rawDob; // fallback giữ nguyên
      }
    }

    if (date != null) {
      dobStr = DateFormat('dd/MM/yyyy').format(date);
    }

    return UserProfile(
      id: id,
      name: (data["displayName"] ?? "").toString(),
      phone: (data["phone"] ?? "").toString(),
      gender: (data["gender"] ?? "").toString(),
      dob: dobStr,
      address: (data["address"] ?? "").toString(),
      allowTracking: data["allowTracking"] ?? false,
      role: (data["role"] ?? "child").toString(),
      avatarUrl: data["avatarUrl"]?.toString(),
      coverUrl: data["coverUrl"]?.toString(),
    );
  }
}
