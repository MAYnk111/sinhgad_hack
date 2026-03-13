import 'package:just_audio/just_audio.dart';
import 'package:maternal_infant_care/domain/services/garbha_sanskar_sound_catalog.dart';

class GarbhaSanskarAudioService {
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _meditationPlayer = AudioPlayer();
  final AudioPlayer _backgroundPlayer = AudioPlayer();

  String? _currentMusicAsset;

  AudioPlayer get musicPlayer => _musicPlayer;

  AudioPlayer get meditationPlayer => _meditationPlayer;

  AudioPlayer get backgroundPlayer => _backgroundPlayer;

  String? get currentMusicAsset => _currentMusicAsset;

  Future<String> _setAssetWithFallback(
    AudioPlayer player,
    String assetPath,
  ) async {
    try {
      await player.setAsset(assetPath);
      return assetPath;
    } catch (_) {
      if (assetPath.endsWith('.mp3')) {
        final fallbackPath = assetPath.replaceFirst(
          RegExp(r'\.mp3$'),
          '.mpeg',
        );
        await player.setAsset(fallbackPath);
        return fallbackPath;
      }
      rethrow;
    }
  }

  Future<void> playMusicTrack(GarbhaSanskarSound sound) async {
    await stopMeditationAudio();

    if (_currentMusicAsset != sound.assetPath) {
      _currentMusicAsset = sound.assetPath;
      await _setAssetWithFallback(_musicPlayer, sound.assetPath);
    }

    await _musicPlayer.play();
  }

  Future<void> toggleMusicPlayback(GarbhaSanskarSound sound) async {
    if (_currentMusicAsset == sound.assetPath && _musicPlayer.playing) {
      await _musicPlayer.pause();
      return;
    }

    await playMusicTrack(sound);
  }

  Future<void> seekMusic(Duration position) async {
    await _musicPlayer.seek(position);
  }

  Future<void> skipMusicBy(int seconds) async {
    final currentPosition = _musicPlayer.position;
    final duration = _musicPlayer.duration ?? Duration.zero;

    var target = currentPosition + Duration(seconds: seconds);
    if (target < Duration.zero) {
      target = Duration.zero;
    }
    if (duration > Duration.zero && target > duration) {
      target = duration;
    }

    await _musicPlayer.seek(target);
  }

  Future<void> stopMusicPlayback() async {
    await _musicPlayer.stop();
    _currentMusicAsset = null;
  }

  Future<void> startMeditationAudio({
    required String meditationAssetPath,
    String? backgroundAssetPath,
  }) async {
    await stopMusicPlayback();
    await _meditationPlayer.stop();
    await _backgroundPlayer.stop();

    await _setAssetWithFallback(_meditationPlayer, meditationAssetPath);
    await _meditationPlayer.setLoopMode(LoopMode.one);
    await _meditationPlayer.play();

    if (backgroundAssetPath != null) {
      await _setAssetWithFallback(_backgroundPlayer, backgroundAssetPath);
      await _backgroundPlayer.setLoopMode(LoopMode.one);
      await _backgroundPlayer.setVolume(0.4);
      await _backgroundPlayer.play();
    }
  }

  Future<void> updateBackgroundSound(String? backgroundAssetPath) async {
    await _backgroundPlayer.stop();

    if (backgroundAssetPath == null) {
      return;
    }

    await _setAssetWithFallback(_backgroundPlayer, backgroundAssetPath);
    await _backgroundPlayer.setLoopMode(LoopMode.one);
    await _backgroundPlayer.setVolume(0.4);

    if (_meditationPlayer.playing) {
      await _backgroundPlayer.play();
    }
  }

  Future<void> pauseMeditationAudio() async {
    await _meditationPlayer.pause();
    await _backgroundPlayer.pause();
  }

  Future<void> resumeMeditationAudio() async {
    await _meditationPlayer.play();
    if (_backgroundPlayer.audioSource != null) {
      await _backgroundPlayer.play();
    }
  }

  Future<void> stopMeditationAudio() async {
    await _meditationPlayer.stop();
    await _backgroundPlayer.stop();
  }

  Future<void> dispose() async {
    await _musicPlayer.dispose();
    await _meditationPlayer.dispose();
    await _backgroundPlayer.dispose();
  }
}
