import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyChatState {
  final String uid;
  final int unreadCount;
  final DateTime? lastReadAt;
  final DateTime? updatedAt;

  const FamilyChatState({
    required this.uid,
    required this.unreadCount,
    required this.lastReadAt,
    required this.updatedAt,
  });

  factory FamilyChatState.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return FamilyChatState(
      uid: (data['uid'] ?? doc.id).toString(),
      unreadCount: (data['unreadCount'] ?? 0) is int
          ? (data['unreadCount'] ?? 0) as int
          : int.tryParse((data['unreadCount'] ?? '0').toString()) ?? 0,
      lastReadAt: (data['lastReadAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}