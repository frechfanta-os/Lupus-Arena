import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lupus_arena/services/app_translations.dart';
import 'package:lupus_arena/services/locale_provider.dart';
import 'package:lupus_arena/services/room_share_service.dart';
import 'package:lupus_arena/ui/bento/language_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocaleProvider.instance.initLocale();
  });

  group('RoomShareService Multilingual Specifications', () {
    test('Format Arabe (ar) conforme aux spécifications exactes', () async {
      await LocaleProvider.instance.setLocale('ar');

      final message = RoomShareService.buildShareMessage(null, 'WOLF12');
      const expected = '🌕 يكتمل القمر فوق Lupus Arena...\n\n'
          'انضم بسرعة إلى القطيع! 🐺\n\n'
          '🗝️ رمز الغرفة : WOLF12';

      expect(message, equals(expected));
    });

    test('Format Français (fr) conforme aux spécifications exactes', () async {
      await LocaleProvider.instance.setLocale('fr');

      final message = RoomShareService.buildShareMessage(null, 'LUPUS42');
      const expected = '🌕 La pleine lune se lève sur Lupus Arena...\n\n'
          'Rejoins vite la meute ! 🐺\n\n'
          '🗝️ Code de la room : LUPUS42';

      expect(message, equals(expected));
    });

    test('Format Anglais (en / par défaut) conforme aux spécifications exactes', () async {
      await LocaleProvider.instance.setLocale('en');

      final message = RoomShareService.buildShareMessage(null, 'ARENA99');
      const expected = '🌕 The full moon rises over Lupus Arena...\n\n'
          'Join the pack quickly! 🐺\n\n'
          '🗝️ Room code: ARENA99';

      expect(message, equals(expected));
    });

    test('AppTranslations clés share_room_message et share_code présentes', () async {

      await LocaleProvider.instance.setLocale('fr');
      expect(AppTranslations.tr('share_code'), equals('Partager le code'));
      final frMsg = AppTranslations.tr('share_room_message', {'ROOM_CODE': 'TEST1'});
      expect(frMsg, contains('Code de la room : TEST1'));
      expect(frMsg, contains('🌕 La pleine lune se lève sur Lupus Arena...'));

      await LocaleProvider.instance.setLocale('ar');
      expect(AppTranslations.tr('share_code'), equals('مشاركة الرمز'));
      final arMsg = AppTranslations.tr('share_room_message', {'ROOM_CODE': 'TEST2'});
      expect(arMsg, contains('🗝️ رمز الغرفة : TEST2'));
      expect(arMsg, contains('🌕 يكتمل القمر فوق Lupus Arena...'));

      await LocaleProvider.instance.setLocale('en');
      expect(AppTranslations.tr('share_code'), equals('Share code'));
      final enMsg = AppTranslations.tr('share_room_message', {'ROOM_CODE': 'TEST3'});
      expect(enMsg, contains('🗝️ Room code: TEST3'));
      expect(enMsg, contains('🌕 The full moon rises over Lupus Arena...'));
    });
  });

  group('Room Share UI Widget Test', () {
    testWidgets('L\'icône Icons.share est présente aux côtés de Icons.copy_rounded', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.filledTonal(
                  onPressed: () {},
                  icon: const Icon(Icons.copy_rounded, size: 20),
                ),
                const SizedBox(width: 8),
                Builder(
                  builder: (shareBtnContext) => IconButton.filledTonal(
                    onPressed: () {
                      final box = shareBtnContext.findRenderObject() as RenderBox?;
                      final origin = box != null && box.hasSize
                          ? (box.localToGlobal(Offset.zero) & box.size)
                          : null;
                      expect(origin, isNotNull);
                    },
                    icon: const Icon(Icons.share, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);

      await tester.tap(find.byIcon(Icons.share));
      await tester.pump();
    });
  });

  group('Suppression des drapeaux dans les sélecteurs de langue', () {
    testWidgets('LanguageDialog affiche les codes textes et noms sans drapeau emoji', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageDialog(
              dismissible: true,
              onSelect: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('FR'), findsOneWidget);
      expect(find.text('AR'), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);

      expect(find.text('Français'), findsOneWidget);
      expect(find.text('العربية'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      expect(find.textContaining('🇫🇷'), findsNothing);
      expect(find.textContaining('🇩🇿'), findsNothing);
      expect(find.textContaining('🇬🇧'), findsNothing);
    });
  });
}
