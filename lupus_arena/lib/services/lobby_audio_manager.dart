import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

class LobbyAudioManager with WidgetsBindingObserver {
  static final LobbyAudioManager instance = LobbyAudioManager._internal();
  factory LobbyAudioManager() => instance;
  LobbyAudioManager._internal() {
    try {
      AudioCache.instance.prefix = '';
    } catch (_) {}
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
  }

  static const String lobbySourcePath = 'Tous les fichiers/Download/Aldeas de Niebla.mp3';
  static const String roomSourcePath = 'Tous les fichiers/Download/Village at Night.mp3';

  static const String lobbyAssetFallback = 'assets/audio/Aldeas de Niebla.mp3';
  static const String roomAssetFallback = 'assets/audio/Village at Night.mp3';

  static const String lobbyMusicAsset = lobbyAssetFallback;

  AudioPlayer? _lobbyPlayer;
  AudioPlayer? _roomPlayer;

  bool _isLobbyExplicitlyStopped = false;
  bool _isRoomExplicitlyStopped = true;

  double _lobbyVolume = 0.50;

  double _roomVolume = 0.18;

  final ValueNotifier<bool> isMusicMutedNotifier = ValueNotifier<bool>(false);

  bool get isMusicMuted => isMusicMutedNotifier.value;
  bool get isMuted => isMusicMuted;

  bool get isLobbyPlaying => _lobbyPlayer?.state == PlayerState.playing;
  bool get isRoomPlaying => _roomPlayer?.state == PlayerState.playing;
  bool get isPlaying => isLobbyPlaying || isRoomPlaying;
  bool get isExplicitlyStopped => _isLobbyExplicitlyStopped;

  double get lobbyVolume => _lobbyVolume;
  double get roomVolume => _roomVolume;
  double get volume => _lobbyVolume;

