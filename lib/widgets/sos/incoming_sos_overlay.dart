import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_route_observer.dart';
import 'package:kid_manager/core/sos/sos_alarm_player.dart';
import 'package:kid_manager/core/sos/sos_focus_bus.dart';
import 'package:kid_manager/viewmodels/location/sos_view_model.dart';
import 'package:provider/provider.dart';

class IncomingSosOverlay extends StatefulWidget {
  final String familyId;
  final String myUid;

  const IncomingSosOverlay({
    super.key,
    required this.familyId,
    required this.myUid,
  });

  @override
  State<IncomingSosOverlay> createState() => _IncomingSosOverlayState();
}

class _IncomingSosOverlayState extends State<IncomingSosOverlay> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  DocumentSnapshot<Map<String, dynamic>>? _doc;

  bool _ringing = false;
  bool _resolving = false;
  String? _ignoredSosId;

  @override
  void initState() {
    super.initState();
    debugPrint(
      "OVERLAY initState familyId=${widget.familyId} hash=$hashCode",
    );
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
          .orderBy('createdAt', descending: true)
          .limit(1);

      _sub = q.snapshots().listen(
            (qs) {
          if (!mounted) return;

          if (qs.docs.isEmpty) {
            _clearOverlayAndStopAlarm();
            return;
          }

          final doc = qs.docs.first;
          final data = doc.data();
          final createdBy = data['createdBy']?.toString();

          debugPrint(
            'SOS stream doc=${doc.id} ignored=$_ignoredSosId resolving=$_resolving ringing=$_ringing',
          );

          // Không hiển thị SOS do chính mình tạo
          if (createdBy == widget.myUid) {
            _clearOverlayAndStopAlarm();
            return;
          }

          // Đang resolve chính SOS này -> bỏ qua snapshot active cũ
          if (_ignoredSosId != null && doc.id == _ignoredSosId) {
            debugPrint('Ignore active snapshot for resolving sosId=${doc.id}');
            return;
          }

          if (!mounted) return;
          setState(() => _doc = doc);

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

          _clearOverlayAndStopAlarm();
        },
        cancelOnError: false,
      );
    } catch (e, st) {
      debugPrint('IncomingSosOverlay subscribe() threw: $e');
      debugPrint('stack: $st');
    }
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
  }

  Future<void> _handleConfirm() async {
    final previousDoc = _doc;
    if (previousDoc == null) return;

    final sosId = previousDoc.id;
    final data = previousDoc.data() ?? {};

    final location = data['location'];
    final lat = (location is Map) ? (location['lat'] as num?)?.toDouble() : null;
    final lng = (location is Map) ? (location['lng'] as num?)?.toDouble() : null;
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
      await context.read<SosViewModel>().resolve(
        familyId: widget.familyId,
        sosId: sosId,
      );

      // Đợi rất ngắn để Firestore kịp phát snapshot resolved / query rỗng
      await Future.delayed(const Duration(milliseconds: 400));

      _resolving = false;
      _ignoredSosId = null;

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xác nhận thất bại: $e')),
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
      _subscribe();
    }
  }

  @override
  Widget build(BuildContext context) {
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
              const Expanded(
                child: Text(
                  '🚨 Có SOS khẩn cấp!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  shape: const StadiumBorder(),
                ),
                onPressed: _resolving ? null : _handleConfirm,
                child: Text(_resolving ? 'ĐANG XỬ LÝ' : 'XÁC NHẬN'),
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
    unawaited(SosAlarmPlayer.instance.stop());
    debugPrint(
      "OVERLAY dispose familyId=${widget.familyId} hash=$hashCode",
    );
    super.dispose();
  }
}