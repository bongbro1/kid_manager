import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionInfo {
  final String plan; // free | pro
  final String status; // trial | active | expired | canceled | payment_failed

  final DateTime? startAt;
  final DateTime? endAt;

  final bool isTrial;
  final bool autoRenew;

  final String? productId; // pro_monthly, pro_yearly
  final String? platform; // android | ios | web

  final DateTime? updatedAt;

  const SubscriptionInfo({
    required this.plan,
    required this.status,
    this.startAt,
    this.endAt,
    this.isTrial = false,
    this.autoRenew = true,
    this.productId,
    this.platform,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'plan': plan,
        'status': status,
        'startAt': startAt == null ? null : Timestamp.fromDate(startAt!),
        'endAt': endAt == null ? null : Timestamp.fromDate(endAt!),
        'isTrial': isTrial,
        'autoRenew': autoRenew,
        'productId': productId,
        'platform': platform,
        'updatedAt': FieldValue.serverTimestamp(),
      }..removeWhere((k, v) => v == null);

  factory SubscriptionInfo.fromMap(Map<String, dynamic> map) {
    return SubscriptionInfo(
      plan: (map['plan'] as String?) ?? 'free',
      status: (map['status'] as String?) ?? 'expired',
      startAt: _readDate(map['startAt']),
      endAt: _readDate(map['endAt']),
      isTrial: (map['isTrial'] as bool?) ?? false,
      autoRenew: (map['autoRenew'] as bool?) ?? true,
      productId: map['productId'] as String?,
      platform: map['platform'] as String?,
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

extension SubscriptionInfoX on SubscriptionInfo {
  bool get isActiveNow {
    final now = DateTime.now();

    if (status != 'active' && status != 'trial') return false;
    if (endAt != null && endAt!.isBefore(now)) return false;

    return true;
  }

  bool get isExpired {
    if (endAt == null) return false;
    return endAt!.isBefore(DateTime.now());
  }

  bool get isCanceled => status == 'canceled';

  bool get hasPaymentFailed => status == 'payment_failed';

  int? get remainingDays {
    if (endAt == null) return null;
    return endAt!.difference(DateTime.now()).inDays;
  }

  SubscriptionInfo copyWith({
    String? plan,
    String? status,
    DateTime? startAt,
    DateTime? endAt,
    bool? isTrial,
    bool? autoRenew,
    String? productId,
    String? platform,
    DateTime? updatedAt,
  }) {
    return SubscriptionInfo(
      plan: plan ?? this.plan,
      status: status ?? this.status,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      isTrial: isTrial ?? this.isTrial,
      autoRenew: autoRenew ?? this.autoRenew,
      productId: productId ?? this.productId,
      platform: platform ?? this.platform,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}