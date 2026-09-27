import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lupus_arena/AgoraVoiceService.dart';
import 'package:lupus_arena/models/game_room.dart';
import 'package:lupus_arena/models/player_model.dart';
import 'package:lupus_arena/ui/bento/room_report_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UGC Moderation & Local Agora Mute Tests', () {
    test('AgoraVoiceService gère le mute local individuel des joueurs', () async {
      final voice = AgoraVoiceService();
      expect(voice.locallyMutedUids.value, isEmpty);
      expect(voice.isUserLocallyMuted(101), isFalse);

      await voice.muteRemoteAudioStream(101, true);
      expect(voice.isUserLocallyMuted(101), isTrue);
      expect(voice.locallyMutedUids.value.contains(101), isTrue);

      await voice.toggleMuteRemoteUser(101);
      expect(voice.isUserLocallyMuted(101), isFalse);

      await voice.muteRemoteAudioStream(202, true);
      expect(voice.isUserLocallyMuted(202), isTrue);

      await voice.leaveChannel();
      expect(voice.locallyMutedUids.value, isEmpty);
    });

    testWidgets('RoomReportDialog affiche les joueurs présents et permet le mute local', (tester) async {
      final room = GameRoom(
        roomCode: 'TEST99',
        hostId: 'user_1',
        players: {
          'user_1': const PlayerModel(id: 'user_1', name: 'Moi', agoraUid: 111),
          'user_2': const PlayerModel(id: 'user_2', name: 'Joueur_Suspect', agoraUid: 222),
          'user_3': const PlayerModel(id: 'user_3', name: 'Autre_Joueur', agoraUid: 333),
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomReportDialog(
              room: room,
              currentUserId: 'user_1',
            ),
          ),
        ),
      );

      expect(find.text('Moi'), findsNothing);
      expect(find.text('Joueur_Suspect'), findsOneWidget);
      expect(find.text('Autre_Joueur'), findsOneWidget);

      final muteButtons = find.byIcon(Icons.volume_up_rounded);
      expect(muteButtons, findsNWidgets(2));

      await tester.tap(muteButtons.first);
      await tester.pump();

      expect(AgoraVoiceService().isUserLocallyMuted(222), isTrue);
      expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
    });
  });
}
