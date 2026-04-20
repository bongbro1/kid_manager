import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kid_manager/models/user/user_subscription.dart';

class SubscriptionCatalogPlan {
  const SubscriptionCatalogPlan({
    required this.id,
    required this.entitlementPlan,
    required this.sortOrder,
    this.isHighlighted = false,
    this.isContactOnly = false,
    this.isActive = true,
    this.updatedAt,
  });

  final String id;
  final SubscriptionPlan entitlementPlan;
  final int sortOrder;
  final bool isHighlighted;
  final bool isContactOnly;
  final bool isActive;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'entitlementPlan': entitlementPlan.wireValue,
      'sortOrder': sortOrder,
      'isHighlighted': isHighlighted,
      'isContactOnly': isContactOnly,
      'isActive': isActive,
      'updatedAt': updatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt!),
    };
  }

  factory SubscriptionCatalogPlan.fromMap(Map<String, dynamic> map) {
    return SubscriptionCatalogPlan(
      id: (map['id'] ?? '').toString().trim().toLowerCase(),
      entitlementPlan: SubscriptionPlan.fromValue(map['entitlementPlan']),
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      isHighlighted: (map['isHighlighted'] as bool?) ?? false,
      isContactOnly: (map['isContactOnly'] as bool?) ?? false,
      isActive: (map['isActive'] as bool?) ?? true,
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}
