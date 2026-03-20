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
      setState(() {
        _videoReady = true;
      });
    } catch (_) {
      await controller.dispose();
      _controller = null;
      if (!mounted) return;
      setState(() {
        _videoFailed = true;
      });
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
                colors: [Color(0x18000000), Color(0x66000000)],
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/Illustration.png',
          fit: BoxFit.cover,
          opacity: const AlwaysStoppedAnimation(0.18),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xF2FFFFFF), Color(0xDBF5F8FF)],
            ),
          ),
        ),
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Color(0xFF155EEF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
        Positioned(
          left: 16,
          top: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.94),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _videoFailed
                  ? 'Them file video vao assets/videos de phat that'
                  : 'Video huong dan se hien tai day',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF344054),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
