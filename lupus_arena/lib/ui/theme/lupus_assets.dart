import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Références aux ressources visuelles officielles issues de la génération Stitch.
/// Tente de charger les images locales en priorité (assets/images/...),
/// avec fallback automatique sur les URLs hébergées en haute définition.
class LupusAssets {
  static const String villageNightBgUrl =
      'https://lh3.googleusercontent.com/aida/AEtjO1VLU-7dEtLiciSxE9WCO-H3XbPVMrQ7vSCVwDcc3L_58zWH96UckrkDtc_KRSTCdFxH0GkH7FsU7BlrvIjlne1mlQfa70B4ikGQ-D9FHOGhwa7SUxSpuKZQtgGUk6IarImvbWC8ryKcGzqiM3Q4L95eFGbcaTOnD4y721apGQDyYo6Vjvjtd_aKQ9MMV8_4jl30vFrp5ksk_KK04JEArUfRzpRccaGh_YJm4lQu3SmHFhZIyGnqfR1QdQY';

  static const String wolfSealUrl =
      'https://lh3.googleusercontent.com/aida/AEtjO1XxsqyMQQ0dm_oZGy9LIuAaqn0OSl-sKCKS4kQRFn-rD9oDYNb_by64mIXCAv5LoNswBPn5aHtjVpfPJWO5kC9pSjkZIDp-Ziy1izTdt08o_rzAsXZ5FOneq8be_epHwHoXUdgsB6PYDj9iK_C1yErktt_UkgBYoKT5oBr1XPBJN8Lc34VyZ79tz6c8A-PtW-gMRXvTHWoISelA2nvxGlkZ75OYfSv8whbrXONV9cc40vYly0zg7dgtkw';

  static const String tableNuitMockupUrl =
      'https://lh3.googleusercontent.com/aida/AEtjO1U-YPASGFap0SkMQqeju4P6z6X8-Fx7I-kRcC_tTu6j3whleWxMg_UYkg85Wm2afVt8D2BZCkG0Quowxg-kFoh7LFSZmBUnxPWPpGtFD-FxveMzaD4DuMdjmz-jCmri9iSfi-7S-8CaO2hUftJVOb6f1FRzH0DLHTyc5zN_TMq3shY61DDoXbMsP1pRByPUGJXN6P697kTUjFVEELSwdu4Ws495q3H5-pfta7MPm9yzzvaX2xYy_YgRIZg';

  static const String villageNightBgAsset =
      'assets/images/village_background.png';
  static const String villageNightBgAssetFallback =
      'village_background.png';
  static const String wolfSealAsset = 'assets/images/lupus_seal.png';

  /// Chemin strict sur l'appareil (téléphone)
  static const String lobbyScreenSourcePath =
      'Tous les fichiers/Pictures/lobby screen.jpg';
  static const String lobbyScreenAsset = 'assets/images/lobby screen.jpg';
  static const String lobbyScreenNormalizedAsset = 'assets/images/lobby_screen.jpg';
  static const String lobbyBackdropAsset = 'assets/images/lobby_screen.jpg';
  static const String lobbyFantasyBgAsset = 'assets/images/lobby_screen.jpg';
  static const String lobbyBackdropLegacyAsset = 'assets/images/backlobby.jpg';
  static const String lobbyFantasyBgFallbackAsset = 'assets/images/lobby_fantasy_bg.png';
  static const String lobbyFantasyBgAltAsset = 'assets/images/IMG_20260918_175859.png';
  static const String lobbyCleanBgAsset = 'assets/images/lobby_clean_bg.png';
  static const String cardBackAsset = 'assets/cards/Fond.jpg';
  static const String cardBackFallbackAsset = 'assets/cards/card_back.png';
  static const String tableNuitMockupAsset =
      'assets/images/table_nuit_mockup.png';

  /// Construit le widget officiel de fond pour le Lobby avec résolution automatique :
  /// 1. Tente le fichier local sur l'appareil (`/sdcard/Pictures/lobby screen.jpg` ou candidate)
  /// 2. Si non trouvé ou sur le Web, utilise l'asset embarqué `assets/images/lobby_screen.jpg`
  /// 3. Cascade gracieuse vers les fallbacks en cas de besoin.
  static Widget buildLobbyBackground({
    BoxFit fit = BoxFit.cover,
    Alignment alignment = Alignment.topCenter,
  }) {
    if (!kIsWeb) {
      final fileName = lobbyScreenSourcePath.split('/').last;
      final candidatePaths = [
        '/sdcard/Pictures/$fileName',
        '/storage/emulated/0/Pictures/$fileName',
        lobbyScreenSourcePath,
      ];
      for (final path in candidatePaths) {
        try {
          final file = File(path);
          if (file.existsSync()) {
            return Image.file(
              file,
              fit: fit,
              alignment: alignment,
              errorBuilder: (context, error, stackTrace) => _buildLobbyAssetCascade(fit, alignment),
            );
          }
        } catch (_) {}
      }
    }

    return _buildLobbyAssetCascade(fit, alignment);
  }

  static Widget _buildLobbyAssetCascade(BoxFit fit, Alignment alignment) {
    return Image.asset(
      lobbyScreenNormalizedAsset,
      fit: fit,
      alignment: alignment,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        lobbyScreenAsset,
        fit: fit,
        alignment: alignment,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          lobbyBackdropLegacyAsset,
          fit: fit,
          alignment: alignment,
          errorBuilder: (context, error, stackTrace) => Image.asset(
            lobbyFantasyBgFallbackAsset,
            fit: fit,
            alignment: alignment,
            errorBuilder: (context, error, stackTrace) => Image.asset(
              lobbyFantasyBgAltAsset,
              fit: fit,
              alignment: alignment,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                lobbyCleanBgAsset,
                fit: fit,
                alignment: alignment,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  villageNightBgAssetFallback,
                  fit: fit,
                  alignment: alignment,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Widget intelligent chargeant l'asset local avec bascule gracieuse sur l'URL hébergée
  static Widget adaptiveImage({
    required String assetPath,
    required String networkUrl,
    BoxFit fit = BoxFit.cover,
    Alignment alignment = Alignment.center,
    double? width,
    double? height,
    Widget? placeholder,
  }) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          villageNightBgAssetFallback,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          errorBuilder: (context, error2, stackTrace2) {
            return Image.network(
              networkUrl,
              width: width,
              height: height,
              fit: fit,
              alignment: alignment,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return placeholder ??
                    Container(
                      width: width,
                      height: height,
                      color: const Color(0xFF070B1D),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Color(0xFF9D4EDD)),
                          ),
                        ),
                      ),
                    );
              },
              errorBuilder: (context, error3, stackTrace3) {
                return placeholder ??
                    Container(
                      width: width,
                      height: height,
                      color: const Color(0xFF070B1D),
                    );
              },
            );
          },
        );
      },
    );
  }
}
