import 'package:flutter_test/flutter_test.dart';
import 'package:lupus_arena/AgoraVoiceService.dart';

void main() {
  group('Agora Voice Service & Token Builder Specifications', () {
    test('Agora credentials and configuration are properly defined', () {
      expect(AgoraVoiceService.defaultAppId, equals('fba9116dce4648a8966952d7f4eba209'));
      expect(AgoraVoiceService.appCertificate, equals('9263c2350773468991e500b63e61d6e1'));
      expect(AgoraVoiceService.appCertificate.isNotEmpty, isTrue);
    });

    test('AgoraTokenBuilder generates a valid RTC 006 token with credentials', () {
      final token = AgoraTokenBuilder.build(
        appId: AgoraVoiceService.defaultAppId,
        appCertificate: AgoraVoiceService.appCertificate,
        channelName: 'lupus_TESTROOM',
        uid: 12345678,
      );

      expect(token, isNotEmpty);
      expect(token.startsWith('006${AgoraVoiceService.defaultAppId}'), isTrue);
    });

    test('deriveUid generates stable deterministic positive 32-bit integers', () {
      final uid1 = AgoraVoiceService.deriveUid('player_alpha');
      final uid2 = AgoraVoiceService.deriveUid('player_alpha');
      final uid3 = AgoraVoiceService.deriveUid('player_beta');

      expect(uid1, equals(uid2));
      expect(uid1 > 0, isTrue);
      expect(uid3 > 0, isTrue);
      expect(uid1, isNot(equals(uid3)));
    });
  });
}
