import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lupus_arena/services/audio_manager.dart';
import 'package:lupus_arena/ui/bento/music_mute_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LupusAudioManager & Audio Specifications', () {
    test('Chemins sources obligatoires stricts et fallbacks configurés', () {
      expect(
        LupusAudioManager.lobbySourcePath,
        equals('Tous les fichiers/Download/Aldeas de Niebla.mp3'),
      );
      expect(
        LupusAudioManager.roomSourcePath,
        equals('Tous les fichiers/Download/Village at Night.mp3'),
      );
      expect(
        LupusAudioManager.lobbyAssetFallback,
        equals('assets/audio/Aldeas de Niebla.mp3'),
      );
      expect(
        LupusAudioManager.roomAssetFallback,
        equals('assets/audio/Village at Night.mp3'),
      );
    });

    test('Volume par défaut de la Room subtil entre 15% et 20%', () {
      final manager = LupusAudioManager.instance;
      expect(manager.roomVolume, inInclusiveRange(0.15, 0.20));
      expect(manager.roomVolume, equals(0.18));
    });

    test('Résolution de source : bascule dynamique entre DeviceFileSource et AssetSource', () {
      // Test d'un fichier existant sur le disque
      final lobbySource = LupusAudioManager.resolveAudioSource(
        LupusAudioManager.lobbySourcePath,
        LupusAudioManager.lobbyAssetFallback,
      );
      expect(lobbySource, isA<Source>());

      // Test d'un chemin virtuel inexistant -> bascule sur AssetSource
      final fallbackSource = LupusAudioManager.resolveAudioSource(
        'Chemin/Inexistant/Track.mp3',
        'assets/audio/Aldeas de Niebla.mp3',
      );
      expect(fallbackSource, isA<AssetSource>());
      expect((fallbackSource as AssetSource).path, equals('assets/audio/Aldeas de Niebla.mp3'));
    });

    test('Bascule Mute Musique (Isolation stricte et mise à jour de volume)', () async {
      final manager = LupusAudioManager.instance;
      await manager.setMusicMuted(false);
      expect(manager.isMusicMuted, isFalse);

      await manager.toggleMusicMute();
      expect(manager.isMusicMuted, isTrue);

      await manager.toggleMusicMute();
      expect(manager.isMusicMuted, isFalse);
    });
  });

  group('MusicMuteButton Widget & Isolation Agora RTC', () {
    testWidgets('MusicMuteButton affiche l\'état actif puis bascule en état coupé au clic', (tester) async {
      final manager = LupusAudioManager.instance;
      await manager.setMusicMuted(false);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MusicMuteButton(),
            ),
          ),
        ),
      );

      // État initial non-muté : icône note de musique
      expect(find.byType(MusicMuteButton), findsOneWidget);
      expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
      expect(find.byIcon(Icons.music_off_rounded), findsNothing);

      // Clic sur le bouton Mute
      await tester.tap(find.byType(MusicMuteButton));
      await tester.pumpAndSettle();

      // État muté : icône note coupée (music_off)
      expect(manager.isMusicMuted, isTrue);
      expect(find.byIcon(Icons.music_off_rounded), findsOneWidget);
      expect(find.byIcon(Icons.music_note_rounded), findsNothing);

      // Clic pour réactiver
      await tester.tap(find.byType(MusicMuteButton));
      await tester.pumpAndSettle();

      expect(manager.isMusicMuted, isFalse);
      expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
    });

    testWidgets('MusicMuteButton en mode compact (HUD Top bar) bascule correctement', (tester) async {
      final manager = LupusAudioManager.instance;
      await manager.setMusicMuted(false);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: MusicMuteButton(isCompact: true, size: 32),
            ),
          ),
        ),
      );

      expect(find.byType(MusicMuteButton), findsOneWidget);
      expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);

      await tester.tap(find.byType(MusicMuteButton));
      await tester.pumpAndSettle();

      expect(manager.isMusicMuted, isTrue);
      expect(find.byIcon(Icons.music_off_rounded), findsOneWidget);
    });
  });
}
