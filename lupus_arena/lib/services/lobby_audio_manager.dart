import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Gestionnaire audio centralisé de Lupus Arena (Lobby & Room).
///
/// Spécifications techniques et coexistence avec Agora RTC :
/// 1. Piste Lobby : 'Tous les fichiers/Download/Aldeas de Niebla.mp3' en boucle.
/// 2. Piste Room : 'Tous les fichiers/Download/Village at Night.mp3' en boucle avec volume bas (15%-20%).
/// 3. Coexistence Agora RTC : AudioContext configuré avec [AndroidAudioFocus.none] et
///    [AVAudioSessionOptions.mixWithOthers] pour garantir que la musique n'interrompt pas,
///    ne coupe pas et ne bloque pas le flux vocal et micro Agora.
/// 4. Isolation stricte : Le bouton Mute Musique n'interagit JAMAIS avec Agora RTC.
class LobbyAudioManager {
  static final LobbyAudioManager instance = LobbyAudioManager._internal();
  factory LobbyAudioManager() => instance;
  LobbyAudioManager._internal() {
    try {
      AudioCache.instance.prefix = '';
    } catch (_) {}
  }

  // --- CHEMINS SOURCES OBLIGATOIRES (CHEMINS STRICTS) ---
  static const String lobbySourcePath = 'Tous les fichiers/Download/Aldeas de Niebla.mp3';
  static const String roomSourcePath = 'Tous les fichiers/Download/Village at Night.mp3';

  // --- FALLBACKS PACKAGÉS DANS L'APPLICATION ---
  static const String lobbyAssetFallback = 'assets/audio/Aldeas de Niebla.mp3';
  static const String roomAssetFallback = 'assets/audio/Village at Night.mp3';

  // Rétrocompatibilité
  static const String lobbyMusicAsset = lobbyAssetFallback;

  AudioPlayer? _lobbyPlayer;
  AudioPlayer? _roomPlayer;

  bool _isLobbyExplicitlyStopped = false;
  bool _isRoomExplicitlyStopped = true;

  // Niveaux de volume par défaut
  double _lobbyVolume = 0.50;
  // Volume Room : strictement maintenu entre 15% et 20% (18%) pour ne pas masquer la voix
  double _roomVolume = 0.18;

  // État Mute Musique (Strictement indépendant du SDK Agora RTC)
  final ValueNotifier<bool> isMusicMutedNotifier = ValueNotifier<bool>(false);

  bool get isMusicMuted => isMusicMutedNotifier.value;
  bool get isMuted => isMusicMuted; // Rétrocompatibilité

  bool get isLobbyPlaying => _lobbyPlayer?.state == PlayerState.playing;
  bool get isRoomPlaying => _roomPlayer?.state == PlayerState.playing;
  bool get isPlaying => isLobbyPlaying || isRoomPlaying;
  bool get isExplicitlyStopped => _isLobbyExplicitlyStopped;

  double get lobbyVolume => _lobbyVolume;
  double get roomVolume => _roomVolume;
  double get volume => _lobbyVolume; // Rétrocompatibilité

