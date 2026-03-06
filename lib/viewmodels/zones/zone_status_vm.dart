import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
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

  ZoneStatusVm({FirebaseDatabase? rtdb, FirebaseFirestore? fs})
      : _rtdb = rtdb ?? FirebaseDatabase.instance,
        _fs = fs ?? FirebaseFirestore.instance;

  String? _childId;
  String? _viewerUid; // parentUid (để query inbox của cha)

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

    _presenceSub?.cancel();
    _lastEventSub?.cancel();
    _activePresence = null;
    _lastEvent = null;

    _tick ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _nowMs = DateTime.now().millisecondsSinceEpoch;
      _recompute();
    });

    _listenPresence(childId);
    _listenLastZoneEvent(viewerUid, childId);

    _recompute();
  }

  void clearFocus() {
    _viewerUid = null;
    _childId = null;
    _presenceSub?.cancel();
    _lastEventSub?.cancel();
    _activePresence = null;
    _lastEvent = null;
    _bubble = null;
    notifyListeners();
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
      q.get().then((s) => debugPrint("🔎 once get count=${s.docs.length}"));
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
    _presenceSub?.cancel();
    _lastEventSub?.cancel();
    _tick?.cancel();
    super.dispose();
  }
}