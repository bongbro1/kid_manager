import 'package:flutter/material.dart';
import 'package:kid_manager/helpers/phone/phone_helps.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/user/app_user_extensions.dart';
import 'package:kid_manager/viewmodels/location/parent_location_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/views/chat/family_group_chat_screen.dart';
import 'package:kid_manager/views/location/child_detail_map_screen.dart';
import 'package:kid_manager/widgets/location/parent_child_list_item.dart';
import 'package:provider/provider.dart';

class ParentChildrenListScreen extends StatelessWidget {
  const ParentChildrenListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<UserVm>();
    final children = vm.locationMembers;
    final locationVm = context.watch<ParentLocationVm>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.parentChildrenListTitle)),
      backgroundColor: colorScheme.background,
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
                    childAvatarUrl: child.avatarUrl,
                    childTimeZone: child.timezone,
                  ),
                ),
              );
            },
            onLocate: () {
              Navigator.pop(context, child);
            },
            onChat: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FamilyGroupChatScreen(),
                ),
              );
            },
            onPhone: () async {
              await handleCallChildByProfile(
                context: context,
                childId: child.uid,
                childName: child.displayLabel,
              );
            },
          );
        },
      ),
    );
  }
}
