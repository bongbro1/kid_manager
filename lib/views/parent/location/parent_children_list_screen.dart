import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/helpers/phone/phone_helps.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/viewmodels/location/parent_location_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/views/location/child_detail_map_screen.dart';
import 'package:kid_manager/widgets/app/app_notice_card.dart';
import 'package:kid_manager/widgets/location/parent_child_list_item.dart';
import 'package:kid_manager/widgets/parent/phone/add_children_phone.dart';
import 'package:provider/provider.dart';

class ParentChildrenListScreen extends StatelessWidget {
  const ParentChildrenListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserVm>();
    final children = vm.children;
    final locationVm = context.watch<ParentLocationVm>();

    Future<void> handleCallChild(BuildContext context, AppUser child) async {
      String phone = (child.phone ?? '').trim();

      if (phone.isEmpty) {
        final result = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (_) => AddChildPhoneScreen(child: child),
          ),
        );

        if (!context.mounted) return;

        if (result != null && result.trim().isNotEmpty) {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AppNoticeCard(
              type: AppNoticeType.success,
              title: 'Thêm số thành công',
              message: 'Số điện thoại của bé đã được lưu thành công.',
            ),
          );
        }

        return; // ✅ không gọi ngay sau khi thêm
      }

      await launchPhoneCall(context, phone);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách thành viên')),
      backgroundColor: const Color(0xFFF6F7FB),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        itemCount: children.length,
        itemBuilder: (_, i) {
          final child = children[i];
          final location = locationVm.childrenLocations[child.uid];

          return ParentChildListItem(
            child: child,
            location: location,
            onOpenHistory: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChildDetailMapScreen(
                    childId: child.uid,
                  ),
                ),
              );
            },
            onLocate: () {
              Navigator.pop(context, child);
            },
            onChat: () {
              // TODO: mở chat
            },
            onPhone: () async {
              await handleCallChild(context, child);
            },
          );
        },
      ),
    );
  }
}