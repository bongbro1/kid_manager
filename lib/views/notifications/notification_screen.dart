import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_route_observer.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/views/notifications/notification_detail_screen.dart';
import 'package:kid_manager/views/notifications/notification_item_view.dart';
import 'package:kid_manager/viewmodels/notification_vm.dart';
import 'package:provider/provider.dart';

import '../../services/storage_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with RouteAware {
  @override
  void initState() {
    super.initState();
    _init();
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
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// 🔥 CHẠY MỖI LẦN MÀN HÌNH ĐƯỢC SHOW LẠI
  @override
  void didPopNext() {
    debugPrint("Notification screen visible again");
    _init(); // reload lại
  }

  Future<void> _init() async {
    final storage = context.read<StorageService>();
    final uid = await storage.getString(StorageKeys.uid);

    if (uid != null && mounted) {
      context.read<NotificationVM>().listen(uid);
    }
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;

    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _onSearch(String keyword) {
    debugPrint('keysearch: ${keyword}');
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationVM>();

    return GestureDetector(
      behavior: HitTestBehavior.translucent, // 👈 quan trọng
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              /// HEADER (đứng im)
              _NotificationHeader(
                onSearch: (keyword) {
                  _onSearch(keyword);
                },
              ),

              /// DIVIDER (đứng im)
              const Divider(height: 2, thickness: 2, color: Color(0xFFF1F5F9)),

              /// LIST (chỉ phần này scroll)
              Expanded(
                child: vm.loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: () async {
                          await vm.refresh();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: vm.notifications.length,
                          itemBuilder: (context, index) {
                            final item = vm.notifications[index];

                            final bool showDateHeader =
                                index == 0 ||
                                !_isSameDay(
                                  item.createdAt,
                                  vm.notifications[index - 1].createdAt,
                                );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                    vm.markAsRead(item.id);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            NotificationDetailScreen(
                                              notificationId: item.id,
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
      text = "HÔM NAY";
    } else if (_isSameDay(date, yesterday)) {
      text = "HÔM QUA";
    } else {
      text = "${date.day}/${date.month}/${date.year}";
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
  final ValueChanged<String> onSearch;

  const _NotificationHeader({Key? key, required this.onSearch})
    : super(key: key);

  @override
  State<_NotificationHeader> createState() => _NotificationHeaderState();
}

class _NotificationHeaderState extends State<_NotificationHeader> {
  bool _isSearching = false;
  bool _isFocused = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  void _onSearch() {
    final keyword = _controller.text.trim();
    widget.onSearch(keyword); // 👈 truyền ngược lên cha
    FocusScope.of(context).unfocus();
  }

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isSearching) {
        setState(() {
          _isSearching = false;
          _controller.clear();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          final slide =
              Tween<Offset>(
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
      key: const ValueKey("normal"),
      alignment: Alignment.center,
      children: [
        const Center(
          child: Text(
            "Thông báo",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _CircleIconButton(icon: Icons.menu, onTap: () {}),
            _CircleIconButton(
              icon: Icons.search,
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
      key: const ValueKey("search"),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white, // 👈 nền trắng hoàn toàn
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _isFocused
                      ? const Color(0xFF2563EB) // focus xanh nhẹ
                      : const Color(0xFFE5E7EB), // viền xám nhẹ
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
                        decoration: const InputDecoration(
                          hintText: "Tìm thông báo",
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
                      _onSearch(); // 👈 gọi hàm search
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

  const _CircleIconButton({required this.icon, required this.onTap});

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
          child: Center(child: Icon(icon, size: 24, color: Colors.black)),
        ),
      ),
    );
  }
}
