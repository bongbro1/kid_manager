import 'package:flutter/material.dart';
import 'package:kid_manager/features/permissions/permission_step_scaffold.dart';

class MediaPermissionScreen extends StatelessWidget {
  const MediaPermissionScreen({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
    required this.busy,
    required this.onAllow,
    required this.onOpenSettings,
    required this.onSkip,
    this.statusMessage,
    this.media,
  });

  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;
  final bool busy;
  final VoidCallback onAllow;
  final VoidCallback onOpenSettings;
  final VoidCallback onSkip;
  final String? statusMessage;
  final Widget? media;

  @override
  Widget build(BuildContext context) {
    return PermissionStepScaffold(
      currentStep: currentStep,
      totalSteps: totalSteps,
      stepLabels: stepLabels,
      title: 'Bật ảnh và media',
      description:
          'Cho phép truy cập ảnh để đổi avatar, chọn hình, và lưu nội dung cần thiết trong các tính năng phù hợp.',
      helper:
          'Nếu chưa cần dùng ngay, có thể bỏ qua. App sẽ xin lại đúng lúc bạn thực sự thao tác với ảnh hoặc media.',
      primaryLabel: 'Cho phép media',
      settingsLabel: 'Mở cài đặt media',
      icon: Icons.photo_library_rounded,
      color: const Color(0xFF00A888),
      busy: busy,
      statusMessage: statusMessage,
      onPrimary: onAllow,
      onOpenSettings: onOpenSettings,
      onSkip: onSkip,
      media: media,
    );
  }
}
