import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class BackgroundLocationGuideVideoCard extends StatefulWidget {
  const BackgroundLocationGuideVideoCard({
    super.key,
    this.assetPath = 'assets/videos/background_location_allow_all_time.mp4',
  });

  final String assetPath;

  @override
  State<BackgroundLocationGuideVideoCard> createState() =>
      _BackgroundLocationGuideVideoCardState();
}

class _BackgroundLocationGuideVideoCardState
    extends State<BackgroundLocationGuideVideoCard> {
  VideoPlayerController? _controller;
  bool _videoReady = false;
  bool _videoFailed = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset(widget.assetPath);
    _controller = controller;

    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted) return;
      setState(() => _videoReady = true);
    } catch (_) {
      await controller.dispose();
      _controller = null;
      if (!mounted) return;
      setState(() => _videoFailed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoReady && _controller != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x12000000), Color(0x33000000)],
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      color: const Color(0xFFF9FCFF),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: const BoxDecoration(
              color: Color(0xFF1683F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _videoFailed
                ? 'Không tải được video hướng dẫn'
                : 'Video hướng dẫn sẽ hiển thị tại đây',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF344054),
            ),
          ),
        ],
      ),
    );
  }
}
