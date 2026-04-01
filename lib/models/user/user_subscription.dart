import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionPlan {
  free('free'),
  pro('pro');

  const SubscriptionPlan(this.wireValue);

  final String wireValue;

  bool get isPaid => this != SubscriptionPlan.free;

  static SubscriptionPlan fromValue(
    Object? value, {
    SubscriptionPlan fallback = SubscriptionPlan.free,
  }) {
    if (value is SubscriptionPlan) {
      return value;
    }

    final normalized = value?.toString().trim().toLowerCase();
    for (final plan in SubscriptionPlan.values) {
      if (plan.wireValue == normalized) {
        return plan;
      }
    }
    return fallback;
  }
}

enum SubscriptionStatus {
  trial('trial'),
  active('active'),
  expired('expired'),
  canceled('canceled'),
  paymentFailed('payment_failed');

  const SubscriptionStatus(this.wireValue);

  final String wireValue;

  bool get grantsEntitlement =>
      this == SubscriptionStatus.trial || this == SubscriptionStatus.active;

  static SubscriptionStatus fromValue(
    Object? value, {
    SubscriptionStatus fallback = SubscriptionStatus.expired,
  }) {
    if (value is SubscriptionStatus) {
      return value;
    }

    final normalized = value?.toString().trim().toLowerCase();
    for (final status in SubscriptionStatus.values) {
      if (status.wireValue == normalized) {
        return status;
      }
    }
    return fallback;
  }
}

class SubscriptionInfo {
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

  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool isTrial;
  final bool autoRenew;
  final String? productId;
  final String? platform;
  final DateTime? updatedAt;

  String get planKey => plan.wireValue;
  String get statusKey => status.wireValue;

  bool get isExpired {
    if (endAt == null) {
      return false;
    }
    return endAt!.isBefore(DateTime.now());
  }

  bool get isActiveNow {
    if (!status.grantsEntitlement) {
      return false;
    }
    return !isExpired;
  }

  bool get isCanceled => status == SubscriptionStatus.canceled;

  bool get hasPaymentFailed => status == SubscriptionStatus.paymentFailed;

  bool get hasPaidAccess => plan.isPaid && isActiveNow;

  SubscriptionPlan get effectivePlan =>
      hasPaidAccess ? plan : SubscriptionPlan.free;

  int? get remainingDays {
    if (endAt == null) {
      return null;
    }
    return endAt!.difference(DateTime.now()).inDays;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'plan': planKey,
      'status': statusKey,
      'startAt': startAt == null ? null : Timestamp.fromDate(startAt!),
      'endAt': endAt == null ? null : Timestamp.fromDate(endAt!),
      'isTrial': isTrial,
      'autoRenew': autoRenew,
      'productId': productId,
      'platform': platform,
      'updatedAt': updatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt!),
    }..removeWhere((key, value) => value == null);
  }

  factory SubscriptionInfo.fromMap(Map<String, dynamic> map) {
    return SubscriptionInfo(
      plan: SubscriptionPlan.fromValue(map['plan']),
      status: SubscriptionStatus.fromValue(map['status']),
      startAt: _readDate(map['startAt']),
      endAt: _readDate(map['endAt']),
      isTrial: (map['isTrial'] as bool?) ?? false,
      autoRenew: (map['autoRenew'] as bool?) ?? true,
      productId: map['productId'] as String?,
      platform: map['platform'] as String?,
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  SubscriptionInfo copyWith({
    SubscriptionPlan? plan,
    SubscriptionStatus? status,
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

  static DateTime? _readDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}
