import 'dart:async';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ZoneBubbleState {
  final IconData icon;
  final String text;

  const ZoneBubbleState({required this.icon, required this.text});
}

class ZoneStatusVm extends ChangeNotifier {
  final FirebaseDatabase _rtdb;
  final FirebaseFirestore _fs;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  ZoneStatusVm({
    FirebaseDatabase? rtdb,
    FirebaseFirestore? fs,
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  })  : _rtdb = rtdb ?? FirebaseDatabase.instance,
        _fs = fs ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _functions =
            functions ??
            FirebaseFunctions.instanceFor(region: 'asia-southeast1') {
    _authSub = _auth.authStateChanges().listen((user) {
      if (user == null) {
        _cancelFocusStreams();
        _activePresence = null;
        _lastEvent = null;
        _setBubble(null);
        return;
      }

      if (_viewerUid == null || _childId == null) return;
      _restartFocusStreams();
      _recompute();
    });
  }

  String? _childId;
  String? _viewerUid; // parentUid (để query inbox của cha)

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DatabaseEvent>? _presenceSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _lastEventSub;
  Timer? _presencePollTimer;
  Timer? _tick;

  Map<String, dynamic>? _activePresence; // zone đang inside (danger ưu tiên)
  Map<String, dynamic>? _lastEvent; // notif ZONE gần nhất

  int _nowMs = DateTime.now().millisecondsSinceEpoch;

  ZoneBubbleState? _bubble;
  ZoneBubbleState? get bubble => _bubble;

