import 'package:flutter/material.dart';
import 'package:kid_manager/models/app_user.dart';

class AppAvatar extends StatelessWidget {
  final AppUser user;
  final double size;
  final bool grayscale;
  final bool? isOnline;

  const AppAvatar({
    super.key,
    required this.user,
    this.size = 48,
    this.grayscale = false,
    this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final ImageProvider imageProvider =
    user.photoUrl != null && user.photoUrl!.isNotEmpty
        ? NetworkImage(user.photoUrl!)
        : const AssetImage('assets/images/avatar_default.png');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ColorFiltered(
          colorFilter: grayscale
              ? const ColorFilter.mode(
            Colors.grey,
            BlendMode.saturation,
          )
              : const ColorFilter.mode(
            Colors.transparent,
            BlendMode.multiply,
          ),
          child: ClipOval(
            child: Image(
              image: imageProvider,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
        ),

        if (isOnline != null)
          Positioned(
            bottom: -1,
            right: -1,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline! ? Colors.green : Colors.grey,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}