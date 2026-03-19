import 'package:flutter/material.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';
import 'package:kid_manager/features/safe_route/domain/entities/trip.dart';

class SafeRouteTripHistorySheet extends StatelessWidget {
  const SafeRouteTripHistorySheet({
    super.key,
    required this.trips,
    required this.onSelectTrip,
  });

  final List<Trip> trips;
  final ValueChanged<Trip> onSelectTrip;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD3DCE7),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lịch sử tuyến đường',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Chọn một tuyến đã đi để xem lại trên bản đồ hiện tại.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF667085),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: trips.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.fromLTRB(18, 6, 18, 28),
                      child: _EmptyHistoryState(),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
                      itemCount: trips.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final trip = trips[index];
                        return _TripHistoryTile(
                          trip: trip,
                          onTap: () {
                            Navigator.of(context).pop();
                            onSelectTrip(trip);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripHistoryTile extends StatelessWidget {
  const _TripHistoryTile({
    required this.trip,
    required this.onTap,
  });

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle(trip.status);

    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE7EDF4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      trip.routeName?.trim().isNotEmpty == true
                          ? trip.routeName!
                          : 'Tuyến ${trip.routeId.substring(0, trip.routeId.length < 8 ? trip.routeId.length : 8)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusStyle.background,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusStyle.label,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: statusStyle.foreground,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HistoryMetaChip(
                    icon: Icons.schedule_rounded,
                    label: _scheduleLabel(trip),
                  ),
                  _HistoryMetaChip(
                    icon: Icons.repeat_rounded,
                    label: _repeatLabel(trip.repeatWeekdays),
                  ),
                  _HistoryMetaChip(
                    icon: Icons.access_time_rounded,
                    label: _updatedLabel(trip.updatedAt),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _StatusStyle _statusStyle(TripStatus status) {
    switch (status) {
      case TripStatus.completed:
        return const _StatusStyle(
          label: 'Đã đến nơi',
          background: Color(0xFFE8F7ED),
          foreground: Color(0xFF15803D),
        );
      case TripStatus.deviated:
        return const _StatusStyle(
          label: 'Lệch tuyến',
          background: Color(0xFFFFE9E5),
          foreground: Color(0xFFB93815),
        );
      case TripStatus.temporarilyDeviated:
        return const _StatusStyle(
          label: 'Tạm lệch',
          background: Color(0xFFFFF4DF),
          foreground: Color(0xFFB45309),
        );
      case TripStatus.cancelled:
        return const _StatusStyle(
          label: 'Đã hủy',
          background: Color(0xFFF1F5F9),
          foreground: Color(0xFF475569),
        );
      case TripStatus.planned:
        return const _StatusStyle(
          label: 'Đã lên lịch',
          background: Color(0xFFEFF6FF),
          foreground: Color(0xFF1D4ED8),
        );
      case TripStatus.active:
        return const _StatusStyle(
          label: 'Đang theo dõi',
          background: Color(0xFFEAF2FF),
          foreground: Color(0xFF1A73E8),
        );
    }
  }

  String _scheduleLabel(Trip trip) {
    final scheduled = trip.scheduledStartAt;
    if (scheduled == null) {
      return 'Theo dõi ngay';
    }
    return '${scheduled.day.toString().padLeft(2, '0')}/${scheduled.month.toString().padLeft(2, '0')} · ${scheduled.hour.toString().padLeft(2, '0')}:${scheduled.minute.toString().padLeft(2, '0')}';
  }

  String _repeatLabel(List<int> weekdays) {
    if (weekdays.isEmpty) {
      return 'Không lặp lại';
    }
    return weekdays.map(_weekdayLabel).join(', ');
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case 1:
        return 'T2';
      case 2:
        return 'T3';
      case 3:
        return 'T4';
      case 4:
        return 'T5';
      case 5:
        return 'T6';
      case 6:
        return 'T7';
      case 7:
        return 'CN';
    }
    return '';
  }

  String _updatedLabel(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}

class _HistoryMetaChip extends StatelessWidget {
  const _HistoryMetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE7EDF4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF526074)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF526074),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7EDF4)),
      ),
      child: const Text(
        'Chưa có tuyến đường nào được lưu trong lịch sử theo dõi.',
        style: TextStyle(
          fontSize: 12,
          color: Color(0xFF667085),
          height: 1.35,
        ),
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
}
