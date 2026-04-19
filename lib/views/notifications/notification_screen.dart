import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_navigator.dart';
import 'package:kid_manager/core/app_page_transitions.dart';
import 'package:kid_manager/core/app_route_observer.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';
import 'package:kid_manager/models/notifications/notification_source.dart';
import 'package:kid_manager/views/notifications/notification_detail_screen.dart';
import 'package:kid_manager/views/notifications/notification_item_view.dart';
import 'package:kid_manager/viewmodels/notification_vm.dart';
import 'package:kid_manager/views/notifications/widgets/notification_header.dart';
import 'package:kid_manager/widgets/app/app_scroll_effects.dart';
import 'package:kid_manager/widgets/notifications/birthday_notification_experience.dart';
import 'package:kid_manager/widgets/notifications/notification_empty_view.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({
    super.key,
    this.sources = const [NotificationSource.global],
    this.systemOnly = false,
  });

  final List<NotificationSource> sources;
  final bool systemOnly;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with RouteAware {
  final ScrollController _scrollController = ScrollController();
  final int _maxCountInPage = 20;

  void _applyCurrentFilter() {
    final vm = context.read<NotificationVM>();

    if (widget.systemOnly) {
      vm.setFilter(NotificationFilter.system);
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePendingNavigation();
      if (!mounted) return;
      _applyCurrentFilter();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - _maxCountInPage) {
        context.read<NotificationVM>().loadMore();
      }
    });
  }

  void _handlePendingNavigation() {
    if (!NotificationNavigationState.hasPending) {
      return;
    }

    final item = NotificationNavigationState.consume();

    if (item == null) return;

    Navigator.of(context).push(
      AppPageTransitions.route(
        builder: (_) => NotificationDetailScreen(item: item),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }

    activeTabNotifier.addListener(() {
      if (activeTabNotifier.value == notificationTabIndexNotifier.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handlePendingNavigation();
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    if (!mounted) return;
    context.read<NotificationVM>().refresh();
  }

  void _onFilterChanged(NotificationFilter filter) {
    context.read<NotificationVM>().setFilter(filter);
  }

  void _onReadFilterChanged(NotificationReadFilter filter) {
    context.read<NotificationVM>().setReadFilter(filter);
  }

  void _onSearch(String keyword) {
    context.read<NotificationVM>().setSearch(keyword);
  }

  Future<void> _markAllAsRead() async {
    final vm = context.read<NotificationVM>();
    final l10n = AppLocalizations.of(context);

    if (vm.unreadCount == 0 || vm.markingAllRead) {
      return;
    }

    try {
      final updatedCount = await vm.markAllAsRead();
      if (!mounted) return;
      if (updatedCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.notificationAllReadAlready)),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.notificationMarkAllReadSuccess)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.notificationMarkAllReadError)),
      );
    }
  }

  Future<void> _handleNotificationTap(AppNotification item) async {
    final vm = context.read<NotificationVM>();

    if (item.notificationType == NotificationType.birthday) {
      if (!item.isRead) {
        await vm.markAsRead(item);
      }
      if (!mounted) return;
      await showBirthdayNotificationSheet(context, item: item);
      return;
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      AppPageTransitions.route(
        builder: (_) => NotificationDetailScreen(item: item),
      ),
    );
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<AppNotification> _buildVisibleNotifications(
    List<AppNotification> items,
  ) {
    return items.where((n) {
      if (n.type == 'family_chat') return false;

      if (widget.systemOnly) {
        return n.senderId == 'system' || n.type == 'system';
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationVM>();
    final notifications = _buildVisibleNotifications(vm.notifications);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: vm.loading
                  ? const _NotificationHeaderSkeleton(
                      key: ValueKey('notification-header-skeleton'),
                    )
                  : NotificationHeader(
                      key: const ValueKey('notification-header-content'),
                      searchKeyword: vm.searchKeyword,
                      onSearch: _onSearch,
                      activeFilter: vm.activeFilter,
                      activeReadFilter: vm.activeReadFilter,
                      unreadCount: vm.unreadCount,
                      markingAllRead: vm.markingAllRead,
                      onFilterChanged: _onFilterChanged,
                      onReadFilterChanged: _onReadFilterChanged,
                      onMarkAllRead: _markAllAsRead,
                    ),
            ),
            Divider(
              height: 2,
              thickness: 2,
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: vm.loading
                    ? const _NotificationListSkeletonBody(
                        key: ValueKey('notification-list-skeleton'),
                      )
                    : vm.error != null
                    ? Center(
                        key: const ValueKey('notification-list-error'),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            vm.error!,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        key: const ValueKey('notification-list-content'),
                        onRefresh: () async {
                          await vm.refresh();
                        },
                        child: notifications.isEmpty
                            ? const NotificationEmptyView()
                            : ListView.builder(
                                controller: _scrollController,
                                physics: AppScrollEffects.physics,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                itemCount:
                                    notifications.length + (vm.hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= notifications.length) {
                                    if (!vm.loadingMore) {
                                      return const SizedBox.shrink();
                                    }

                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 24,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  final item = notifications[index];
                                  final showDateHeader =
                                      index == 0 ||
                                      !_isSameDay(
                                        item.createdAt,
                                        notifications[index - 1].createdAt,
                                      );

                                  return AppScrollReveal(
                                    key: ValueKey('reveal-${item.id}'),
                                    index: index,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (showDateHeader) ...[
                                          const SizedBox(height: 16),
                                          _buildDateHeader(item.createdAt!),
                                          const SizedBox(height: 12),
                                        ],
                                        NotificationItemView(
                                          key: ValueKey(item.id),
                                          item: item,
                                          onTap: () async =>
                                              _handleNotificationTap(item),
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    String text;
    if (_isSameDay(date, now)) {
      text = l10n.notificationDateToday;
    } else if (_isSameDay(date, yesterday)) {
      text = l10n.notificationDateYesterday;
    } else {
      text = '${date.day}/${date.month}/${date.year}';
    }

    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        style: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
          letterSpacing: 0.2,
          fontSize: Theme.of(context).appTypography.body.fontSize!,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NotificationHeaderSkeleton extends StatelessWidget {
  const _NotificationHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final topInset = MediaQuery.paddingOf(context).top;

    return Skeletonizer(
      enabled: true,
      enableSwitchAnimation: true,
      child: Container(
        color: colorScheme.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: topInset),
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'Notifications',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: Theme.of(
                        context,
                      ).appTypography.screenTitle.fontSize!,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      _NotificationCircleSkeleton(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _NotificationCircleSkeleton(),
                          SizedBox(width: 2),
                          _NotificationCircleSkeleton(),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationListSkeletonBody extends StatelessWidget {
  const _NotificationListSkeletonBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      enableSwitchAnimation: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: const [
          SizedBox(height: 16),
          _NotificationDateSkeleton(),
          SizedBox(height: 12),
          _NotificationCardSkeleton(),
          SizedBox(height: 12),
          _NotificationCardSkeleton(),
          SizedBox(height: 16),
          _NotificationDateSkeleton(label: 'YESTERDAY'),
          SizedBox(height: 12),
          _NotificationCardSkeleton(),
          SizedBox(height: 12),
          _NotificationCardSkeleton(),
          SizedBox(height: 12),
          _NotificationCardSkeleton(),
        ],
      ),
    );
  }
}

class _NotificationCircleSkeleton extends StatelessWidget {
  const _NotificationCircleSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colorScheme.outlineVariant.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _NotificationDateSkeleton extends StatelessWidget {
  const _NotificationDateSkeleton({this.label = 'TODAY'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(alignment: Alignment.centerLeft, child: Text(label));
  }
}

class _NotificationCardSkeleton extends StatelessWidget {
  const _NotificationCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: theme.brightness == Brightness.light
            ? const [
                BoxShadow(
                  color: Color(0x0C000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ]
            : [],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: Text(
                        'Notification title placeholder',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Text(
                          '2m ago',
                          textAlign: TextAlign.right,
                          style: textTheme.labelMedium,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'This is a preview line for the notification body.',
                  maxLines: 1,
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
