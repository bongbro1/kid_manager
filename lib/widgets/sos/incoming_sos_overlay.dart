import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_route_observer.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/core/sos/sos_alarm_player.dart';
import 'package:kid_manager/core/sos/sos_focus_bus.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/services/notifications/sos_notification_service.dart';
import 'package:kid_manager/viewmodels/location/sos_view_model.dart';
import 'package:provider/provider.dart';

class IncomingSosOverlay extends StatefulWidget {
  final String familyId;
  final String myUid;
  final UserRole? viewerRole;

  const IncomingSosOverlay({
    super.key,
    required this.familyId,
    required this.myUid,
    required this.viewerRole,
  });

  @override
  State<IncomingSosOverlay> createState() => _IncomingSosOverlayState();
}

class _IncomingSosOverlayState extends State<IncomingSosOverlay> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  DocumentSnapshot<Map<String, dynamic>>? _doc;
  Timer? _retryTimer;

  bool _ringing = false;
  bool _resolving = false;
  String? _ignoredSosId;
  int _subscribeRetryCount = 0;

  bool get _canResolveSos => widget.viewerRole?.isAdultManager ?? false;

  DocumentSnapshot<Map<String, dynamic>>? _selectVisibleSos(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    for (final doc in docs) {
      final data = doc.data();
      final createdBy = data['createdBy']?.toString();

      if (createdBy == widget.myUid) {
        continue;
      }

      if (_ignoredSosId != null && doc.id == _ignoredSosId) {
        continue;
      }

      return doc;
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    debugPrint('OVERLAY initState familyId=${widget.familyId} hash=$hashCode');
    _subscribe();
  }

  void _subscribe() {
    _sub?.cancel();
    _sub = null;

    try {
      final q = FirebaseFirestore.instance
          .collection('families')
          .doc(widget.familyId)
          .collection('sos')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true);

      _sub = q.snapshots().listen(
        (qs) {
          if (!mounted) return;
          _subscribeRetryCount = 0;
          _retryTimer?.cancel();
          _retryTimer = null;

          if (qs.docs.isEmpty) {
            _resolving = false;
            _ignoredSosId = null;
            _clearOverlayAndStopAlarm();
            return;
          }

          final hasIgnoredActive =
              _ignoredSosId != null &&
              qs.docs.any((doc) => doc.id == _ignoredSosId);
          final doc = _selectVisibleSos(qs.docs);

          debugPrint(
            'SOS stream active=${qs.docs.length} visible=${doc?.id} '
            'ignored=$_ignoredSosId resolving=$_resolving ringing=$_ringing',
          );

          if (doc == null) {
            if (!hasIgnoredActive) {
              _ignoredSosId = null;
              _resolving = false;
            }
            _clearOverlayAndStopAlarm();
            return;
          }

          if (_ignoredSosId != null && !hasIgnoredActive) {
            _ignoredSosId = null;
            _resolving = false;
          }

          if (!mounted) return;
          if (_doc?.id != doc.id) {
            setState(() => _doc = doc);
          }

          if (!_ringing && !_resolving) {
            _ringing = true;
            unawaited(SosAlarmPlayer.instance.startLoop());
          }
        },
        onError: (Object error, StackTrace st) {
          debugPrint('IncomingSosOverlay stream error: $error');
          debugPrint('stack: $st');

          if (error is FirebaseException) {
            debugPrint('FirebaseException code=${error.code}');
            debugPrint('message=${error.message}');
          }
          _scheduleSubscribeRetry();
        },
        cancelOnError: false,
      );
    } catch (e, st) {
      debugPrint('IncomingSosOverlay subscribe() threw: $e');
      debugPrint('stack: $st');
    }
  }

  void _scheduleSubscribeRetry() {
    if (!mounted || _retryTimer != null) {
      return;
    }

    _subscribeRetryCount += 1;
    final exponent = _subscribeRetryCount > 6 ? 6 : _subscribeRetryCount;
    final delay = Duration(seconds: 1 << (exponent - 1));

    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      if (!mounted) return;
      _subscribe();
    });
  }

  void _clearOverlayAndStopAlarm() {
    if (mounted) {
      setState(() => _doc = null);
    } else {
      _doc = null;
    }

    if (_ringing) {
      _ringing = false;
      unawaited(SosAlarmPlayer.instance.stop());
    }

    unawaited(SosNotificationService.instance.clearActiveAlert());
  }

  Future<void> _handleConfirm() async {
    if (!_canResolveSos) return;

    final previousDoc = _doc;
    if (previousDoc == null) return;
    final sosViewModel = context.read<SosViewModel>();
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final sosId = previousDoc.id;
    final data = previousDoc.data() ?? {};

    final location = data['location'];
    final lat = (location is Map)
        ? (location['lat'] as num?)?.toDouble()
        : null;
    final lng = (location is Map)
        ? (location['lng'] as num?)?.toDouble()
        : null;
    final createdBy = data['createdBy']?.toString();

    debugPrint('Confirm tapped sosId=$sosId');

    // Chặn stream bật chuông lại cho chính SOS này
    _resolving = true;
    _ignoredSosId = sosId;

    if (mounted) {
      setState(() => _doc = null);
    }

    if (_ringing) {
      _ringing = false;
      await SosAlarmPlayer.instance.stop();
    }

    if (lat != null && lng != null) {
      activeTabNotifier.value = 0;
      sosFocusNotifier.value = SosFocus(
        lat: lat,
        lng: lng,
        familyId: widget.familyId,
        sosId: sosId,
        childUid: createdBy,
      );
    }

    try {
      await sosViewModel.resolve(familyId: widget.familyId, sosId: sosId);
      _resolving = false;
      await SosNotificationService.instance.clearActiveAlert();

      debugPrint('Confirm success sosId=$sosId');
    } catch (e) {
      debugPrint('Confirm failed sosId=$sosId error=$e');

      _resolving = false;
      _ignoredSosId = null;

      if (!mounted) return;

      setState(() => _doc = previousDoc);

      if (!_ringing) {
        _ringing = true;
        await SosAlarmPlayer.instance.startLoop();
      }

      messenger.showSnackBar(
        SnackBar(content: Text(sosViewModel.error ?? l10n.sosResolveFailed)),
      );
    }
  }

  @override
  void didUpdateWidget(covariant IncomingSosOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.familyId != widget.familyId) {
      _doc = null;
      _ringing = false;
      _resolving = false;
      _ignoredSosId = null;
      _subscribeRetryCount = 0;
      _retryTimer?.cancel();
      _retryTimer = null;
      _subscribe();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final doc = _doc;
    if (doc == null) return const SizedBox.shrink();

    return SafeArea(
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        color: Colors.red.shade700,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.sos, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.incomingSosEmergencyTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_canResolveSos)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: _resolving ? null : _handleConfirm,
                  child: Text(
                    _resolving
                        ? l10n.incomingSosResolvingButton
                        : l10n.incomingSosConfirmButton,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _retryTimer?.cancel();
    unawaited(SosAlarmPlayer.instance.stop());
    debugPrint('OVERLAY dispose familyId=${widget.familyId} hash=$hashCode');
    super.dispose();
  }
}
