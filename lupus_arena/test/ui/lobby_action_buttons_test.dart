import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lupus_arena/GameNotifier.dart';
import 'package:lupus_arena/ui/screens/lobby_screen.dart';
import 'package:lupus_arena/ui/theme/lupus_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LobbyActionButtons Specifications', () {
    test('Button assets constants and files exist', () {
      expect(LupusAssets.btnCreateRoomAsset, equals('assets/images/btn_create_room.png'));
      expect(LupusAssets.btnCodeRoomAsset, equals('assets/images/btn_code_room.png'));
      expect(LupusAssets.btnCodeRoomBlankAsset, equals('assets/images/btn_code_room_blank.png'));
      expect(LupusAssets.btnJoinRoomAsset, equals('assets/images/btn_join_room.png'));

      expect(File('assets/images/btn_create_room.png').existsSync(), isTrue);
      expect(File('assets/images/btn_code_room.png').existsSync(), isTrue);
      expect(File('assets/images/btn_code_room_blank.png').existsSync(), isTrue);
      expect(File('assets/images/btn_join_room.png').existsSync(), isTrue);
    });

    testWidgets('LobbyActionButtons renders 3 buttons and text field', (tester) async {
      final codeController = TextEditingController();
      bool createTriggered = false;
      bool joinTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LobbyActionButtons(
              gameState: const LupusGameState(
                currentUserId: 'test-user',
                currentUserName: 'TestUser',
                agoraUid: 12345,
              ),
              codeController: codeController,
              onCreate: () => createTriggered = true,
              onJoin: () => joinTriggered = true,
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(AspectRatio), findsNWidgets(3));

      await tester.enterText(find.byType(TextField), 'abc123');
      await tester.pump();
      expect(codeController.text, equals('ABC123'));

      final aspectRatios = find.byType(AspectRatio);
      await tester.tap(aspectRatios.first);
      await tester.pumpAndSettle();
      expect(createTriggered, isTrue);

      await tester.tap(aspectRatios.last);
      await tester.pumpAndSettle();
      expect(joinTriggered, isTrue);
    });
  });
}
