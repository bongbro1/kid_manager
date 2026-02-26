import 'package:flutter/material.dart';
import 'package:kid_manager/viewmodels/sos/sos_view_model.dart';
import 'package:provider/provider.dart';

import 'package:kid_manager/viewmodels/location/child_location_view_model.dart';

class SosView extends StatelessWidget {
  const SosView({super.key});

  @override
  Widget build(BuildContext context) {
    final sosVm = context.watch<SosViewModel>();
    final locVm = context.watch<ChildLocationViewModel>();
    final loc = locVm.currentLocation;

    return Scaffold(
      appBar: AppBar(title: const Text('SOS')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Text(
                'Nhấn SOS để gửi cảnh báo khẩn cấp tới tất cả thành viên gia đình.',
                style: TextStyle(fontSize: 14),
              ),
            ),

            const SizedBox(height: 16),

            // Error
            if (sosVm.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  sosVm.error!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),

            if (sosVm.error != null) const SizedBox(height: 12),

            // Location status
            Row(
              children: [
                Icon(
                  loc == null ? Icons.location_off : Icons.location_on,
                  color: loc == null ? Colors.grey : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc == null
                        ? 'Chưa có vị trí hiện tại (đợi GPS)...'
                        : 'Vị trí: ${loc.latitude.toStringAsFixed(6)}, ${loc.longitude.toStringAsFixed(6)} (acc ~${loc.accuracy})',
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Main SOS Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: sosVm.sending
                    ? null
                    : () async {
                        if (loc == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Chưa có vị trí hiện tại'),
                            ),
                          );
                          return;
                        }

                        final sosId = await context
                            .read<SosViewModel>()
                            .triggerSos(
                              lat: loc.latitude,
                              lng: loc.longitude,
                              acc: loc.accuracy,
                            );

                        if (sosId != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Đã gửi SOS')),
                          );
                        }
                      },
                child: sosVm.sending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'GỬI SOS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            if (sosVm.lastSosId != null)
              Text(
                'Last SOS: ${sosVm.lastSosId}',
                style: const TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
