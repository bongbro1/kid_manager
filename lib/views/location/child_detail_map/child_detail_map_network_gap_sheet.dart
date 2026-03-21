import 'package:flutter/material.dart';
import 'package:kid_manager/helpers/location/location_history_presenter.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/views/location/child_detail_map/child_detail_map_shared_widgets.dart';

class ChildDetailMapNetworkGapSheet extends StatelessWidget {
  final LocationData point;
  final VoidCallback? onClose;

  const ChildDetailMapNetworkGapSheet({
    super.key,
    required this.point,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final gapDuration = point.networkGapDuration ?? Duration.zero;
    final start = point.gapStartDateTime;
    final end = point.gapEndDateTime;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.portable_wifi_off_rounded,
                  color: Color(0xFFF57C00),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mất mạng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bản đồ nối tạm 2 đầu vì dữ liệu bị ngắt trong ${LocationHistoryPresenter.formatDuration(gapDuration)}.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClose != null)
                IconButton(
                  onPressed: onClose,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F4F6),
                  ),
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const ChildDetailMapTagChip(
                text: 'Mất kết nối',
                backgroundColor: Color(0xFFFFF3E0),
                foregroundColor: Color(0xFFF57C00),
              ),
              ChildDetailMapTagChip(
                text: LocationHistoryPresenter.formatDuration(gapDuration),
                backgroundColor: const Color(0xFFF1F3F4),
                foregroundColor: const Color(0xFF5F6368),
              ),
            ],
          ),
          if (start != null && end != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ChildDetailMapInfoCard(
                    label: 'Mất từ',
                    value: LocationHistoryPresenter.formatTime(start),
                    hint: point.dateLabel,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChildDetailMapInfoCard(
                    label: 'Có lại lúc',
                    value: LocationHistoryPresenter.formatTime(end),
                    hint: point.dateLabel,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
