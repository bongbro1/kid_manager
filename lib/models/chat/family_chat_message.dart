import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyChatMessage {
  final String id;
  final String familyId;
  final String senderUid;
  final String senderRole;
  final String senderName;
  final String? clientMessageId;
  final String text;
  final String type;
  final String? stickerId;
  final String? imageUrl;
  final String? imagePath;
  final int? imageWidth;
  final int? imageHeight;
  final DateTime? createdAt;
  final String verifyState;
  final String? verifyError;
  final bool hasPendingWrites;

  const FamilyChatMessage({
    required this.id,
    required this.familyId,
    required this.senderUid,
    required this.senderRole,
    required this.senderName,
    required this.clientMessageId,
    required this.text,
    required this.type,
    required this.stickerId,
    required this.imageUrl,
    required this.imagePath,
    required this.imageWidth,
    required this.imageHeight,
    required this.createdAt,
    required this.verifyState,
    required this.verifyError,
    required this.hasPendingWrites,
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
      clientMessageId: data['clientMessageId']?.toString(),
      text: (data['text'] ?? '').toString(),
      type: (data['type'] ?? 'text').toString(),
      stickerId: data['stickerId']?.toString(),
      imageUrl: data['imageUrl']?.toString(),
      imagePath: data['imagePath']?.toString(),
      imageWidth: (data['imageWidth'] as num?)?.toInt(),
      imageHeight: (data['imageHeight'] as num?)?.toInt(),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
          (data['clientCreatedAt'] as Timestamp?)?.toDate(),
      verifyState: (data['verifyState'] ?? 'verified').toString(),
      verifyError: data['verifyError']?.toString(),
      hasPendingWrites: doc.metadata.hasPendingWrites,
    );
  }
}
