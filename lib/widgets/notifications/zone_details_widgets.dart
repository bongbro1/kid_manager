import 'package:flutter/cupertino.dart';
import 'package:kid_manager/models/notifications/notification_detail_model.dart';

class ZoneDetailWidget extends StatelessWidget {
  final NotificationDetailModel detail;
  const ZoneDetailWidget({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final data = detail.data;

    final zoneName = (data['zoneName'] ?? detail.content ?? '').toString();
    final action = (data['action'] ?? '').toString(); // enter/exit
    final zoneType = (data['zoneType'] ?? '').toString(); // safe/danger
    final durationMin = (data['durationMin'] ?? '').toString();

    final rows = <Widget>[
      _row("Địa điểm", zoneName),
      _row("Hành động", action),
      _row("Loại vùng", zoneType),
    ];

    if (durationMin.isNotEmpty && durationMin != "0") {
      rows.add(_row("Thời gian", "$durationMin phút"));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(k, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(v, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}