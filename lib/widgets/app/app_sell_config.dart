import 'package:kid_manager/features/presentation/shared/app_bottom_bar_config.dart';
import 'package:kid_manager/features/presentation/shared/state/mapbox_controller.dart';
import 'package:kid_manager/models/notifications/notification_source.dart';
import 'package:kid_manager/repositories/chat/family_chat_repository.dart';
import 'package:kid_manager/viewmodels/location/child_location_view_model.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/viewmodels/zones/zone_status_vm.dart';
import 'package:kid_manager/views/chat/family_group_chat_screen.dart';
import 'package:kid_manager/views/child/child_location_screen.dart';
import 'package:kid_manager/views/notifications/notification_debug_screen.dart';
import 'package:kid_manager/views/notifications/notification_tab.dart';
import 'package:kid_manager/views/parent/dashboard/app_management_screen.dart';
import 'package:kid_manager/views/parent/location/parent_location_screen.dart';
import 'package:kid_manager/views/parent/schedule/schedule_screen.dart';
import 'package:kid_manager/views/child/schedule/child_schedule_screen.dart';
import 'package:kid_manager/views/personal_info_screen.dart';
import 'package:provider/provider.dart';

import 'package:kid_manager/repositories/location/location_repository.dart';
import 'package:kid_manager/services/location/location_service.dart';

class AppShellConfig {
  final List<BottomTabConfig> tabs;
  final int chatTabIndex;

  const AppShellConfig(
      this.tabs, {
        required this.chatTabIndex,
      });

  static AppShellConfig parent() => AppShellConfig(
    [
      BottomTabConfig(
        iconAsset: 'assets/icons/location.svg',
        root: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MapboxController()),
            ChangeNotifierProvider(create: (_) => ZoneStatusVm()),
          ],
          child: const ParentAllChildrenMapScreen(),
        ),
      ),
      BottomTabConfig(
        iconAsset: 'assets/icons/dashboard.svg',
        root: const AppManagementScreen(),
      ),
      BottomTabConfig(
        iconAsset: 'assets/icons/sms.svg',
        root: const FamilyGroupChatScreen(),
        showBadge: true,
        badgeCountStreamBuilder: (context) {
          final userVm = context.read<UserVm>();
          final familyId = userVm.familyId;
          final me = userVm.me;

          if (familyId == null || me == null) {
            return Stream.value(0);
          }

          return FamilyChatRepository().watchUnreadCount(
            familyId: familyId,
            uid: me.uid,
          );
        },
      ),
      BottomTabConfig(
        iconAsset: 'assets/icons/bell.svg',
        root: const NotificationTab(
          sources: [NotificationSource.global, NotificationSource.userInbox],
        ),
        showBadge: true,
        isNotificationTab: true,
      ),
      BottomTabConfig(
        iconAsset: 'assets/icons/calendar.svg',
        root: const ScheduleScreen(),
      ),
      BottomTabConfig(
        iconAsset: 'assets/icons/user_nav.svg',
        root: const PersonalInfoScreen(),
      ),
    ],
    chatTabIndex: 2,
  );

  static AppShellConfig child() => AppShellConfig(
    [
      BottomTabConfig(
        iconAsset: 'assets/icons/location.svg',
        root: MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (context) => ChildLocationViewModel(
                context.read<LocationRepository>(),
                context.read<LocationServiceInterface>(),
              ),
            ),
            ChangeNotifierProvider(create: (_) => MapboxController()),
          ],
          child: const ChildLocationScreen(),
        ),
      ),
      BottomTabConfig(
        iconAsset: 'assets/icons/sms.svg',
        root: const FamilyGroupChatScreen(),
        showBadge: true,
        isNotificationTab: true,
        badgeCountStreamBuilder: (context) {
          final userVm = context.read<UserVm>();
          final familyId = userVm.familyId;
          final me = userVm.me;

          if (familyId == null || me == null) {
            return Stream.value(0);
          }

          return FamilyChatRepository().watchUnreadCount(
            familyId: familyId,
            uid: me.uid,
          );
        },
      ),
      BottomTabConfig(
        iconAsset: 'assets/icons/bell.svg',
        root: const NotificationTab(
          sources: [NotificationSource.global, NotificationSource.userInbox],
        ),
        showBadge: true,
        isNotificationTab: true,
      ),
      BottomTabConfig(
        iconAsset: 'assets/icons/calendar.svg',
        root: const ChildScheduleScreen(),
      ),
      BottomTabConfig(
        iconAsset: 'assets/icons/user_nav.svg',
        root: const PersonalInfoScreen(),
      ),
    ],
    chatTabIndex: 1,

  );

  static int get notificationTabIndex {
    final parentIndex = parent().tabs.indexWhere((t) => t.isNotificationTab);

    if (parentIndex >= 0) return parentIndex;

    return child().tabs.indexWhere((t) => t.isNotificationTab);
  }
}