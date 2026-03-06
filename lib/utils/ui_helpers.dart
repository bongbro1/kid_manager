import 'package:flutter/material.dart';

/// Loading dạng Overlay (KHÔNG pop Navigator) => tránh treo / pop nhầm sheet.
Future<T> runWithLoading<T>(
  BuildContext context,
  Future<T> Function() action,
) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  if (overlay == null) {
    return await action();
  }

  late final OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => const _BlockingLoadingOverlay(),
  );

  overlay.insert(entry);

  try {
    return await action();
  } finally {
    entry.remove();
  }
}

class _BlockingLoadingOverlay extends StatelessWidget {
  const _BlockingLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        // chặn thao tác
        ModalBarrier(dismissible: false, color: Colors.black26),
        Center(
          child: SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(strokeWidth: 4),
          ),
        ),
      ],
    );
  }
}