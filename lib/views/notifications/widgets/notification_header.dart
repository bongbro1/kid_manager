import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';
import 'package:kid_manager/views/notifications/widgets/notification_filter_sheet.dart';

class NotificationHeader extends StatefulWidget {
  const NotificationHeader({
    super.key,
    required this.searchKeyword,
    required this.onSearch,
    required this.activeFilter,
    required this.activeReadFilter,
    required this.unreadCount,
    required this.markingAllRead,
    required this.onFilterChanged,
    required this.onReadFilterChanged,
    required this.onMarkAllRead,
  });

  final String searchKeyword;
  final ValueChanged<String> onSearch;
  final NotificationFilter activeFilter;
  final NotificationReadFilter activeReadFilter;
  final int unreadCount;
  final bool markingAllRead;
  final Function(NotificationFilter) onFilterChanged;
  final ValueChanged<NotificationReadFilter> onReadFilterChanged;
  final Future<void> Function() onMarkAllRead;

  @override
  State<NotificationHeader> createState() => _NotificationHeaderState();
}

class _NotificationHeaderState extends State<NotificationHeader>
    with SingleTickerProviderStateMixin {
  bool _isSearching = false;
  bool _isFocused = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final AnimationController _entranceController;
  late final Animation<double> _entranceOpacity;
  late final Animation<Offset> _entranceOffset;

  void _onSearch(String keyword) {
    widget.onSearch(keyword.trim());
  }

  @override
  void initState() {
    super.initState();
    _controller.text = widget.searchKeyword;
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _entranceOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _entranceOffset =
        Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isSearching) {
        setState(() {
          _isSearching = false;
        });
      }
    });

    _entranceController.forward();
  }

  @override
  void didUpdateWidget(covariant NotificationHeader oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.searchKeyword != widget.searchKeyword) {
      _controller.text = widget.searchKeyword;
    }
  }

  void _showFilter() {
    final l10n = AppLocalizations.of(context);

    Navigator.of(context, rootNavigator: true).push(
      RawDialogRoute<void>(
        barrierDismissible: true,
        barrierLabel: l10n.birthdayCloseButton,
        barrierColor: Colors.black.withValues(alpha: 0.12),
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (routeContext, animation, secondaryAnimation) {
          return NotificationFilterSheet(
            activeFilter: widget.activeFilter,
            activeReadFilter: widget.activeReadFilter,
            onSelected: (filter) {
              widget.onFilterChanged(filter);
              Navigator.of(routeContext, rootNavigator: true).pop();
            },
            onReadFilterSelected: (filter) {
              widget.onReadFilterChanged(filter);
              Navigator.of(routeContext, rootNavigator: true).pop();
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      color: scheme.surface,
      child: FadeTransition(
        opacity: _entranceOpacity,
        child: SlideTransition(
          position: _entranceOffset,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: topInset),
              SizedBox(
                height: 56,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  reverseDuration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        ...previousChildren,
                        ...?switch (currentChild) {
                          final child? => <Widget>[child],
                          null => null,
                        },
                      ],
                    );
                  },
                  transitionBuilder: (child, animation) {
                    final slide =
                        Tween<Offset>(
                          begin: const Offset(0.0, -0.18),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        );

                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: _isSearching
                      ? _buildSearchBox()
                      : _buildNormalHeader(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNormalHeader() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasFilter =
        widget.activeFilter != NotificationFilter.all ||
        widget.activeReadFilter != NotificationReadFilter.all;
    final hasSearch = widget.searchKeyword.isNotEmpty;
    final canMarkAllRead = widget.unreadCount > 0 && !widget.markingAllRead;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(color: colorScheme.surface),
      child: Stack(
        key: const ValueKey('normal'),
        alignment: Alignment.center,
        children: [
          Center(child: _buildAnimatedTitle(theme, colorScheme)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CircleIconButton(
                icon: Icons.tune,
                active: hasFilter,
                color: hasFilter ? colorScheme.primary : colorScheme.onSurface,
                onTap: _showFilter,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CircleIconButton(
                    icon: widget.markingAllRead
                        ? Icons.hourglass_top_rounded
                        : Icons.done_all_rounded,
                    active: canMarkAllRead,
                    color: canMarkAllRead
                        ? colorScheme.primary
                        : colorScheme.outline,
                    tooltip: l10n.notificationMarkAllRead,
                    onTap: canMarkAllRead ? () => widget.onMarkAllRead() : null,
                  ),
                  const SizedBox(width: 2),
                  _CircleIconButton(
                    icon: Icons.search,
                    active: hasSearch || _isSearching,
                    color: hasSearch
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    onTap: () {
                      setState(() {
                        _isSearching = true;
                      });

                      Future.delayed(Duration.zero, _focusNode.requestFocus);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTitle(ThemeData theme, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context);

    return AnimatedSlide(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      offset: _isSearching ? const Offset(0, -0.08) : Offset.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: _isSearching ? 0.92 : 1,
        child: Text(
          l10n.notificationScreenTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: Theme.of(context).appTypography.screenTitle.fontSize!,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

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
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _isFocused
                      ? colorScheme.primary
                      : colorScheme.outline.withValues(alpha: 0.5),
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
                        cursorColor: colorScheme.primary,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                        onChanged: _onSearch,
                        decoration: InputDecoration(
                          hintText: l10n.notificationSearchHint,
                          hintStyle: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.outline,
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
                    child: Icon(
                      Icons.search,
                      size: 20,
                      color: colorScheme.outline,
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
    _entranceController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.color = Colors.black,
    this.active = false,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final bool active;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tip = tooltip;

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: onTap == null ? 0.5 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: active
                  ? scheme.primary.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(100),
            ),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              scale: active ? 1.06 : 1,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: Icon(
                    icon,
                    key: ValueKey('${icon.codePoint}-$active-${onTap == null}'),
                    size: 24,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (tip == null || tip.isEmpty) {
      return button;
    }

    return Tooltip(message: tip, child: button);
  }
}
