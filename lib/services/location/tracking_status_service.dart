import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class TrackingStatusService {
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  String? _cachedUid;
  bool? _cachedCanReport;

  TrackingStatusService({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'asia-southeast1'),
       _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  Future<bool> _canReportStatus() async {
    final uid = _auth.currentUser?.uid.trim();
    if (uid == null || uid.isEmpty) {
      return false;
    }

    if (_cachedUid == uid && _cachedCanReport != null) {
      return _cachedCanReport!;
    }

    try {
      final userSnap = await _firestore.collection('users').doc(uid).get();
      final role = (userSnap.data()?['role'] ?? '').toString().trim().toLowerCase();
      final canReport = role == 'child';
      _cachedUid = uid;
      _cachedCanReport = canReport;
      return canReport;
    } catch (e) {
      debugPrint('TrackingStatusService canReportStatus error: $e');
      _cachedUid = uid;
      _cachedCanReport = false;
      return false;
    }
  }

  Future<void> reportStatus({required String status, String? message}) async {
    if (!await _canReportStatus()) {
      return;
    }
    await _functions.httpsCallable('reportTrackingStatus').call({
      'status': status,
      'message': message ?? '',
    });
  }
}
