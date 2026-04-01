import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/views/setting_pages/crop_photo_screen.dart';
import 'package:kid_manager/widgets/app/app_image_modal.dart';

Widget tappablePhoto({
  required BuildContext context,
  required UserVm vm,
  required String? url,
  required String fallbackAsset,
  required Widget child,
  required CropPhotoType cropType,
  Future<bool> Function(int index, File file)? onReplace,
}) {
  final u = (url ?? '').trim();
  final uri = Uri.tryParse(u);
  final hasHttpImage =
      uri != null &&
      uri.host.isNotEmpty &&
      (uri.scheme == 'http' || uri.scheme == 'https');
  final isFile = File(u).existsSync();

  final provider = isFile
      ? FileImage(File(u))
      : hasHttpImage
      ? CachedNetworkImageProvider(u)
      : AssetImage(fallbackAsset) as ImageProvider;

  return GestureDetector(
    onTap: () {
      showImageModal(
        context,
        images: [provider],
        cropType: cropType,
        onReplace: onReplace,
      );
    },
    child: child,
  );
}