  /// Résout la source audio : teste l'existence et la lisibilité du fichier sur l'appareil (/sdcard/Download/...)
  /// et bascule gracieusement sur l'asset local si le fichier n'est pas accessible.
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
          // Vérification réelle de la permission de lecture (évite EACCES / Scoped Storage crash)
          final raf = file.openSync(mode: FileMode.read);
          raf.closeSync();
          return DeviceFileSource(file.path);
        }
      } catch (_) {}
    }

    return AssetSource(fallbackAsset);
  }

  /// Résolution hautement résiliente :
  /// 1. Tente le fichier externe (/sdcard/Download/...) s'il est physiquement lisible.
  /// 2. Si absent ou inaccessible (Scoped storage), extrait le fichier asset packagé
  ///    dans le cache interne privé de l'application (`getTemporaryDirectory`),
  ///    ce qui garantit une lecture locale native par MediaPlayer sans aucune permission requise.
  /// 3. Fallback direct sur AssetSource si l'extraction échoue.
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

    // Extraction sécurisée vers le cache interne de l'application
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

  /// Contexte audio pour coexistence parfaite avec Agora RTC
  AudioContext _buildAgoraCoexistenceContext() {
    return AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.none, // Ne vole jamais le focus VoIP d'Agora
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient, // Mixe avec le chat vocal sans couper
        options: {
          AVAudioSessionOptions.mixWithOthers,
        },
      ),
    );
  }

  /// Initialise le lecteur du Lobby
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

  /// Initialise le lecteur de la Room (In-Game)
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

  // ===========================================================================
  // GESTION DU LOBBY
  // ===========================================================================

  /// Lance la musique du Lobby en boucle
  Future<void> playLobbyMusic({bool resetPosition = false}) async {
    _isLobbyExplicitlyStopped = false;
    // Arrête proprement toute musique de room en cours
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
      // Tentative de secours direct sur l'asset
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

  /// Arrêt forcé de la musique du Lobby
  Future<void> stopLobbyMusic() async {
    _isLobbyExplicitlyStopped = true;
    if (_lobbyPlayer != null) {
      try {
        await _lobbyPlayer!.stop();
        debugPrint('[LobbyAudioManager] ⏹️ Musique Lobby arrêtée.');
      } catch (e) {
        debugPrint('[LobbyAudioManager] Erreur stopLobbyMusic: $e');
      }
    }
  }

  /// Arrêt progressif (fade out) de la musique du Lobby lors de la transition vers la Room
  Future<void> fadeOutAndStopLobbyMusic({
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    _isLobbyExplicitlyStopped = true;
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

  /// Met en pause temporairement la musique du Lobby
  Future<void> pauseLobbyMusic() async {
    if (_lobbyPlayer != null && _lobbyPlayer!.state == PlayerState.playing) {
      try {
        await _lobbyPlayer!.pause();
        debugPrint('[LobbyAudioManager] ⏸️ Musique Lobby mise en pause.');
      } catch (e) {
        debugPrint('[LobbyAudioManager] Erreur pauseLobbyMusic: $e');
      }
    }
  }

  /// Reprend la musique du Lobby
  Future<void> resumeLobbyMusic() async {
    if (!_isLobbyExplicitlyStopped && _lobbyPlayer != null) {
      try {
        await _lobbyPlayer!.resume();
        debugPrint('[LobbyAudioManager] ▶️ Musique Lobby reprise.');
      } catch (e) {
        debugPrint('[LobbyAudioManager] Erreur resumeLobbyMusic: $e');
      }
    }
  }

  // ===========================================================================
  // GESTION DE LA ROOM (IN-GAME)
  // ===========================================================================

  /// Lance la musique de la Room en boucle à volume bas (15%-20%)
  Future<void> playRoomMusic({bool resetPosition = false}) async {
    _isRoomExplicitlyStopped = false;
    // Arrête la musique du Lobby
    await stopLobbyMusic();
    await _initRoomPlayer();

    if (_roomPlayer != null && _roomPlayer!.state == PlayerState.playing) {
      return;
    }

    try {
      if (_roomPlayer != null) {
        await _roomPlayer!.stop();
      }
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
      // Tentative de secours direct sur l'asset
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

  /// Arrêt forcé de la musique de la Room
  Future<void> stopRoomMusic() async {
    _isRoomExplicitlyStopped = true;
    if (_roomPlayer != null) {
      try {
        await _roomPlayer!.stop();
        debugPrint('[LobbyAudioManager] ⏹️ Musique Room arrêtée.');
      } catch (e) {
        debugPrint('[LobbyAudioManager] Erreur stopRoomMusic: $e');
      }
    }
  }

  /// Arrêt progressif (fade out) de la musique de la Room
  Future<void> fadeOutAndStopRoomMusic({
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    _isRoomExplicitlyStopped = true;
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

  /// Met en pause la musique de la Room
  Future<void> pauseRoomMusic() async {
    if (_roomPlayer != null && _roomPlayer!.state == PlayerState.playing) {
      try {
        await _roomPlayer!.pause();
        debugPrint('[LobbyAudioManager] ⏸️ Musique Room mise en pause.');
      } catch (e) {
        debugPrint('[LobbyAudioManager] Erreur pauseRoomMusic: $e');
      }
    }
  }

  /// Reprend la musique de la Room
  Future<void> resumeRoomMusic() async {
    if (!_isRoomExplicitlyStopped && _roomPlayer != null) {
      try {
        await _roomPlayer!.resume();
        debugPrint('[LobbyAudioManager] ▶️ Musique Room reprise.');
      } catch (e) {
        debugPrint('[LobbyAudioManager] Erreur resumeRoomMusic: $e');
      }
    }
  }

  // ===========================================================================
  // BOUTON "MUTE MUSIQUE" (ISOLATION TOTALE D'AGORA RTC)
  // ===========================================================================

  /// Bascule l'état Mute de la musique.
  ///
  /// RÈGLE STRICTE : N'interagit JAMAIS avec Agora RTC (aucun appel à RtcEngine,
  /// muteLocalAudioStream, muteAllRemoteAudioStreams, adjustPlaybackSignalVolume).
  /// Les flux micro et voix restent 100% actifs.
  Future<void> toggleMusicMute() async {
    final nextMuteState = !isMusicMuted;
    await setMusicMuted(nextMuteState);
  }

  /// Définit l'état Mute de la musique.
  Future<void> setMusicMuted(bool mute) async {
    isMusicMutedNotifier.value = mute;

    if (mute) {
      // Mute activé : passe le volume local à 0 ou met en pause
      try {
        await _lobbyPlayer?.setVolume(0.0);
        await _roomPlayer?.setVolume(0.0);
      } catch (e) {
        debugPrint('[LobbyAudioManager] Erreur mute setVolume: $e');
      }
      debugPrint('[LobbyAudioManager] 🔇 Musique locale coupée (Agora RTC non impacté).');
    } else {
      // Mute désactivé : rétablit le volume par défaut
      try {
        await _lobbyPlayer?.setVolume(_lobbyVolume);
        await _roomPlayer?.setVolume(_roomVolume);
      } catch (e) {
        debugPrint('[LobbyAudioManager] Erreur unmute setVolume: $e');
      }
      debugPrint('[LobbyAudioManager] 🔊 Musique locale rétablie (Room: ${(_roomVolume * 100).toInt()}%, Agora RTC non impacté).');
    }
  }

  /// Rétrocompatibilité pour toggleMute
  Future<void> toggleMute() async => toggleMusicMute();

  /// Ajuste le volume sonore général du lobby
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

  /// Ajuste le volume sonore de la room (maintenu entre 15% et 20%)
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

  /// Libère toutes les ressources audio
  void dispose() {
    try {
      _isLobbyExplicitlyStopped = true;
      _isRoomExplicitlyStopped = true;
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
