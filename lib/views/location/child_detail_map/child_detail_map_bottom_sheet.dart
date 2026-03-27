import 'package:flutter/material.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/viewmodels/location/child_detail_map_vm.dart';
import 'package:kid_manager/views/location/child_detail_map/child_detail_map_overview_sheet.dart';
import 'package:kid_manager/views/location/child_detail_map/child_detail_map_point_sheet.dart';

class ChildDetailMapBottomSheet extends StatelessWidget {
  final ChildDetailMapVm vm;
  final VoidCallback onClosePoint;
  final Future<void> Function(LocationData point) onPointSelected;
  final DraggableScrollableController controller;

  const ChildDetailMapBottomSheet({
    super.key,
    required this.vm,
    required this.onClosePoint,
    required this.onPointSelected,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final selectedPoint = vm.selectedPoint;
    final latest = vm.latest;

    if (selectedPoint == null && latest == null) {
      return const SizedBox.shrink();
    }

    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: selectedPoint != null ? 0.42 : 0.24,
      minChildSize: 0.16,
      maxChildSize: 0.94,
      snap: true,
      snapSizes: const [0.24, 0.42, 0.68, 0.94],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.97),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 12),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              if (selectedPoint != null)
                SliverToBoxAdapter(
                  child: ChildDetailMapPointSheet(
                    vm: vm,
                    point: selectedPoint,
                    history: vm.cachedHistory,
                    isToday: vm.isToday,
                    onClose: onClosePoint,
                  ),
                )
              else if (latest != null)
                SliverToBoxAdapter(
                  child: ChildDetailMapOverviewSheet(
                    vm: vm,
                    latest: latest,
                    onPointSelected: onPointSelected,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
