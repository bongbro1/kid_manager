import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String senderId;
  final String receiverId;
  final String? familyId;

  final String type;
  final String title;
  final String body;

  final bool isRead;
  final String status;

  final DateTime? createdAt;
  final Map<String, dynamic> data;

  AppNotification({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.familyId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.status,
    required this.data,
    required this.createdAt,
  });

  factory AppNotification.fromMap(
      String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,

      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      familyId: map['familyId'],

      type: map['type'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',

      isRead: map['isRead'] ?? false,
      status: map['status'] ?? 'pending',

      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,

      data: Map<String, dynamic>.from(map['data'] ?? {}),
    );
  }
}