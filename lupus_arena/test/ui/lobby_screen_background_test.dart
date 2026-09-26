import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lupus_arena/ui/theme/lupus_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Lobby Screen Image Replacement Specifications', () {
    test('Chemin source strict et constantes de lobby screen définis', () {
      expect(
        LupusAssets.lobbyScreenSourcePath,
        equals('Tous les fichiers/Pictures/lobby screen.jpg'),
      );
      expect(
        LupusAssets.lobbyScreenAsset,
        equals('assets/images/lobby screen.jpg'),
      );
      expect(
        LupusAssets.lobbyScreenNormalizedAsset,
        equals('assets/images/lobby_screen.jpg'),
      );
      expect(
        LupusAssets.lobbyBackdropAsset,
        equals('assets/images/lobby_screen.jpg'),
      );
    });

    test('Les fichiers d\'assets correspondants existent dans assets/images/', () {
      final normalizedFile = File('assets/images/lobby_screen.jpg');
      final legacyFile = File('assets/images/backlobby.jpg');
      final directFile = File('assets/images/lobby screen.jpg');

      expect(normalizedFile.existsSync(), isTrue, reason: 'lobby_screen.jpg doit exister');
      expect(legacyFile.existsSync(), isTrue, reason: 'backlobby.jpg doit exister');
      expect(directFile.existsSync(), isTrue, reason: 'lobby screen.jpg doit exister');

      // Vérifie que les fichiers ont la bonne taille (> 50 KB, JPEG valide)
      expect(normalizedFile.lengthSync(), greaterThan(50000));
      expect(legacyFile.lengthSync(), greaterThan(50000));
      expect(directFile.lengthSync(), greaterThan(50000));
    });

    testWidgets('buildLobbyBackground() génère un widget valide avec BoxFit.cover', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: LupusAssets.buildLobbyBackground(),
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });
  });
}
