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
  final String? parentUid;
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
    this.parentUid,
  });

  Map<String, dynamic> toMap() {
    final data = {
      "displayName": name,
      "phone": phone,
      "gender": gender,
      "dob": dob,
      "address": address,
      "allowTracking": allowTracking,
      "role": role,
      "avatarUrl": avatarUrl,
      "coverUrl": coverUrl,
      "parentUid": parentUid,
    };

    data.removeWhere((key, value) => value == null);
    return data;
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? gender,
    String? dob,
    String? address,
    bool? allowTracking,
    String? role,
    String? avatarUrl,
    String? coverUrl,
    String? parentUid,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      address: address ?? this.address,
      allowTracking: allowTracking ?? this.allowTracking,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      parentUid: parentUid ?? this.parentUid,
    );
  }

  factory UserProfile.fromMap(String id, Map<String, dynamic> data) {
    String dobStr = '';
    final rawDob = data['dob'];

    DateTime? date;

    if (rawDob is Timestamp) {
      date = rawDob.toDate();
    } else if (rawDob is int) {
      date = DateTime.fromMillisecondsSinceEpoch(rawDob);
    } else if (rawDob is String) {
      final value = rawDob.trim();

      try {
        date = DateFormat('dd/MM/yyyy').parseStrict(value);
      } catch (_) {
        try {
          date = DateTime.parse(value);
        } catch (_) {
          dobStr = value;
        }
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
      parentUid: data["parentUid"]?.toString(),
    );
  }
}