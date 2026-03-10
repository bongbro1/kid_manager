class FamilyChatMember {
  final String uid;
  final String role;
  final String displayName;
  final String avatarUrl;

  const FamilyChatMember({
    required this.uid,
    required this.role,
    required this.displayName,
    required this.avatarUrl,
  });
}

class LocalPendingChatMessage {
  final String localId;
  final String text;
  final DateTime createdAt;
  final bool failed;

  const LocalPendingChatMessage({
    required this.localId,
    required this.text,
    required this.createdAt,
    this.failed = false,
  });

  LocalPendingChatMessage copyWith({
    bool? failed,
  }) {
    return LocalPendingChatMessage(
      localId: localId,
      text: text,
      createdAt: createdAt,
      failed: failed ?? this.failed,
    );
  }
}
