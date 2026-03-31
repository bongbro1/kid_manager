import 'dart:async';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/core/async/polling_backoff.dart';
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
        _presenceUnavailable = false;
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
  Timer? _presenceRetryTimer;
  Timer? _tick;
  final PollingBackoff _presenceFallbackBackoff = PollingBackoff(
    initialDelay: Duration(seconds: 10),
    maxDelay: Duration(minutes: 1),
  );
  static const Duration _presenceRealtimeRetryInterval = Duration(minutes: 1);

  Map<String, dynamic>? _activePresence; // zone đang inside (danger ưu tiên)
  Map<String, dynamic>? _lastEvent; // notif ZONE gần nhất

  bool _presenceUnavailable = false;
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
    _presenceUnavailable = false;

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
    _presenceUnavailable = false;
    _bubble = null;
    notifyListeners();
  }

  void _cancelFocusStreams() {
    _presenceSub?.cancel();
    _presenceSub = null;
    _presencePollTimer?.cancel();
    _presencePollTimer = null;
    _presenceRetryTimer?.cancel();
    _presenceRetryTimer = null;
    _presenceFallbackBackoff.reset();
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
      _restoreRealtimePresenceIfNeeded(childId);
      _applyPresenceValue(e.snapshot.value);
    }, onError: (Object e, StackTrace st) {
      debugPrint(
        '[ZoneStatusVm] zonePresence listen error child=$childId error=$e',
      );
      debugPrint('$st');
      unawaited(_presenceSub?.cancel());
      _presenceSub = null;
      _presenceUnavailable = true;
      _startPresenceFallbackPolling(childId);
      _schedulePresenceRealtimeRetry(childId);
    });
  }

  void _applyPresenceValue(dynamic value) {
    _presenceUnavailable = false;
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
      _presenceUnavailable = true;
      _recompute();
    } finally {
      if (_presencePollTimer != null) {
        _schedulePresenceRealtimeRetry(childId);
        _schedulePresenceFallbackPoll(childId);
      }
    }
  }

  void _startPresenceFallbackPolling(String childId) {
    if (_presencePollTimer != null) return;

    _presenceFallbackBackoff.reset();
    debugPrint(
      '[ZoneStatusVm] enter fallback polling for zone presence child=$childId',
    );
    unawaited(_pollPresenceOnce(childId));
    _schedulePresenceFallbackPoll(childId);
    _schedulePresenceRealtimeRetry(childId);
  }

  void _schedulePresenceFallbackPoll(String childId) {
    _presencePollTimer?.cancel();
    if (_childId != childId) {
      return;
    }

    final delay = _presenceFallbackBackoff.nextDelay();
    debugPrint(
      '[ZoneStatusVm] fallback polling zone presence child=$childId '
      'attempt=${_presenceFallbackBackoff.attemptCount} nextInMs=${delay.inMilliseconds}',
    );
    _presencePollTimer = Timer(delay, () {
      if (_childId == childId && _presenceSub == null) {
        unawaited(_pollPresenceOnce(childId));
      }
    });
  }

  void _schedulePresenceRealtimeRetry(String childId) {
    if (_presenceRetryTimer != null) {
      return;
    }

    _presenceRetryTimer = Timer(_presenceRealtimeRetryInterval, () {
      _presenceRetryTimer = null;
      if (_childId == childId && _presenceSub == null) {
        debugPrint(
          '[ZoneStatusVm] retry realtime zone presence listener child=$childId',
        );
        _listenPresence(childId);
      }
    });
  }

  void _restoreRealtimePresenceIfNeeded(String childId) {
    if (_presencePollTimer != null || _presenceRetryTimer != null) {
      debugPrint(
        '[ZoneStatusVm] restored realtime zone presence listener child=$childId',
      );
    }
    _presencePollTimer?.cancel();
    _presencePollTimer = null;
    _presenceRetryTimer?.cancel();
    _presenceRetryTimer = null;
    _presenceFallbackBackoff.reset();
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
    if (_presenceUnavailable) {
      _setBubble(
        ZoneBubbleState(
          icon: Icons.location_disabled_outlined,
          text: l10n.zoneStatusLiveUnavailable,
        ),
      );
      return;
    }

    final ev = _lastEvent;
    if (ev != null) {
      final body = _buildLastEventBody(ev);
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
    final locale = l10n.localeName.toLowerCase();
    final isVietnamese = locale.startsWith('vi');
    final normalizedSeconds = sec <= 0 ? 0 : sec;
    final totalMinutes = normalizedSeconds <= 0
        ? 0
        : ((normalizedSeconds + 59) / 60).floor();
    final days = totalMinutes ~/ (24 * 60);
    final hours = (totalMinutes % (24 * 60)) ~/ 60;
    final minutes = totalMinutes % 60;

    if (days <= 0 && hours <= 0) {
      return l10n.zoneStatusDurationMinutes(minutes);
    }
    if (days <= 0) {
      return l10n.zoneStatusDurationHoursMinutes(hours, minutes);
    }

    final parts = <String>[
      _formatDurationUnit(days, isVietnamese: isVietnamese, vi: 'ngày', en: 'day'),
    ];
    if (hours > 0) {
      parts.add(
        _formatDurationUnit(
          hours,
          isVietnamese: isVietnamese,
          vi: 'giờ',
          en: 'hour',
        ),
      );
    }
    if (minutes > 0) {
      parts.add(
        _formatDurationUnit(
          minutes,
          isVietnamese: isVietnamese,
          vi: 'phút',
          en: 'minute',
        ),
      );
    }
    return parts.join(' ');
  }

  String _buildLastEventBody(Map<String, dynamic> event) {
    final rawData = event['data'];
    final payload = rawData is Map
        ? rawData.map((key, value) => MapEntry('$key', value))
        : const <String, dynamic>{};

    final zoneName = _normalizeZoneLabel(
      (payload['zoneName'] ?? event['body'] ?? '').toString(),
    );
    if (zoneName.isEmpty) {
      return '';
    }

    final durationSec = int.tryParse('${payload['durationSec'] ?? ''}') ?? 0;
    if (durationSec > 0) {
      return '$zoneName • ${_fmtDuration(durationSec)}';
    }

    final durationMin = int.tryParse('${payload['durationMin'] ?? ''}') ?? 0;
    if (durationMin > 0) {
      return '$zoneName • ${_fmtDuration(durationMin * 60)}';
    }

    return zoneName;
  }

  String _normalizeZoneLabel(String raw) {
    final body = raw.trim();
    final bulletIndex = body.indexOf('•');
    if (bulletIndex <= 0) {
      return body;
    }
    return body.substring(0, bulletIndex).trim();
  }

  String _formatDurationUnit(
    int value, {
    required bool isVietnamese,
    required String vi,
    required String en,
  }) {
    if (isVietnamese) {
      return '$value $vi';
    }
    final suffix = value == 1 ? en : '${en}s';
    return '$value $suffix';
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
