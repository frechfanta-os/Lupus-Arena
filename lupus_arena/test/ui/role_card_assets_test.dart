import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lupus_arena/models/game_role.dart';
import 'package:lupus_arena/ui/bento/role_card_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RoleAssetMap & Cards Assets Tests', () {
    test('Fond de carte officiel existe bien sous assets/cards/', () {
      final fondFile = File(RoleAssetMap.cardBackPath);
      expect(fondFile.existsSync(), isTrue,
          reason: 'Le fichier ${RoleAssetMap.cardBackPath} doit exister.');

      final cardBackFallbackFile = File(RoleAssetMap.cardBackFallback);
      expect(cardBackFallbackFile.existsSync(), isTrue,
          reason: 'Le fallback ${RoleAssetMap.cardBackFallback} doit exister.');
    });

    test('Chaque rôle avec illustration officielle pointe vers un fichier existant dans assets/cards/', () {
      for (final role in GameRole.values) {
        final path = RoleAssetMap.getImagePath(role);
        if (path != null) {
          expect(path.startsWith('assets/cards/'), isTrue,
              reason: 'Le chemin de $role doit commencer par assets/cards/');
          expect(path.contains('LOUP GAROU ENHANCED'), isFalse,
              reason: 'Aucun chemin ne doit contenir LOUP GAROU ENHANCED');

          final file = File(path);
          expect(file.existsSync(), isTrue,
              reason: 'Le fichier $path pour le rôle $role doit exister physiquement.');
        }
      }
    });

    testWidgets('RoleCardImage affiche correctement un placeholder si imagePath est null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RoleCardImage(
              role: GameRole.mayor,
              width: 80,
              height: 120,
            ),
          ),
        ),
      );

      expect(find.byType(RoleCardImage), findsOneWidget);
      expect(find.byIcon(GameRole.mayor.icon), findsOneWidget);
    });

    testWidgets('RoleCardImage affiche un widget stable pour n\'importe quel rôle du jeu', (tester) async {
      for (final role in GameRole.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RoleCardImage(
                role: role,
                width: 60,
                height: 90,
              ),
            ),
          ),
        );
        expect(find.byType(RoleCardImage), findsOneWidget);
      }
    });

    test('Tous les assets déclarés peuvent être chargés avec succès via rootBundle', () async {

      final backData = await rootBundle.load(RoleAssetMap.cardBackPath);
      expect(backData.lengthInBytes, greaterThan(0),
          reason: 'L\'asset ${RoleAssetMap.cardBackPath} doit pouvoir être chargé');

      final fallbackData = await rootBundle.load(RoleAssetMap.cardBackFallback);
      expect(fallbackData.lengthInBytes, greaterThan(0),
          reason: 'L\'asset ${RoleAssetMap.cardBackFallback} doit pouvoir être chargé');

      for (final role in GameRole.values) {
        final path = RoleAssetMap.getImagePath(role);
        if (path != null) {
          final data = await rootBundle.load(path);
          expect(data.lengthInBytes, greaterThan(0),
              reason: 'L\'asset $path pour le rôle $role doit être chargeable via rootBundle');
        }
      }
    });
  });
}
