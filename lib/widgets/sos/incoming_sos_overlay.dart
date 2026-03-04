import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_route_observer.dart';
import 'package:kid_manager/core/sos/sos_alarm_player.dart';
import 'package:kid_manager/core/sos/sos_focus_bus.dart';
import 'package:kid_manager/viewmodels/location/sos_view_model.dart';
import 'package:kid_manager/widgets/common/notification_modal.dart';
import 'package:provider/provider.dart';
import 'package:kid_manager/widgets/sos/sos_confirmed_card.dart';

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
  StreamSubscription? _sub;
  DocumentSnapshot<Map<String, dynamic>>? _doc;
  bool _ringing = false;

  @override
  void initState() {
    super.initState();
    debugPrint(
      "OVERLAY initState familyId=${widget.familyId} hash=${hashCode}",
    );

    _subscribe();
  }

  void _subscribe() {
    // huỷ stream cũ nếu có (an toàn khi gọi lại)
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
      print("Vào đến đây 1 $q");

      _sub = q.snapshots().listen(
        (qs) async {
          if (!mounted) return;

          if (qs.docs.isEmpty) {
            if (_ringing) {
              _ringing = false;
              await SosAlarmPlayer.instance.stop();
            }
            setState(() => _doc = null);
            return;
          }

          final doc = qs.docs.first;
          final data = doc.data() ?? {};
          final createdBy = data['createdBy']?.toString();

          if (createdBy == widget.myUid) {
            if (_ringing) {
              _ringing = false;
              await SosAlarmPlayer.instance.stop();
            }
            if (mounted) setState(() => _doc = null);
            return;
          }

          setState(() => _doc = doc);

          if (!_ringing) {
            _ringing = true;
            await SosAlarmPlayer.instance.startLoop();
          }
        },
        onError: (Object error, StackTrace st) async {
          //  BẮT LỖI THẬT SỰ TỪ FIRESTORE Ở ĐÂY
          debugPrint(' IncomingSosOverlay stream error: $error');
          debugPrint(' stack: $st');

          if (error is FirebaseException) {
            debugPrint(' FirebaseException code=${error.code}');
            debugPrint(' message=${error.message}');
            // Ví dụ: permission-denied, failed-precondition (missing index), unavailable...
          }

          // reset UI + stop ringing để khỏi kẹt
          if (mounted) setState(() => _doc = null);
          if (_ringing) {
            _ringing = false;
            await SosAlarmPlayer.instance.stop();
          }
        },
        cancelOnError: false,
      );
    } catch (e, st) {
      //  BẮT LỖI SYNC (ví dụ: query invalid, assert fail)
      debugPrint(' IncomingSosOverlay subscribe() threw: $e');
      debugPrint(' stack: $st');
    }
  }

  @override
  void didUpdateWidget(covariant IncomingSosOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.familyId != widget.familyId) {
      _doc = null;
      _ringing = false;
      _subscribe(); // resubscribe theo familyId mới
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = _doc;
    debugPrint("SOS OVERLAY BUILD doc=${doc?.id}");
    if (doc == null) return const SizedBox.shrink();

    final sosId = doc.id;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 110,
      child: SafeArea(
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
                  onPressed: () async {
                    final previousDoc = _doc;
                    if (previousDoc == null) return;

                    final sosId = previousDoc.id;
                    final data = previousDoc.data() ?? {};

                    // ✅ đọc đúng theo schema: location.{lat,lng,acc}
                    final location = data['location'];
                    final lat = (location is Map)
                        ? (location['lat'] as num?)?.toDouble()
                        : null;
                    final lng = (location is Map)
                        ? (location['lng'] as num?)?.toDouble()
                        : null;
                    final acc = (location is Map)
                        ? (location['acc'] as num?)
                        : null;

                    final createdAt = (data['createdAt'] as Timestamp?)
                        ?.toDate();
                    final createdByRole = data['createdByRole']?.toString();
                    final createdByName = data['createdByName']
                        ?.toString(); // ✅ field mới
                    final createdBy = data['createdBy']
                        ?.toString(); // uid người gửi (nếu bạn cần)

                    // ✅ 1) Ẩn overlay + tắt chuông ngay
                    if (mounted) setState(() => _doc = null);
                    if (_ringing) {
                      _ringing = false;
                      await SosAlarmPlayer.instance.stop();
                    }

                    // ✅ 2) Zoom về SOS luôn
                    if (lat != null && lng != null) {
                      activeTabNotifier.value = 0;
                      sosFocusNotifier.value = SosFocus(
                        lat: lat,
                        lng: lng,
                        familyId: widget.familyId,
                        sosId: sosId,
                        childUid:
                            createdBy, // nếu bạn muốn focus theo người gửi thì dùng createdBy
                      );
                    }

                    try {
                      // ✅ resolve
                      await context.read<SosViewModel>().resolve(
                        familyId: widget.familyId,
                        sosId: sosId,
                      );

                      // ✅ fetch lại doc để chắc chắn có resolvedAt (serverTimestamp)
                      final fresh = await previousDoc.reference.get();
                      final freshData = fresh.data() ?? {};
                      final resolvedAt = (freshData['resolvedAt'] as Timestamp?)
                          ?.toDate();

                      if (!mounted) return;
                      // cần sửa lại
                      // NotificationModal.show(
                      //   context,
                      //   width: 320,
                      //   maxHeight: 300,
                      //   child: SosConfirmedCard(
                      //     createdAt: createdAt,
                      //     resolvedAt: resolvedAt,
                      //     createdByRole: createdByRole,
                      //     createdByName: createdByName,
                      //     acc: acc,
                      //   ),
                      // );
                    } catch (e) {
                      // ❌ FAIL -> hiện lại overlay + bật chuông lại
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
                  },
                  child: const Text('XÁC NHẬN'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    SosAlarmPlayer.instance.stop();
    debugPrint("OVERLAY dispose familyId=${widget.familyId} hash=${hashCode}");

    super.dispose();
  }
}
