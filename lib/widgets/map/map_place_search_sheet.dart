import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/location/map_place_search_result.dart';
import 'package:kid_manager/services/location/mapbox_place_search_service.dart';

Future<MapPlaceSearchResult?> showMapPlaceSearchSheet({
  required BuildContext context,
  required String title,
  String? hintText,
  String initialQuery = '',
  double? proximityLatitude,
  double? proximityLongitude,
  MapboxPlaceSearchService service = const MapboxPlaceSearchService(),
}) {
  return showModalBottomSheet<MapPlaceSearchResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _MapPlaceSearchSheet(
        title: title,
        hintText: hintText,
        initialQuery: initialQuery,
        proximityLatitude: proximityLatitude,
        proximityLongitude: proximityLongitude,
        service: service,
      );
    },
  );
}

class _MapPlaceSearchSheet extends StatefulWidget {
  const _MapPlaceSearchSheet({
    required this.title,
    required this.hintText,
    required this.initialQuery,
    required this.proximityLatitude,
    required this.proximityLongitude,
    required this.service,
  });

  final String title;
  final String? hintText;
  final String initialQuery;
  final double? proximityLatitude;
  final double? proximityLongitude;
  final MapboxPlaceSearchService service;

  @override
  State<_MapPlaceSearchSheet> createState() => _MapPlaceSearchSheetState();
}

class _MapPlaceSearchSheetState extends State<_MapPlaceSearchSheet> {
  static const Duration _debounceDuration = Duration(milliseconds: 300);
  static const int _minQueryLength = 2;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  bool _isLoading = false;
  String? _errorText;
  List<MapPlaceSearchResult> _results = const [];
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialQuery;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();

      final initialQuery = _controller.text.trim();
      if (initialQuery.length >= _minQueryLength) {
        _searchNow(initialQuery);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});

    _debounce?.cancel();

    final query = value.trim();
    if (query.length < _minQueryLength) {
      _clearSearchState();
      return;
    }

    _debounce = Timer(_debounceDuration, () {
      _searchNow(query);
    });
  }

  Future<void> _searchNow(String value) async {
    final query = value.trim();
    final currentRequestId = ++_requestId;

    if (query.length < _minQueryLength) {
      _clearSearchState();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final results = await widget.service.search(
        query,
        proximityLatitude: widget.proximityLatitude,
        proximityLongitude: widget.proximityLongitude,
      );

      if (!mounted || currentRequestId != _requestId) return;

      setState(() {
        _results = results;
        _isLoading = false;
        _errorText = null;
      });
    } catch (error) {
      if (!mounted || currentRequestId != _requestId) return;

      setState(() {
        _results = const [];
        _isLoading = false;
        _errorText = error.toString();
      });
    }
  }

  void _clearSearchState() {
    _requestId++;

    if (!mounted) return;
    setState(() {
      _results = const [];
      _errorText = null;
      _isLoading = false;
    });
  }

  void _onClearPressed() {
    _debounce?.cancel();
    _controller.clear();
    _clearSearchState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD3DCE7),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.hintText ??
                          l10n.childLocationMapSearchSubtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF667085),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: _onChanged,
                      onSubmitted: _searchNow,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: l10n.childLocationMapSearchInputHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                onPressed: _onClearPressed,
                                icon: const Icon(Icons.close_rounded),
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF7F9FC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: Color(0xFFE7EDF4),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: Color(0xFFE7EDF4),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: Color(0xFFBFD7FB),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context);
    final query = _controller.text.trim();

    if (query.length < _minQueryLength) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            l10n.childLocationMapSearchMinChars,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF667085),
              height: 1.4,
            ),
          ),
        ),
      );
    }

    if (_isLoading && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorText != null && _results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _errorText!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFB91C1C),
              height: 1.35,
            ),
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            l10n.childLocationMapSearchNoResults,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF667085)),
          ),
        ),
      );
    }

    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: _results.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = _results[index];
            return _PlaceResultTile(
              item: item,
              onTap: () => Navigator.of(context).pop(item),
            );
          },
        ),
        if (_isLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}

class _PlaceResultTile extends StatelessWidget {
  const _PlaceResultTile({required this.item, required this.onTap});

  final MapPlaceSearchResult item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.place_rounded,
                  color: Color(0xFF1A73E8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.fullAddress,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF667085),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.north_west_rounded,
                size: 18,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
