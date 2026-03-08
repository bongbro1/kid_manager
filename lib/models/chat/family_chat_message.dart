import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyChatMessage {
  final String id;
  final String familyId;
  final String senderUid;
  final String senderRole;
  final String senderName;
  final String text;
  final String type;
  final DateTime? createdAt;

  const FamilyChatMessage({
    required this.id,
    required this.familyId,
    required this.senderUid,
    required this.senderRole,
    required this.senderName,
    required this.text,
    required this.type,
    required this.createdAt,
  });

  factory FamilyChatMessage.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc, {
        required String familyId,
      }) {
    final data = doc.data() ?? <String, dynamic>{};
    return FamilyChatMessage(
      id: doc.id,
      familyId: familyId,
      senderUid: (data['senderUid'] ?? '').toString(),
      senderRole: (data['senderRole'] ?? '').toString(),
      senderName: (data['senderName'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
      type: (data['type'] ?? 'text').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
