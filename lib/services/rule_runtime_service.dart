// import 'dart:async';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:kid_manager/background/foreground_watcher.dart';
// import 'package:kid_manager/utils/usage_rule_utils.dart';

// class RuleRuntimeService {
//   static final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
//       _ruleSubs = {};

//   static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _appsSub;

//   static Future<void> start(String userId) async {
//     await stop();

//     debugPrint("🟢 RuleRuntimeService.start userId=$userId");

//     await _syncAllRules(userId);
//     _listenApps(userId);
//   }

//   static Future<void> _syncAllRules(String userId) async {
//     debugPrint("🔄 _syncAllRules userId=$userId");

//     final appsSnap = await FirebaseFirestore.instance
//         .collection("blocked_items")
//         .doc(userId)
//         .collection("apps")
//         .get();

//     final nativeRules = <NativeBlockedRule>[];

//     debugPrint("📦 apps count=${appsSnap.docs.length}");

//     for (final app in appsSnap.docs) {
//       final packageName = app.id;

//       final ruleDoc = await FirebaseFirestore.instance
//           .collection("blocked_items")
//           .doc(userId)
//           .collection("apps")
//           .doc(packageName)
//           .collection("usage_rule")
//           .doc("config")
//           .get();

//       debugPrint(
//         "📄 sync rule package=$packageName exists=${ruleDoc.exists} data=${ruleDoc.data()}",
//       );

//       if (!ruleDoc.exists || ruleDoc.data() == null) {
//         continue;
//       }

//       final rule = UsageRule.fromMap(ruleDoc.data()!);

//       nativeRules.add(
//         NativeBlockedRule.fromUsageRule(
//           packageName: packageName,
//           rule: rule,
//         ),
//       );
//     }

//     debugPrint("📤 push native rules count=${nativeRules.length}");
//     for (final item in nativeRules) {
//       debugPrint(
//         "   📦 ${item.packageName} enabled=${item.enabled} "
//         "weekdays=${item.weekdays} windows=${item.windows} "
//         "overrides=${item.overrides}",
//       );
//     }
//   }

//   static void _listenApps(String userId) {
//     debugPrint("👂 listen apps collection userId=$userId");

//     _appsSub = FirebaseFirestore.instance
//         .collection("blocked_items")
//         .doc(userId)
//         .collection("apps")
//         .snapshots()
//         .listen(
//       (snapshot) async {
//         debugPrint(
//           "🔥 apps changed size=${snapshot.docs.length} changes=${snapshot.docChanges.length}",
//         );

//         final currentPackages = snapshot.docs.map((e) => e.id).toSet();

//         for (final change in snapshot.docChanges) {
//           debugPrint("📦 app change type=${change.type} package=${change.doc.id}");
//         }

//         for (final packageName in currentPackages) {
//           if (!_ruleSubs.containsKey(packageName)) {
//             debugPrint("➕ attach rule listener for $packageName");
//             await _listenRule(userId, packageName);
//           }
//         }

//         final removedPackages = _ruleSubs.keys
//             .where((pkg) => !currentPackages.contains(pkg))
//             .toList();

//         for (final packageName in removedPackages) {
//           debugPrint("➖ remove rule listener for deleted app $packageName");
//           await _ruleSubs[packageName]?.cancel();
//           _ruleSubs.remove(packageName);
//         }

//         await _syncAllRules(userId);
//       },
//       onError: (e) {
//         debugPrint("🔥 listenApps error: $e");
//       },
//     );
//   }

//   static Future<void> _listenRule(String userId, String packageName) async {
//     if (_ruleSubs.containsKey(packageName)) {
//       debugPrint("⏭ already listening $packageName");
//       return;
//     }

//     final ref = FirebaseFirestore.instance
//         .collection("blocked_items")
//         .doc(userId)
//         .collection("apps")
//         .doc(packageName)
//         .collection("usage_rule")
//         .doc("config");

//     try {
//       final first = await ref.get();
//       debugPrint(
//         "🧪 initial check package=$packageName exists=${first.exists} data=${first.data()}",
//       );
//     } catch (e) {
//       if (e is FirebaseException && e.code == 'permission-denied') {
//         debugPrint("⛔ No permission for $packageName");
//         return;
//       }
//       debugPrint("🔥 initial read error ($packageName): $e");
//       return;
//     }

//     final sub = ref.snapshots().listen(
//       (doc) async {
//         debugPrint(
//           "🔥 rule changed package=$packageName exists=${doc.exists} data=${doc.data()}",
//         );

//         if (!doc.exists || doc.data() == null) {
//           debugPrint("⚠️ rule missing for $packageName -> remove");
//           await _syncAllRules(userId);
//           return;
//         }

//         try {
//           final rule = UsageRule.fromMap(doc.data()!);

//           debugPrint(
//             "✅ parsed rule package=$packageName "
//             "enabled=${rule.enabled} "
//             "weekdays=${rule.weekdays} "
//             "windows=${rule.windows.length} "
//             "overrides=${rule.overrides}",
//           );

//           for (final w in rule.windows) {
//             debugPrint("   🪟 window ${w.startMin} -> ${w.endMin}");
//           }

//           await _syncAllRules(userId);
//         } catch (e, s) {
//           debugPrint("❌ parse rule failed ($packageName): $e");
//           debugPrint("$s");
//         }
//       },
//       onError: (e) async {
//         debugPrint("🔥 listenRule error ($packageName): $e");
//         await _ruleSubs[packageName]?.cancel();
//         _ruleSubs.remove(packageName);
//       },
//     );

//     _ruleSubs[packageName] = sub;
//   }

//   static Future<void> stop() async {
//     debugPrint("🔴 RuleRuntimeService.stop");

//     await _appsSub?.cancel();
//     _appsSub = null;

//     for (final entry in _ruleSubs.entries) {
//       debugPrint("🧹 cancel rule listener for ${entry.key}");
//       await entry.value.cancel();
//     }
//     _ruleSubs.clear();
//   }
// }