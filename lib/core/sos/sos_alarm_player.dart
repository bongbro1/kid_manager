import 'package:just_audio/just_audio.dart';

class SosAlarmPlayer {
  SosAlarmPlayer._();
  static final SosAlarmPlayer instance = SosAlarmPlayer._();

  final AudioPlayer _player = AudioPlayer();
  bool _inited = false;

  Future<void> _ensureInit() async {
    if (_inited) return;
    await _player.setAsset('assets/sounds/sos_alarm.mp3');
    _player.setLoopMode(LoopMode.one);
    _inited = true;
  }

  Future<void> startLoop() async {
    await _ensureInit();
    if (_player.playing) return;
    await _player.play();
  }

  Future<void> stop() async {
    if (_player.playing) {
      await _player.stop();
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
