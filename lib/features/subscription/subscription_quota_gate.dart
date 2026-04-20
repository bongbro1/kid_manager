import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

enum SubscriptionQuotaFeature { zone, safeRoute }

class SubscriptionQuotaInfo {
  const SubscriptionQuotaInfo({required this.feature, this.limit});

  final SubscriptionQuotaFeature feature;
  final int? limit;
}

class SubscriptionQuotaGate {
  static const zoneLimitError = 'FREE_PLAN_ZONE_LIMIT_REACHED';
  static const safeRouteLimitError = 'FREE_PLAN_SAFE_ROUTE_LIMIT_REACHED';
  static const _encodedPrefix = '__quota_limit__';

  static SubscriptionQuotaInfo? resolve(Object? error) {
    if (error == null) {
      return null;
    }

    if (error is FirebaseFunctionsException) {
      final feature = _featureFromText(error.message);
      if (feature != null) {
        return SubscriptionQuotaInfo(
          feature: feature,
          limit: _extractLimit(error.details),
        );
      }
    }

    final text = error.toString();
    if (text.startsWith(_encodedPrefix)) {
      return _decode(text);
    }

    final feature = _featureFromText(text);
    if (feature == null) {
      return null;
    }
    return SubscriptionQuotaInfo(feature: feature);
  }

  static String encode(SubscriptionQuotaInfo info) {
    final limitValue = info.limit?.toString() ?? '';
    return '$_encodedPrefix|${info.feature.name}|$limitValue';
  }

  static Future<void> showPlanUpgradeDialog(
    BuildContext context, {
    required SubscriptionQuotaInfo quota,
    VoidCallback? onUpgrade,
  }) async {
    final isVi =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'vi';
    final title = isVi ? 'Cần gói Pro' : 'Pro plan required';
    final limitText =
        quota.limit?.toString() ??
        (isVi ? 'một số lượng giới hạn' : 'a limited number of');
    final message = switch (quota.feature) {
      SubscriptionQuotaFeature.zone =>
        isVi
            ? 'Gói thường chỉ tạo tối đa $limitText vùng an toàn hoặc vùng nguy hiểm cho mỗi bé. Nâng cấp Pro để tạo không giới hạn.'
            : 'The free plan allows up to $limitText safe or danger zones per child. Upgrade to Pro for unlimited zones.',
      SubscriptionQuotaFeature.safeRoute =>
        isVi
            ? 'Gói thường chỉ tạo tối đa $limitText đường an toàn cho mỗi bé. Nâng cấp Pro để tạo không giới hạn.'
            : 'The free plan allows up to $limitText safe routes per child. Upgrade to Pro for unlimited safe routes.',
    };
    final dismissText = isVi ? 'Để sau' : 'Later';
    final upgradeText = onUpgrade == null
        ? (isVi ? 'Đã hiểu' : 'Got it')
        : (isVi ? 'Đăng ký Pro' : 'Upgrade to Pro');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(message, style: const TextStyle(height: 1.5)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(dismissText),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onUpgrade?.call();
              },
              child: Text(upgradeText),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showVipUpgradeDialog(
    BuildContext context, {
    required SubscriptionQuotaInfo quota,
    VoidCallback? onUpgrade,
  }) {
    return showPlanUpgradeDialog(context, quota: quota, onUpgrade: onUpgrade);
  }

  static SubscriptionQuotaInfo? _decode(String value) {
    final parts = value.split('|');
    if (parts.length < 3 || parts.first != _encodedPrefix) {
      return null;
    }

    final feature = switch (parts[1]) {
      'zone' => SubscriptionQuotaFeature.zone,
      'safeRoute' => SubscriptionQuotaFeature.safeRoute,
      _ => null,
    };
    if (feature == null) {
      return null;
    }

    final limit = int.tryParse(parts[2]);
    return SubscriptionQuotaInfo(feature: feature, limit: limit);
  }

  static SubscriptionQuotaFeature? _featureFromText(String? text) {
    if (text == null || text.isEmpty) {
      return null;
    }
    if (text.contains(zoneLimitError)) {
      return SubscriptionQuotaFeature.zone;
    }
    if (text.contains(safeRouteLimitError)) {
      return SubscriptionQuotaFeature.safeRoute;
    }
    return null;
  }

  static int? _extractLimit(dynamic details) {
    if (details is Map) {
      final raw = details['limit'];
      if (raw is int) {
        return raw;
      }
      if (raw is num) {
        return raw.toInt();
      }
      if (raw is String) {
        return int.tryParse(raw);
      }
    }
    return null;
  }
}
