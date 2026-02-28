// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:kid_manager/core/sos/sos_alarm_player.dart';
// import 'package:kid_manager/services/notifications/sos_notification_service.dart';
// import 'package:kid_manager/viewmodels/location/sos_view_model.dart';
// import 'package:provider/provider.dart';

// class SosView extends StatefulWidget {
//   final double lat;
//   final double lng;
//   final double? acc;
//   final String? familyId;
//   final String? sosId;

//   const SosView({
//     super.key,
//     required this.lat,
//     required this.lng,
//     this.acc,
//     this.familyId,
//     this.sosId,
//   });

//   @override
//   State<SosView> createState() => _SosViewState();
// }

// class _SosViewState extends State<SosView> {
//   StreamSubscription? _sub;
//   bool _closing = false;

//   Future<void> _closeToHome() async {
//     if (_closing) return;
//     _closing = true;

//     await SosAlarmPlayer.instance.stop();

//     if (!mounted) return;

//     // ✅ Pop đúng 1 màn SOS. Nếu bạn muốn chắc chắn về Home,
//     // hãy dùng popUntil với route đầu tiên.
//     Navigator.of(context).popUntil((route) => route.isFirst);
//   }

//   @override
//   void initState() {
//     super.initState();

//     final isIncomingSos = widget.familyId != null && widget.sosId != null;

//     if (isIncomingSos) {
//       SosAlarmPlayer.instance.startLoop();

//       _sub = FirebaseFirestore.instance
//           .doc('families/${widget.familyId}/sos/${widget.sosId}')
//           .snapshots()
//           .listen(
//             (snap) {
//               final d = snap.data();
//               if (d == null) return;

//               if (d['status'] == 'resolved') {
//                 _closeToHome(); // ✅ chỉ đóng 1 lần
//               }
//             },
//             onError: (e) {
//               debugPrint('SOS listen error: $e');
//             },
//           );
//     }
//   }

//   bool hasProvider<T>(BuildContext context) {
//     try {
//       context.read<T>();
//       return true;
//     } catch (_) {
//       return false;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final ok = hasProvider<SosViewModel>(context);
//     debugPrint('SosView: HAS SosViewModel? $ok');

//     if (!ok) {
//       return const Scaffold(
//         body: Center(child: Text('SOS Provider NOT FOUND (debug)')),
//       );
//     }

//     final sosVm = context.watch<SosViewModel>();

//     return Scaffold(
//       appBar: AppBar(title: const Text('SOS')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             if (sosVm.error != null)
//               Text(sosVm.error!, style: const TextStyle(color: Colors.red)),
//             const Spacer(),
//             SizedBox(
//               width: double.infinity,
//               height: 56,
//               child: ElevatedButton(
//                 onPressed: sosVm.sending
//                     ? null
//                     : () async {
//                         final sosId = await context
//                             .read<SosViewModel>()
//                             .triggerSos(
//                               lat: widget.lat,
//                               lng: widget.lng,
//                               acc: widget.acc,
//                             );

//                         if (!mounted) return;

//                         if (sosId != null) {
//                           await _closeToHome();
//                         }
//                       },
//                 child: sosVm.sending
//                     ? const CircularProgressIndicator()
//                     : const Text('GỬI SOS'),
//               ),
//             ),
//             const SizedBox(height: 12),
//             SizedBox(
//               width: double.infinity,
//               height: 56,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//                 onPressed: () async {
//                   if (widget.familyId == null || widget.sosId == null) return;

//                   // ✅ stop ngay cho chắc
//                   await SosAlarmPlayer.instance.stop();

//                   await context.read<SosViewModel>().resolve(
//                     familyId: widget.familyId!,
//                     sosId: widget.sosId!,
//                   );

//                   // ✅ đóng 1 lần thôi (snapshot cũng sẽ gọi nhưng bị chặn bởi _closing)
//                   await _closeToHome();
//                 },
//                 child: const Text('XÁC NHẬN'),
//               ),
//             ),
//             ElevatedButton(
//               onPressed: () => SosNotificationService.instance.testSosSound(),
//               child: const Text('Test SOS Sound'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _sub?.cancel();
//     SosAlarmPlayer.instance.stop();
//     super.dispose();
//   }
// }