  void focus({required String viewerUid, required String childId}) {
    if (_viewerUid == viewerUid && _childId == childId) return;

    _viewerUid = viewerUid;
    _childId = childId;

    _cancelFocusStreams();
    _activePresence = null;
    _lastEvent = null;

    _tick ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _nowMs = DateTime.now().millisecondsSinceEpoch;
      _recompute();
    });

    _restartFocusStreams();

    _recompute();
  }

  void clearFocus() {
    _viewerUid = null;
    _childId = null;
    _cancelFocusStreams();
    _activePresence = null;
    _lastEvent = null;
    _bubble = null;
    notifyListeners();
  }

  void _cancelFocusStreams() {
    _presenceSub?.cancel();
    _presenceSub = null;
    _presencePollTimer?.cancel();
    _presencePollTimer = null;
    _lastEventSub?.cancel();
    _lastEventSub = null;
  }

  void _restartFocusStreams() {
    _cancelFocusStreams();

    final viewerUid = _viewerUid;
    final childId = _childId;
    final authUid = _auth.currentUser?.uid;

    if (viewerUid == null || childId == null) return;

    if (authUid == null || authUid.isEmpty) {
      debugPrint(
        '[ZoneStatusVm] Skip listeners until FirebaseAuth is ready '
        'viewer=$viewerUid child=$childId',
      );
      return;
    }

    if (authUid != viewerUid) {
      debugPrint(
        '[ZoneStatusVm] Skip listeners because auth uid mismatch '
        'authUid=$authUid viewer=$viewerUid child=$childId',
      );
      return;
    }

    _listenPresence(childId);
    _listenLastZoneEvent(viewerUid, childId);
  }

  void _listenPresence(String childId) {
    final ref = _rtdb.ref('zonePresenceByChild/$childId');

    _presenceSub = ref.onValue.listen((e) {
      _applyPresenceValue(e.snapshot.value);
    }, onError: (Object e, StackTrace st) {
      debugPrint(
        '[ZoneStatusVm] zonePresence listen error child=$childId error=$e',
      );
      debugPrint('$st');
      unawaited(_presenceSub?.cancel());
      _presenceSub = null;
      _startPresenceFallbackPolling(childId);
    });
  }

  void _applyPresenceValue(dynamic value) {
    if (value == null) {
      _activePresence = null;
      _recompute();
      return;
    }

    if (value is! Map) {
      _activePresence = null;
      _recompute();
      return;
    }

    final m = Map<dynamic, dynamic>.from(value);

    Map<String, dynamic>? bestDanger;
    Map<String, dynamic>? bestSafe;

    for (final entry in m.entries) {
      final raw = entry.value;
      if (raw is! Map) continue;
      final data = Map<String, dynamic>.from(raw);
      if (data['inside'] != true) continue;

      final type = (data['zoneType'] ?? '').toString();
      if (type == 'danger') bestDanger ??= data;
      if (type == 'safe') bestSafe ??= data;
    }

    _activePresence = bestDanger ?? bestSafe;
    _recompute();
  }

  Future<void> _pollPresenceOnce(String childId) async {
    try {
      final res = await _functions.httpsCallable('getChildZonePresence').call({
        'childUid': childId,
      });
      final data = Map<String, dynamic>.from(res.data as Map);
      _applyPresenceValue(data['presence']);
    } catch (e, st) {
      debugPrint('[ZoneStatusVm] zonePresence callable error child=$childId error=$e');
      debugPrint('$st');
      _activePresence = null;
      _recompute();
    }
  }

  void _startPresenceFallbackPolling(String childId) {
    if (_presencePollTimer != null) return;

    unawaited(_pollPresenceOnce(childId));
    _presencePollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      unawaited(_pollPresenceOnce(childId));
    });
  }

  void _listenLastZoneEvent(String viewerUid, String childId) {

    final q = _fs
        .collection('users')
        .doc(viewerUid)
        .collection('notifications')
        .where('type', isEqualTo: 'ZONE')
        .where('data.childUid', isEqualTo: childId)
        .orderBy('createdAt', descending: true)
        .limit(1);

    _lastEventSub = q.snapshots().listen((snap) {
      if (snap.docs.isEmpty) {
        _lastEvent = null;
        _recompute();
        return;
      }
      _lastEvent = snap.docs.first.data();

      debugPrint("🔎 lastZoneEvent viewer=$viewerUid child=$childId");
      q.get().then((s) => debugPrint("🔎 lastZoneEvent get count=${s.docs.length}"));
      _recompute();
    }, onError: (e) {
      debugPrint("❌ _listenLastZoneEvent error: $e");
    });
  }

  void _recompute() {
    final presence = _activePresence;

    // 1) Nếu đang inside -> "đang ở ..."
    if (presence != null) {
      final zoneName = (presence['zoneName'] ?? 'Vùng').toString();
      final zoneType = (presence['zoneType'] ?? '').toString();
      final enterAt = int.tryParse((presence['enterAt'] ?? '0').toString()) ?? 0;

      final elapsedSec =
      enterAt > 0 ? max(0, ((_nowMs - enterAt) / 1000).floor()) : 0;

      final text = "đang ở $zoneName · ${_fmtDuration(elapsedSec)}";
      final icon = zoneType == 'danger'
          ? Icons.warning_amber_rounded
          : Icons.home;

      _setBubble(ZoneBubbleState(icon: icon, text: text));
      return;
    }

    // 2) Không inside -> fallback last event (thường là exit)
    final ev = _lastEvent;
    if (ev != null) {
      final body = (ev['body'] ?? '').toString(); // bạn đang lưu bodyText = zoneName hoặc zoneName • phút
      final createdAt = ev['createdAt'];
      DateTime? dt;
      if (createdAt is Timestamp) dt = createdAt.toDate();

      final ago = dt != null ? _timeAgo(dt) : '';
      final text = ago.isNotEmpty ? "đã ở $body · $ago" : "đã ở $body";

      // icon theo key nếu có
      final key = (ev['eventKey'] ?? '').toString();
      final icon = key.contains('.danger.')
          ? Icons.warning_amber_rounded
          : Icons.home;

      _setBubble(ZoneBubbleState(icon: icon, text: text));
      return;
    }

    // 3) Không có gì
    _setBubble(null);
  }

  void _setBubble(ZoneBubbleState? b) {
    final changed = (_bubble?.text != b?.text) || (_bubble?.icon != b?.icon);
    _bubble = b;
    if (changed) notifyListeners();
  }

  String _fmtDuration(int sec) {
    final m = (sec / 60).floor();
    final h = (m / 60).floor();
    final mm = m % 60;
    if (h <= 0) return "${mm} phút";
    return "${h}g${mm.toString().padLeft(2, '0')} phút";
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return "vừa xong";
    if (diff.inMinutes < 60) return "${diff.inMinutes} phút trước";
    if (diff.inHours < 24) return "${diff.inHours} giờ trước";
    return "${diff.inDays} ngày trước";
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _cancelFocusStreams();
    _tick?.cancel();
    super.dispose();
  }
}
