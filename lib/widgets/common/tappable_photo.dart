import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kid_manager/models/notifications/notification_type.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/widgets/app/app_image_modal.dart';
import 'package:kid_manager/widgets/app/app_notification_dialog.dart';

Widget tappablePhoto({
  required BuildContext context,
  required UserVm vm,
  required String? url,
  required String fallbackAsset,
  required Widget child, // widget hiển thị ảnh (Container/Image/...)
  Future<bool> Function(int index, File file)? onReplace,
}) {
  final u = (url ?? '').trim();
  final provider = u.isNotEmpty
      ? NetworkImage(u)
      : AssetImage(fallbackAsset) as ImageProvider;

  return GestureDetector(
    onTap: () {
      showImageModal(
        context,
        images: [provider],

        onReplace: onReplace == null
            ? null
            : (index, file) async {
                final ok = await onReplace(index, file);
                if (!ok) {
                  NotificationDialog.show(
                    context,
                    type: DialogType.error,
                    title: "Thất bại",
                    message: vm.error ?? 'Cập nhật ảnh thất bại',
                  );
                }
              },
      );
    },
    child: child,
  );
}
