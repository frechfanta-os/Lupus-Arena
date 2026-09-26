import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'locale_provider.dart';

/// Service dédié au partage natif du code de salon (Room Code)
/// avec support multilingue dynamique (Français, Arabe, Anglais)
/// et configuration du `sharePositionOrigin` pour iPad/tablettes.
class RoomShareService {
  /// Génère le message textuel d'invitation selon la langue actuelle du joueur
  static String buildShareMessage(BuildContext? context, String roomCode) {
    String langCode = 'en';

    if (context != null) {
      try {
        langCode = Localizations.localeOf(context).languageCode;
      } catch (_) {
        langCode = LocaleProvider.instance.languageCode;
      }
    } else {
      langCode = LocaleProvider.instance.languageCode;
    }

    switch (langCode.toLowerCase()) {
      case 'ar':
        return '🌕 يكتمل القمر فوق Lupus Arena...\n\n'
            'انضم بسرعة إلى القطيع! 🐺\n\n'
            '🗝️ رمز الغرفة : $roomCode';

      case 'fr':
        return '🌕 La pleine lune se lève sur Lupus Arena...\n\n'
            'Rejoins vite la meute ! 🐺\n\n'
            '🗝️ Code de la room : $roomCode';

      case 'en':
      default:
        return '🌕 The full moon rises over Lupus Arena...\n\n'
            'Join the pack quickly! 🐺\n\n'
            '🗝️ Room code: $roomCode';
    }
  }

  /// Sujet optionnel du partage (ex. pour e-mail ou messageries supportant le subject)
  static String buildShareSubject(BuildContext? context) {
    String langCode = 'en';

    if (context != null) {
      try {
        langCode = Localizations.localeOf(context).languageCode;
      } catch (_) {
        langCode = LocaleProvider.instance.languageCode;
      }
    } else {
      langCode = LocaleProvider.instance.languageCode;
    }

    switch (langCode.toLowerCase()) {
      case 'ar':
        return 'انضم إلى مباراتي في Lupus Arena! 🐺';
      case 'fr':
        return 'Rejoins ma partie Lupus Arena ! 🐺';
      case 'en':
      default:
        return 'Join my Lupus Arena game! 🐺';
    }
  }

  /// Déclenche le partage natif système avec positionnement précis de la popup (iPad/tablettes)
  static Future<ShareResult> shareRoomCode({
    required BuildContext context,
    required String roomCode,
    Rect? sharePositionOrigin,
  }) async {
    // Si aucun Rect n'est explicitement fourni, on le calcule depuis le BuildContext
    Rect? origin = sharePositionOrigin;
    if (origin == null) {
      try {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          origin = renderBox.localToGlobal(Offset.zero) & renderBox.size;
        }
      } catch (e) {
        debugPrint('[RoomShareService] Erreur calcul RenderBox: $e');
      }
    }

    final message = buildShareMessage(context, roomCode);
    final subject = buildShareSubject(context);

    try {
      return await SharePlus.instance.share(
        ShareParams(
          text: message,
          subject: subject,
          sharePositionOrigin: origin,
        ),
      );
    } catch (e) {
      debugPrint('[RoomShareService] Erreur lors du partage natif: $e');
      return const ShareResult(
        'Erreur de partage',
        ShareResultStatus.unavailable,
      );
    }
  }
}
