import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lupus_arena/GameNotifier.dart';
import 'package:lupus_arena/services/locale_provider.dart';
import 'package:lupus_arena/ui/screens/lobby_screen.dart';
import 'package:lupus_arena/ui/theme/lupus_assets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('LobbyActionButtons Specifications', () {
    test('Button assets constants and files exist', () {
      expect(LupusAssets.btnCreateRoomAsset, equals('assets/images/btn_create_room.png'));
      expect(LupusAssets.btnCreateRoomBlankAsset, equals('assets/images/btn_create_room_blank.png'));
      expect(LupusAssets.btnCodeRoomAsset, equals('assets/images/btn_code_room.png'));
      expect(LupusAssets.btnCodeRoomBlankAsset, equals('assets/images/btn_code_room_blank.png'));
      expect(LupusAssets.btnJoinRoomAsset, equals('assets/images/btn_join_room.png'));
      expect(LupusAssets.btnJoinRoomBlankAsset, equals('assets/images/btn_join_room_blank.png'));

      expect(File('assets/images/btn_create_room.png').existsSync(), isTrue);
      expect(File('assets/images/btn_create_room_blank.png').existsSync(), isTrue);
      expect(File('assets/images/btn_code_room.png').existsSync(), isTrue);
      expect(File('assets/images/btn_code_room_blank.png').existsSync(), isTrue);
      expect(File('assets/images/btn_join_room.png').existsSync(), isTrue);
      expect(File('assets/images/btn_join_room_blank.png').existsSync(), isTrue);
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

    testWidgets('LobbyActionButtons updates button labels dynamically when locale changes', (tester) async {
      final localeProvider = LocaleProvider();
      await localeProvider.setLocale('fr');
      final codeController = TextEditingController();

      await tester.pumpWidget(
        AnimatedBuilder(
          animation: localeProvider,
          builder: (context, _) {
            return MaterialApp(
              locale: localeProvider.locale,
              supportedLocales: const [Locale('fr'), Locale('en'), Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: Scaffold(
                body: LobbyActionButtons(
                  gameState: const LupusGameState(
                    currentUserId: 'test-user',
                    currentUserName: 'TestUser',
                    agoraUid: 12345,
                  ),
                  codeController: codeController,
                  localeProvider: localeProvider,
                  onCreate: () {},
                  onJoin: () {},
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('CRÉER UN SALON'), findsOneWidget);
      expect(find.text('REJOINDRE'), findsOneWidget);

      await localeProvider.setLocale('en');
      await tester.pumpAndSettle();

      expect(find.text('CREATE ROOM'), findsOneWidget);
      expect(find.text('JOIN'), findsOneWidget);

      await localeProvider.setLocale('ar');
      await tester.pumpAndSettle();

      expect(find.text('إنشاء غرفة'), findsOneWidget);
      expect(find.text('انضمام'), findsOneWidget);
    });
  });
}
