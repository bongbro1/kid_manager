import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_route_observer.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';
import 'package:kid_manager/models/notifications/notification_source.dart';
import 'package:kid_manager/views/notifications/notification_detail_screen.dart';
import 'package:kid_manager/views/notifications/notification_item_view.dart';
import 'package:kid_manager/viewmodels/notification_vm.dart';
import 'package:kid_manager/widgets/notifications/notification_empty_view.dart';
import 'package:provider/provider.dart';

class NotificationScreen extends StatefulWidget {
  final List<NotificationSource> sources;
  final bool systemOnly;

  const NotificationScreen({
    super.key,
    this.sources = const [
      NotificationSource.userInbox,
      NotificationSource.global,
    ],
    this.systemOnly = false,
  });

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
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

  void _onSearch(String keyword) {
    context.read<NotificationVM>().setSearch(keyword);
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<AppNotification> _buildVisibleNotifications(List<AppNotification> items) {
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

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _NotificationHeader(
                searchKeyword: vm.searchKeyword,
                onSearch: _onSearch,
                activeFilter: vm.activeFilter,
                onFilterChanged: _onFilterChanged,
              ),
              const Divider(
                height: 2,
                thickness: 2,
                color: Color(0xFFF1F5F9),
              ),
              Expanded(
                child: vm.loading
                    ? const Center(child: CircularProgressIndicator())
                    : vm.error != null
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      vm.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                    : RefreshIndicator(
                  onRefresh: () async {
                    await vm.refresh();
                  },
                  child: notifications.isEmpty
                      ? const NotificationEmptyView()
                      : ListView.builder(
                    controller: _scrollController,
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
                          padding: EdgeInsets.symmetric(vertical: 24),
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

                      return Column(
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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      NotificationDetailScreen(
                                        item: item,
                                      ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    String text;
    if (_isSameDay(date, now)) {
      text = 'HÔM NAY';
    } else if (_isSameDay(date, yesterday)) {
      text = 'HÔM QUA';
    } else {
      text = '${date.day}/${date.month}/${date.year}';
    }

    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _NotificationHeader extends StatefulWidget {
  final String searchKeyword;
  final ValueChanged<String> onSearch;
  final NotificationFilter activeFilter;
  final Function(NotificationFilter) onFilterChanged;

  const _NotificationHeader({
    super.key,
    required this.searchKeyword,
    required this.onSearch,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  @override
  State<_NotificationHeader> createState() => _NotificationHeaderState();
}

class _NotificationHeaderState extends State<_NotificationHeader> {
  bool _isSearching = false;
  bool _isFocused = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final filters = const [
    (NotificationFilter.all, 'Tất cả', Icons.notifications),
    (NotificationFilter.activity, 'Hoạt động', Icons.school),
    (NotificationFilter.alert, 'Cảnh báo', Icons.warning),
    (NotificationFilter.reminder, 'Nhắc nhở', Icons.event),
    (NotificationFilter.system, 'Thông báo hệ thống', Icons.campaign),
  ];

  void _onSearch(String keyword) {
    widget.onSearch(keyword.trim());
  }

  @override
  void initState() {
    super.initState();
    _controller.text = widget.searchKeyword;

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isSearching) {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant _NotificationHeader oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.searchKeyword != widget.searchKeyword) {
      _controller.text = widget.searchKeyword;
    }
  }

  void _showFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Lọc thông báo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: filters.map((f) {
                  final filter = f.$1;
                  final label = f.$2;
                  final icon = f.$3;

                  return ListTile(
                    leading: Icon(icon),
                    title: Text(label),
                    trailing: widget.activeFilter == filter
                        ? const Icon(Icons.check, color: Colors.blue)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      widget.onFilterChanged(filter);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0.0, -0.2),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: _isSearching ? _buildSearchBox() : _buildNormalHeader(),
      ),
    );
  }

  Widget _buildNormalHeader() {
    return Stack(
      key: const ValueKey('normal'),
      alignment: Alignment.center,
      children: [
        const Center(
          child: Text(
            'Thông báo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _CircleIconButton(
              icon: Icons.tune,
              color: widget.activeFilter == NotificationFilter.all
                  ? Colors.black
                  : Colors.blue,
              onTap: _showFilter,
            ),
            _CircleIconButton(
              icon: Icons.search,
              color: widget.searchKeyword.isEmpty
                  ? Colors.black
                  : Colors.blue,
              onTap: () {
                setState(() {
                  _isSearching = true;
                });

                Future.delayed(Duration.zero, () {
                  _focusNode.requestFocus();
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      key: const ValueKey('search'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _isFocused
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Focus(
                      onFocusChange: (value) {
                        setState(() => _isFocused = value);
                      },
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: true,
                        cursorColor: const Color(0xFF2563EB),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                        onChanged: _onSearch,
                        decoration: const InputDecoration(
                          hintText: 'Tìm thông báo',
                          hintStyle: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          isCollapsed: true,
                          filled: true,
                          fillColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      _onSearch(_controller.text);
                      FocusScope.of(context).unfocus();
                    },
                    child: const Icon(
                      Icons.search,
                      size: 20,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.color = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Icon(icon, size: 24, color: color),
          ),
        ),
      ),
    );
  }
}