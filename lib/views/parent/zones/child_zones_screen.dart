import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kid_manager/models/zones/geo_zone.dart';
import 'package:kid_manager/repositories/zones/zone_repository.dart';
import 'package:kid_manager/viewmodels/zones/parent_zones_vm.dart';

import 'edit_zone_screen.dart';

class ChildZonesScreen extends StatelessWidget {
  final String childId;
  const ChildZonesScreen({super.key, required this.childId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ParentZonesVm(ZoneRepository())..bind(childId),
      child: _ChildZonesBody(childId: childId),
    );
  }
}

class _ChildZonesBody extends StatelessWidget {
  final String childId;
  const _ChildZonesBody({required this.childId});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ParentZonesVm>();
    final zones = vm.zones;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vùng của bé"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push<GeoZone>(
            context,
            MaterialPageRoute(
              builder: (_) => EditZoneScreen(
                childId: childId,
                zone: null,
                existingZones: zones,
              ),
            ),
          );
          if (res != null) {
            await context.read<ParentZonesVm>().save(childId, res);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Thêm vùng"),
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.error != null
          ? Center(child: Text("Lỗi: ${vm.error}"))
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: zones.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final z = zones[i];
          final color = z.type == ZoneType.danger ? Colors.red : Colors.green;

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: const [
                BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(
                    z.type == ZoneType.danger ? Icons.warning_amber_rounded : Icons.home,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(z.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        "${z.type.label} • ${z.radiusM.toStringAsFixed(0)}m",
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      )
                    ],
                  ),
                ),
                Switch(
                  value: z.enabled,
                  onChanged: (v) => vm.toggleEnabled(childId, z, v),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == "edit") {
                      final edited = await Navigator.push<GeoZone>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditZoneScreen(childId: childId, zone: z,existingZones: zones),
                        ),
                      );
                      if (edited != null) {
                        await vm.save(childId, edited);
                      }
                    } else if (v == "delete") {
                      await vm.delete(childId, z.id);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: "edit", child: Text("Sửa")),
                    PopupMenuItem(value: "delete", child: Text("Xoá")),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}