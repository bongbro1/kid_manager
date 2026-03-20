import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/utils/runtime_l10n.dart';

class ZoneBubbleState {
  final IconData icon;
  final String text;

  const ZoneBubbleState({required this.icon, required this.text});
}

class ZoneStatusVm extends ChangeNotifier {
  final FirebaseDatabase _rtdb;
  final FirebaseFirestore _fs;
  final FirebaseAuth _auth;

  ZoneStatusVm({
    FirebaseDatabase? rtdb,
    FirebaseFirestore? fs,
    FirebaseAuth? auth,
  })  : _rtdb = rtdb ?? FirebaseDatabase.instance,
        _fs = fs ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance {
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
      final v = e.snapshot.value;
      if (v == null) {
        _activePresence = null;
        _recompute();
        return;
      }

      final m = Map<dynamic, dynamic>.from(v as Map);

      Map<String, dynamic>? bestDanger;
      Map<String, dynamic>? bestSafe;

      for (final entry in m.entries) {
        final data = Map<String, dynamic>.from(entry.value as Map);
        if (data['inside'] != true) continue;

        final type = (data['zoneType'] ?? '').toString();
        if (type == 'danger') bestDanger ??= data;
        if (type == 'safe') bestSafe ??= data;
      }

      _activePresence = bestDanger ?? bestSafe;
      _recompute();
    }, onError: (Object e, StackTrace st) {
      debugPrint(
        '[ZoneStatusVm] zonePresence listen error child=$childId error=$e',
      );
      debugPrint('$st');
      _activePresence = null;
      _recompute();
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
    final l10n = runtimeL10n();
    final presence = _activePresence;

    // 1) Nếu đang inside -> "đang ở ..."
    if (presence != null) {
      final zoneName = (presence['zoneName'] ?? l10n.zonesDefaultNameFallback)
          .toString();
      final zoneType = (presence['zoneType'] ?? '').toString();
      final enterAt = int.tryParse((presence['enterAt'] ?? '0').toString()) ?? 0;

      final elapsedSec =
      enterAt > 0 ? max(0, ((_nowMs - enterAt) / 1000).floor()) : 0;

      final text = l10n.zoneStatusAtText(
        zoneName,
        _fmtDuration(elapsedSec),
      );
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
      final text = ago.isNotEmpty
          ? l10n.zoneStatusWasAtWithAgoText(body, ago)
          : l10n.zoneStatusWasAtText(body);

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
    final l10n = runtimeL10n();
    final m = (sec / 60).floor();
    final h = (m / 60).floor();
    final mm = m % 60;
    if (h <= 0) return l10n.zoneStatusDurationMinutes(mm);
    return l10n.zoneStatusDurationHoursMinutes(h, mm);
  }

  String _timeAgo(DateTime t) {
    final l10n = runtimeL10n();
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return l10n.zoneStatusJustNow;
    if (diff.inMinutes < 60) return l10n.zoneStatusMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.zoneStatusHoursAgo(diff.inHours);
    return l10n.zoneStatusDaysAgo(diff.inDays);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _cancelFocusStreams();
    _tick?.cancel();
    super.dispose();
  }
}
