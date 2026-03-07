import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kid_manager/models/notifications/notification_detail_model.dart';

class ZoneDetailWidget extends StatelessWidget {
  final NotificationDetailModel detail;
  const ZoneDetailWidget({super.key, required this.detail});

  Map<String, dynamic> get _data => detail.data;

  String get _zoneName =>
      (_data['zoneName'] ?? detail.content ?? '').toString();

  String get _zoneType => (_data['zoneType'] ?? '').toString().toLowerCase();
  String get _action => (_data['action'] ?? '').toString().toLowerCase();

  String get _childName =>
      (_data['childName'] ??
          _data['displayName'] ??
          _data['name'] ??
          _data['fullName'] ??
          'Bé')
          .toString();

  bool get _isDanger => _zoneType == 'danger';
  bool get _isEnter => _action == 'enter';

  String get _descriptionText {
    if (_isDanger && _isEnter) {
      return 'Vị trí của $_childName đã được ghi nhận tại $_zoneName. '
          'Hệ thống ghi nhận bé đã vào vùng nguy hiểm lúc ${_clock(detail.createdAt)}.';
    }
    if (!_isDanger && !_isEnter) {
      return 'Vị trí của $_childName đã được ghi nhận tại $_zoneName. '
          'Hệ thống ghi nhận bé đã rời vùng an toàn lúc ${_clock(detail.createdAt)}.';
    }
    if (_isDanger && !_isEnter) {
      return 'Vị trí của $_childName đã được ghi nhận tại $_zoneName. '
          'Hệ thống ghi nhận bé đã rời vùng nguy hiểm lúc ${_clock(detail.createdAt)}.';
    }
    return 'Vị trí của $_childName đã được cập nhật tại $_zoneName.';
  }

  String _clock(DateTime dt) => DateFormat('HH:mm').format(dt);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDescription(),
        const SizedBox(height: 16),
        _buildMapPreview(),
        const SizedBox(height: 16),
        _buildPrimaryButton(),
        const SizedBox(height: 10),
        _buildSecondaryButton(),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      _descriptionText,
      style: const TextStyle(
        fontSize: 15,
        height: 1.6,
        color: Color(0xFF475569),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildMapPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        color: const Color(0xFFF1F5F9),
        child: Column(
          children: [
            Container(
              height: 170,
              color: const Color(0xFFE5E7EB),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(double.infinity, 170),
                    painter: _MapGridPainter(),
                    child: const SizedBox.expand(),
                  ),
                  Positioned(
                    top: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _zoneName.length > 12
                            ? '${_zoneName.substring(0, 12)}...'
                            : _zoneName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3B82F6).withOpacity(0.18),
                    ),
                    child: Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _zoneName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.map_outlined, size: 18),
          label: const Text('Xem trên bản đồ chính'),
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.phone_in_talk_outlined, size: 18),
          label: const Text('Liên hệ ngay'),
          style: OutlinedButton.styleFrom(
            elevation: 0,
            foregroundColor: const Color(0xFF334155),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFCBD5E1).withOpacity(0.35)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, size.height * 0.38),
      Offset(size.width, size.height * 0.38),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.52, 0),
      Offset(size.width * 0.52, size.height),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}