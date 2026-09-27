import 'package:flutter/material.dart';
import '../../models/game_role.dart';

class RoleAssetMap {
  static const String cardBackPath = 'assets/cards/Fond.jpg';
  static const String cardBackFallback = 'assets/cards/Fond.jpg';

  static bool hasCardAsset(GameRole role) => getImagePath(role) != null;

  static String? getImagePath(GameRole role) {
    switch (role) {
      case GameRole.simpleVillager:
        return 'assets/cards/Simple villageois.jpg';
      case GameRole.seer:
        return 'assets/cards/Voyante.jpg';
      case GameRole.witch:
        return 'assets/cards/Sorcière.jpg';
      case GameRole.hunter:
        return 'assets/cards/Chasseur.jpg';
      case GameRole.cupid:
        return 'assets/cards/Cupidon.jpg';
      case GameRole.littleGirl:
        return 'assets/cards/Petite fille.jpg';
      case GameRole.thief:
        return 'assets/cards/Voleur.jpg';
      case GameRole.defender:
        return 'assets/cards/Salvateur.jpg';
      case GameRole.elder:
        return 'assets/cards/Ancien.jpg';
      case GameRole.scapegoat:
        return 'assets/cards/Bouc Émissaire.jpg';
      case GameRole.idiot:
        return 'assets/cards/Idiot du village.jpg';
      case GameRole.twoSisters:
        return 'assets/cards/Deux Sœurs.jpg';
      case GameRole.threeBrothers:
        return 'assets/cards/Trois frères.jpg';
      case GameRole.fox:
        return 'assets/cards/Renard.jpg';
      case GameRole.bearTamer:
        return 'assets/cards/Montreur d\'ours.jpg';
      case GameRole.stutteringJudge:
        return 'assets/cards/Juge Bègue.jpg';
      case GameRole.knightRustySword:
        return 'assets/cards/Chevalier à l\'épée roulliée.jpg';
      case GameRole.servantMaid:
        return 'assets/cards/Servante dévoué.jpg';
      case GameRole.actor:
        return 'assets/cards/Comédien.jpg';
      case GameRole.simpleWerewolf:
        return 'assets/cards/Loup noir.jpg';
      case GameRole.bigBadWolf:
        return 'assets/cards/Grand méchant loup.jpg';
      case GameRole.whiteWerewolf:
        return 'assets/cards/Loup blanc.jpg';
      case GameRole.blackWolf:
        return 'assets/cards/Loup noir.jpg';
      case GameRole.vileFatherOfWolves:
        return 'assets/cards/Infect père des loups.jpg';
      case GameRole.wolfCub:
        return 'assets/cards/Chien loup.jpg';
      case GameRole.wildChild:
        return 'assets/cards/Enfant sauvage.jpg';
      case GameRole.pyromaniac:
        return 'assets/cards/Pyromane.jpg';
      case GameRole.raven:
        return 'assets/cards/Corbeau.jpg';
      case GameRole.angel:
        return 'assets/cards/Ange.jpg';
      case GameRole.piedPiper:
        return 'assets/cards/Joueur de flute.jpg';
      case GameRole.sectLeader:
        return 'assets/cards/Abominable Sectaire.jpg';
      case GameRole.thiefOfHearts:
        return 'assets/cards/Gitan.jpg';
      case GameRole.mayor:
        return null;
    }
  }
}

class RoleCardImage extends StatelessWidget {
  final GameRole role;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool showBorder;
  final bool showGlow;

  const RoleCardImage({
    super.key,
    required this.role,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.showBorder = true,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = RoleAssetMap.getImagePath(role);
    final radius = borderRadius ?? BorderRadius.circular(16);
    final accent = role.accentColor;

    Widget imageWidget;
    if (imagePath != null) {
      imageWidget = Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(accent);
        },
      );
    } else {
      imageWidget = _buildPlaceholder(accent);
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: showBorder
            ? Border.all(
                color: accent.withValues(alpha: showGlow ? 0.8 : 0.4),
                width: showGlow ? 2.0 : 1.2,
              )
            : null,
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.4),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: imageWidget,
      ),
    );
  }

  Widget _buildPlaceholder(Color accent) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.25),
            const Color(0xFF0A0F1E),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              role.icon,
              size: (width != null && width! < 60) ? 22 : 36,
              color: accent,
            ),
            if (width == null || width! >= 80) ...[
              const SizedBox(height: 6),
              Text(
                role.displayName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