  bool _wasLobbyPlayingBeforeBackground = false;
  bool _wasRoomPlayingBeforeBackground = false;
  bool _isBackgrounded = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _handleAppBackgrounded();
    } else if (state == AppLifecycleState.detached) {
      _handleAppDetached();
    } else if (state == AppLifecycleState.resumed) {
      _handleAppForegrounded();
    }
  }

  void _handleAppBackgrounded() {
    _isBackgrounded = true;
    _wasLobbyPlayingBeforeBackground = isLobbyPlaying;
    _wasRoomPlayingBeforeBackground = isRoomPlaying;
    try {
      _lobbyPlayer?.pause();
    } catch (_) {}
    try {
      _roomPlayer?.pause();
    } catch (_) {}
  }

  void _handleAppDetached() {
    _isBackgrounded = true;
    _wasLobbyPlayingBeforeBackground = false;
    _wasRoomPlayingBeforeBackground = false;
    try {
      _lobbyPlayer?.stop();
    } catch (_) {}
    try {
      _roomPlayer?.stop();
    } catch (_) {}
  }

  void _handleAppForegrounded() {
    _isBackgrounded = false;
    if (_wasLobbyPlayingBeforeBackground && !_isLobbyExplicitlyStopped && !isMusicMuted) {
      try {
        _lobbyPlayer?.resume();
      } catch (_) {}
    }
    if (_wasRoomPlayingBeforeBackground && !_isRoomExplicitlyStopped && !isMusicMuted) {
      try {
        _roomPlayer?.resume();
      } catch (_) {}
    }
    _wasLobbyPlayingBeforeBackground = false;
    _wasRoomPlayingBeforeBackground = false;
  }

  static Source resolveAudioSource(String strictPath, String fallbackAsset) {
    final fileName = strictPath.split('/').last;
    final candidatePaths = [
      '/sdcard/Download/$fileName',
      '/storage/emulated/0/Download/$fileName',
      strictPath,
    ];

    for (final path in candidatePaths) {
      try {
        final file = File(path);
        if (file.existsSync()) {

          final raf = file.openSync(mode: FileMode.read);
          raf.closeSync();
          return DeviceFileSource(file.path);
        }
      } catch (_) {}
    }

    return AssetSource(fallbackAsset);
  }

  static Future<Source> resolvePlayableSource(String strictPath, String fallbackAsset) async {
    final fileName = strictPath.split('/').last;
    final candidatePaths = [
      '/sdcard/Download/$fileName',
      '/storage/emulated/0/Download/$fileName',
      strictPath,
    ];

    for (final path in candidatePaths) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          final raf = file.openSync(mode: FileMode.read);
          raf.closeSync();
          return DeviceFileSource(file.path);
        }
      } catch (_) {}
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final targetFile = File('${tempDir.path}/lupus_audio/$fileName');
      if (targetFile.existsSync() && targetFile.lengthSync() > 1000) {
        return DeviceFileSource(targetFile.path);
      }
      final data = await rootBundle.load(fallbackAsset);
      await targetFile.parent.create(recursive: true);
      await targetFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
      return DeviceFileSource(targetFile.path);
    } catch (e) {
      debugPrint('[LobbyAudioManager] Extraction asset cache: $e');
    }

    return AssetSource(fallbackAsset);
  }

  AudioContext _buildAgoraCoexistenceContext() {
    return AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
        options: {
          AVAudioSessionOptions.mixWithOthers,
        },
      ),
    );
  }

  Future<void> _initLobbyPlayer() async {
    if (_lobbyPlayer == null) {
      final player = AudioPlayer();
      player.audioCache.prefix = '';
      try {
        await player.setAudioContext(_buildAgoraCoexistenceContext());
      } catch (e) {
        debugPrint('[LobbyAudioManager] Contexte audio _lobbyPlayer: $e');
      }
      try {
        await player.setReleaseMode(ReleaseMode.loop);
      } catch (e) {
        debugPrint('[LobbyAudioManager] setReleaseMode _lobbyPlayer: $e');
      }
      try {
        await player.setVolume(isMusicMuted ? 0.0 : _lobbyVolume);
      } catch (e) {
        debugPrint('[LobbyAudioManager] setVolume _lobbyPlayer: $e');
      }
      _lobbyPlayer = player;
    }
  }

  Future<void> _initRoomPlayer() async {
    if (_roomPlayer == null) {
      final player = AudioPlayer();
      player.audioCache.prefix = '';
      try {
        await player.setAudioContext(_buildAgoraCoexistenceContext());
      } catch (e) {
        debugPrint('[LobbyAudioManager] Contexte audio _roomPlayer: $e');
      }
      try {
        await player.setReleaseMode(ReleaseMode.loop);
      } catch (e) {
        debugPrint('[LobbyAudioManager] setReleaseMode _roomPlayer: $e');
      }
      try {
        await player.setVolume(isMusicMuted ? 0.0 : _roomVolume);
      } catch (e) {
        debugPrint('[LobbyAudioManager] setVolume _roomPlayer: $e');
      }
      _roomPlayer = player;
    }
  }

  Future<void> playLobbyMusic({bool resetPosition = false}) async {
    _isLobbyExplicitlyStopped = false;

    if (_isBackgrounded) {
      _wasLobbyPlayingBeforeBackground = true;
      return;
    }

    await stopRoomMusic();
    await _initLobbyPlayer();

    if (_lobbyPlayer != null && _lobbyPlayer!.state == PlayerState.playing) {
      return;
    }

    try {
      if (_lobbyPlayer != null) {
        await _lobbyPlayer!.stop();
      }
      if (!_isLobbyExplicitlyStopped && _lobbyPlayer != null) {
        _lobbyPlayer!.audioCache.prefix = '';
        await _lobbyPlayer!.setReleaseMode(ReleaseMode.loop);
        await _lobbyPlayer!.setVolume(isMusicMuted ? 0.0 : _lobbyVolume);
        if (resetPosition) {
          try {
            await _lobbyPlayer!.seek(Duration.zero);
          } catch (_) {}
        }
        Source source;
        try {
          source = await resolvePlayableSource(lobbySourcePath, lobbyAssetFallback);
        } catch (_) {
          source = resolveAudioSource(lobbySourcePath, lobbyAssetFallback);
        }
        await _lobbyPlayer!.play(source);
        debugPrint('[LobbyAudioManager] 🎵 Musique Lobby ($lobbySourcePath) lancée en boucle.');
      }
    } catch (e) {
      debugPrint('[LobbyAudioManager] Erreur playLobbyMusic: $e');

      try {
        if (_lobbyPlayer != null) {
          _lobbyPlayer!.audioCache.prefix = '';
          await _lobbyPlayer!.play(AssetSource(lobbyAssetFallback));
        }
      } catch (e2) {
        debugPrint('[LobbyAudioManager] Erreur fallback asset Lobby: $e2');
      }
    }
  }

  Future<void> stopLobbyMusic() async {
    _isLobbyExplicitlyStopped = true;
    _wasLobbyPlayingBeforeBackground = false;
    if (_lobbyPlayer != null) {
      try {
        await _lobbyPlayer!.stop();
        debugPrint('[LobbyAudioManager] ⏹️ Musique Lobby arrêtée.');
      } catch (e) {
        debugPrint('[LobbyAudioManager] Erreur stopLobbyMusic: $e');
      }
    }
  }

  Future<void> fadeOutAndStopLobbyMusic({
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    _isLobbyExplicitlyStopped = true;
    _wasLobbyPlayingBeforeBackground = false;
    if (_lobbyPlayer != null && _lobbyPlayer!.state == PlayerState.playing && !isMusicMuted) {
      try {
        const steps = 5;
        final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);
        final currentVol = _lobbyVolume;
        for (int i = steps - 1; i >= 0; i--) {
          await _lobbyPlayer?.setVolume((currentVol * i) / steps);
          await Future.delayed(stepDuration);
        }
      } catch (e) {
        debugPrint('[LobbyAudioManager] Erreur fadeOut Lobby: $e');
      }
    }
    await stopLobbyMusic();
  }

  Future<void> pauseLobbyMusic() async {
    if (_lobbyPlayer != null) {
      try {
        await _lobbyPlayer!.pause();
        debugPrint('[LobbyAudioManager] ⏸️ Musique Lobby mise en pause.');
      } catch (e) {
        debugPrint('[LobbyAudioManager] Erreur pauseLobbyMusic: $e');
      }
    }
  }

  Future<void> resumeLobbyMusic() async {
    if (!_isLobbyExplicitlyStopped && _lobbyPlayer != null && !_isBackgrounded && !isMusicMuted) {
      try {
        await _lobbyPlayer!.resume();
        debugPrint('[LobbyAudioManager] ▶️ Musique Lobby reprise.');
      } catch (e) {
        debugPrint('[LobbyAudioManager] Erreur resumeLobbyMusic: $e');
      }
    }
  }

  Future<void> playRoomMusic({bool resetPosition = false}) async {
    _isRoomExplicitlyStopped = false;

    if (_isBackgrounded) {
      _wasRoomPlayingBeforeBackground = true;
      return;
    }

    await stopLobbyMusic();
    await _initRoomPlayer();

    if (_roomPlayer != null && _roomPlayer!.state == PlayerState.playing) {
      return;
    }

    if (_roomPlayer != null && _roomPlayer!.state == PlayerState.paused && !resetPosition) {
      try {
        await _roomPlayer!.resume();
        debugPrint('[LobbyAudioManager] 🌙 Musique Room ($roomSourcePath) reprise depuis pause.');
        return;
      } catch (_) {}
    }

    try {
      if (!_isRoomExplicitlyStopped && _roomPlayer != null) {
        _roomPlayer!.audioCache.prefix = '';
        await _roomPlayer!.setReleaseMode(ReleaseMode.loop);
        await _roomPlayer!.setVolume(isMusicMuted ? 0.0 : _roomVolume);
        if (resetPosition) {
          try {
            await _roomPlayer!.seek(Duration.zero);
          } catch (_) {}
        }
        Source source;
        try {
          source = await resolvePlayableSource(roomSourcePath, roomAssetFallback);
        } catch (_) {
          source = resolveAudioSource(roomSourcePath, roomAssetFallback);
        }
        await _roomPlayer!.play(source);
        debugPrint('[LobbyAudioManager] 🌙 Musique Room ($roomSourcePath) lancée en boucle (Vol: ${(_roomVolume * 100).toInt()}%).');
      }
    } catch (e) {
      debugPrint('[LobbyAudioManager] Erreur playRoomMusic: $e');

      try {
        if (_roomPlayer != null) {
          _roomPlayer!.audioCache.prefix = '';
          await _roomPlayer!.play(AssetSource(roomAssetFallback));
        }
      } catch (e2) {
        debugPrint('[LobbyAudioManager] Erreur fallback asset Room: $e2');
      }
    }
  }

  Future<void> stopRoomMusic() async {
    _isRoomExplicitlyStopped = true;
    _wasRoomPlayingBeforeBackground = false;
    if (_roomPlayer != null) {
      try {
        await _roomPlayer!.stop();
        debugPrint('[LobbyAudioManager] ⏹️ Musique Room arrêtée.');
      } catch (e) {
        debugPrint('[LobbyAudioManager] Erreur stopRoomMusic: $e');
      }
    }
  }

  Future<void> fadeOutAndStopRoomMusic({
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    _isRoomExplicitlyStopped = true;
    _wasRoomPlayingBeforeBackground = false;
    if (_roomPlayer != null && _roomPlayer!.state == PlayerState.playing && !isMusicMuted) {
      try {
        const steps = 5;
        final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);
        final currentVol = _roomVolume;
        for (int i = steps - 1; i >= 0; i--) {
          await _roomPlayer?.setVolume((currentVol * i) / steps);
          await Future.delayed(stepDuration);
        }
      } catch (e) {
        debugPrint('[LobbyAudioManager] Erreur fadeOut Room: $e');
      }
    }
    await stopRoomMusic();
  }

  Future<void> pauseRoomMusic() async {
    if (_roomPlayer != null) {
      try {
        await _roomPlayer!.pause();
        debugPrint('[LobbyAudioManager] ⏸️ Musique Room mise en pause.');
      } catch (e) {
        debugPrint('[LobbyAudioManager] Erreur pauseRoomMusic: $e');
      }
    }
  }

  Future<void> resumeRoomMusic() async {
    if (!_isRoomExplicitlyStopped && _roomPlayer != null && !_isBackgrounded && !isMusicMuted) {
      try {
        await _roomPlayer!.resume();
        debugPrint('[LobbyAudioManager] ▶️ Musique Room reprise.');
      } catch (e) {
        debugPrint('[LobbyAudioManager] Erreur resumeRoomMusic: $e');
      }
    }
  }

  Future<void> toggleMusicMute() async {
    final nextMuteState = !isMusicMuted;
    await setMusicMuted(nextMuteState);
  }

  Future<void> setMusicMuted(bool mute) async {
    isMusicMutedNotifier.value = mute;

    if (mute) {

      try {
        await _lobbyPlayer?.setVolume(0.0);
        await _roomPlayer?.setVolume(0.0);
      } catch (e) {
        debugPrint('[LobbyAudioManager] Erreur mute setVolume: $e');
      }
      debugPrint('[LobbyAudioManager] 🔇 Musique locale coupée (Agora RTC non impacté).');
    } else {

      try {
        await _lobbyPlayer?.setVolume(_lobbyVolume);
        await _roomPlayer?.setVolume(_roomVolume);
      } catch (e) {
        debugPrint('[LobbyAudioManager] Erreur unmute setVolume: $e');
      }
      debugPrint('[LobbyAudioManager] 🔊 Musique locale rétablie (Room: ${(_roomVolume * 100).toInt()}%, Agora RTC non impacté).');
    }
  }

  Future<void> toggleMute() async => toggleMusicMute();

  Future<void> setVolume(double newVolume) async {
    _lobbyVolume = newVolume.clamp(0.0, 1.0);
    if (_lobbyPlayer != null && !isMusicMuted) {
      try {
        await _lobbyPlayer!.setVolume(_lobbyVolume);
      } catch (e) {
        debugPrint('[LobbyAudioManager] Erreur setVolume: $e');
      }
    }
  }

  Future<void> setRoomVolume(double newVolume) async {
    _roomVolume = newVolume.clamp(0.05, 0.50);
    if (_roomPlayer != null && !isMusicMuted) {
      try {
        await _roomPlayer!.setVolume(_roomVolume);
      } catch (e) {
        debugPrint('[LobbyAudioManager] Erreur setRoomVolume: $e');
      }
    }
  }

  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
      _isLobbyExplicitlyStopped = true;
      _isRoomExplicitlyStopped = true;
      _wasLobbyPlayingBeforeBackground = false;
      _wasRoomPlayingBeforeBackground = false;
      _lobbyPlayer?.stop();
      _lobbyPlayer?.dispose();
      _lobbyPlayer = null;

      _roomPlayer?.stop();
      _roomPlayer?.dispose();
      _roomPlayer = null;
    } catch (e) {
      debugPrint('[LobbyAudioManager] Erreur dispose: $e');
    }
  }
}
