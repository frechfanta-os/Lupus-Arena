import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/player_model.dart';
import '../../services/app_translations.dart';
import '../../services/fog_of_war_service.dart';
import '../theme/lupus_avatars.dart';
import '../theme/lupus_theme.dart';
import 'animated_status_badge.dart';
import 'bento_card.dart';
import 'game_action_visual_effects.dart';
import 'ghost_death_badge.dart';

class BentoPlayerTile extends StatelessWidget {
  final PlayerModel player;
  final bool isMe;
  final bool isSpeaking;
  final bool isSelected;
  final int votesCount;
  final bool showRole;
  final bool isWolfPeer;
  final GameRole? seerDiscoveredRole;
  final bool isDevMode;
  final GameRole myRole;
  final bool myIsLover;
  final bool myIsCharmed;
  final bool isSniffed;
  final bool hasWolfSmell;
  final bool isProtected;
  final bool isWitchVictim;
  final bool isWitchHealed;
  final bool isWitchPoisoned;
  final bool isCrowTarget;
  final bool isWildChildModel;
  final bool isContaminatedWolf;
  final bool isBearTamerGrowling;
  final bool isHunterImpact;
  final bool isPyroIgnited;
  final VoidCallback? onTap;

  const BentoPlayerTile({
    super.key,
    required this.player,
    this.isMe = false,
    this.isSpeaking = false,
    this.isSelected = false,
    this.votesCount = 0,
    this.showRole = false,
    this.isWolfPeer = false,
    this.seerDiscoveredRole,
    this.isDevMode = false,
    this.myRole = GameRole.simpleVillager,
    this.myIsLover = false,
    this.myIsCharmed = false,
    this.isSniffed = false,
    this.hasWolfSmell = false,
    this.isProtected = false,
    this.isWitchVictim = false,
    this.isWitchHealed = false,
    this.isWitchPoisoned = false,
    this.isCrowTarget = false,
    this.isWildChildModel = false,
    this.isContaminatedWolf = false,
    this.isBearTamerGrowling = false,
    this.isHunterImpact = false,
    this.isPyroIgnited = false,
    this.onTap,
  });

  static List<IconData> get avatarIcons => LupusAvatars.icons;

  @override
  Widget build(BuildContext context) {
    final isDead = !player.isAlive;
    final avatarItem = LupusAvatars.getByIndex(player.avatarIndex);
    final icon = avatarItem.icon;

    final canSeeSeer = FogOfWarService.canSeeSeerInspection(
      observerRole: myRole,
      isDevMode: isDevMode,
    );
    final effectiveSeerRole = canSeeSeer ? seerDiscoveredRole : null;

    final canSeeRole = isMe ||
        isDead ||
        isDevMode ||
        (isWolfPeer && player.isAlive) ||
        (effectiveSeerRole != null && player.isAlive);

    final GameRole roleToDisplay =
        (effectiveSeerRole != null && !isMe && !isDead)
            ? effectiveSeerRole
            : (isDead ? player.roleInitial : player.role);

    String roleLabel;
    if (isMe) {
      roleLabel = context.tr('my_role_label', {'role': player.role.getDisplayName(context)});
    } else if (isDead) {
      roleLabel = player.roleInitial.getDisplayName(context);
    } else if (effectiveSeerRole != null) {
      roleLabel = '🔮 ${effectiveSeerRole.getDisplayName(context)}';
    } else if (isWolfPeer) {
      final wolfName = (player.role == GameRole.whiteWerewolf)
          ? context.tr('role_white_werewolf')
          : (player.role.isEvil && player.role != GameRole.simpleVillager)
              ? player.role.getDisplayName(context)
              : context.tr('role_simple_werewolf');
      roleLabel = '🐺 $wolfName';
    } else if (isDevMode) {
      roleLabel = player.estDechu
          ? '${player.role.getDisplayName(context)} (Ex-${player.roleInitial.getDisplayName(context)})'
          : player.role.getDisplayName(context);
    } else {
      roleLabel = context.tr('alive');
    }

    Color borderColor;
    if (isSpeaking && player.isAlive) {
      borderColor = const Color(0xFF00FF88);
    } else if (isSelected) {
      borderColor = LupusColors.bloodRed;
    } else if (isDead) {
      borderColor = Colors.black45;
    } else if (isWolfPeer && player.isAlive && !isMe) {
      borderColor = LupusColors.bloodRed.withValues(alpha: 0.7);
    } else {
      borderColor = LupusColors.border;
    }

    return RepaintBoundary(
      child: BentoCard(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      onTap: onTap != null
          ? () {
              HapticFeedback.selectionClick();
              onTap!();
            }
          : null,
      borderColor: borderColor,
      glowing: isSpeaking && player.isAlive,
      backgroundColor: isDead
          ? const Color(0xFF0F1117)
          : (isSelected
              ? LupusColors.bloodRed.withValues(alpha: 0.15)
              : LupusColors.surface),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          GhostDeathBadge(
            playerUid: player.id,
            isAlive: player.isAlive,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [

                  if (FogOfWarService.canSeeCharmedBadge(
                    targetIsCharmed: player.isCharmed,
                    observerRole: myRole,
                    observerIsCharmed: myIsCharmed,
                    isDevMode: isDevMode,
                  ))
                    const CharmedPulsingHalo(size: 44),

                  if (isSpeaking && player.isAlive)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00FF88),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF00FF88).withValues(alpha: 0.8),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),

                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isDead
                          ? const LinearGradient(
                              colors: [Color(0xFF202025), Color(0xFF121214)],
                            )
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: avatarItem.gradientColors,
                            ),
                      border: Border.all(
                        color: isDead
                            ? Colors.white12
                            : avatarItem.borderColor.withValues(alpha: 0.8),
                        width: 1.2,
                      ),
                      boxShadow: isDead
                          ? null
                          : [
                              BoxShadow(
                                color: avatarItem.glowColor,
                                blurRadius: 6,
                              ),
                            ],
                    ),
                    child: Center(
                      child: Icon(
                        isDead ? Icons.sentiment_very_dissatisfied_rounded : icon,
                        color: isDead ? LupusColors.textMuted : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                  if (isHunterImpact)
                    const Positioned.fill(
                      child: HunterImpactEffect(size: 36),
                    ),

                  if (isPyroIgnited)
                    const Positioned.fill(
                      child: PyroFlameBurstEffect(size: 36),
                    ),

                  if (isDead)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(1.5),
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cancel_rounded,
                          color: LupusColors.bloodRed,
                          size: 14,
                        ),
                      ),
                    ),

                  if (!player.isOnline && player.isAlive)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E212D),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.wifi_off_rounded,
                          color: Colors.amber,
                          size: 11,
                        ),
                      ),
                    ),

                  if (isSpeaking && player.isAlive)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF070B1D),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF00FF88),
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.graphic_eq_rounded,
                          color: Color(0xFF00FF88),
                          size: 11,
                        ),
                      ),
                    ),

                  if (player.isMuted && player.isAlive)
                    Positioned(
                      bottom: -2,
                      left: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF200A10),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFF3333),
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.mic_off_rounded,
                          color: Color(0xFFFF3333),
                          size: 11,
                        ),
                      ),
                    ),

                  if (isSniffed && !isMe)
                    Positioned(
                      top: -4,
                      left: -4,
                      child: AnimatedStatusBadge(
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: hasWolfSmell ? const Color(0xFFFF1E46) : const Color(0xFFFB8500),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 0.8),
                          ),
                          child: Text(
                            hasWolfSmell ? '🐺' : '🦊',
                            style: const TextStyle(fontSize: 8.5),
                          ),
                        ),
                      ),
                    ),

                  if (isProtected && !isMe)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: const AnimatedStatusBadge(
                        child: Text('🛡️', style: TextStyle(fontSize: 9.5)),
                      ),
                    ),

                  if (isWitchHealed && !isMe)
                    Positioned(
                      bottom: -4,
                      left: -4,
                      child: const AnimatedStatusBadge(
                        child: Text('🧪', style: TextStyle(fontSize: 9.5)),
                      ),
                    ),

                  if (isWitchPoisoned && !isMe)
                    Positioned(
                      bottom: -4,
                      left: -4,
                      child: const AnimatedStatusBadge(
                        child: Text('☠️', style: TextStyle(fontSize: 9.5)),
                      ),
                    ),

                  if (isWitchVictim && !isMe)
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: const AnimatedStatusBadge(
                        child: Text('🩸', style: TextStyle(fontSize: 9.5)),
                      ),
                    ),

                  if (isCrowTarget && !isMe)
                    Positioned(
                      top: -4,
                      left: -4,
                      child: const AnimatedStatusBadge(
                        child: Text('🦅', style: TextStyle(fontSize: 9.5)),
                      ),
                    ),

                  if (isWildChildModel && !isMe)
                    Positioned(
                      bottom: -4,
                      left: -4,
                      child: const AnimatedStatusBadge(
                        child: Text('🌱', style: TextStyle(fontSize: 9.5)),
                      ),
                    ),

                  if (isContaminatedWolf && !isMe)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: const AnimatedStatusBadge(
                        child: Text('🗡️', style: TextStyle(fontSize: 9.5)),
                      ),
                    ),

                  if (isBearTamerGrowling && !isMe)
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: const AnimatedStatusBadge(
                        child: Text('🐻', style: TextStyle(fontSize: 9.5)),
                      ),
                    ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (player.isHost) ...[
                  const AnimatedStatusBadge(
                    child: Icon(Icons.star_rounded,
                        size: 12, color: LupusColors.sunAmber),
                  ),
                  const SizedBox(width: 2),
                ],
                if (player.isCaptain) ...[
                  const AnimatedStatusBadge(
                    child: Icon(Icons.military_tech_rounded,
                        size: 12, color: Color(0xFFFFD700)),
                  ),
                  const SizedBox(width: 2),
                ],
                if (isWolfPeer && !isMe && player.isAlive) ...[
                  const AnimatedStatusBadge(
                    child: Text('🐺', style: TextStyle(fontSize: 10)),
                  ),
                  const SizedBox(width: 2),
                ],
                if (effectiveSeerRole != null && !isMe && player.isAlive) ...[
                  const AnimatedStatusBadge(
                    child: Text('🔮', style: TextStyle(fontSize: 10)),
                  ),
                  const SizedBox(width: 2),
                ],
                if (FogOfWarService.canSeeLoverBadge(
                  targetIsLover: player.isLover,
                  observerRole: myRole,
                  observerIsLover: myIsLover,
                  isDevMode: isDevMode,
                )) ...[
                  const AnimatedStatusBadge(
                    child: Icon(Icons.favorite_rounded,
                        size: 11, color: LupusColors.bloodRed),
                  ),
                  const SizedBox(width: 2),
                ],
                if (FogOfWarService.canSeeCharmedBadge(
                  targetIsCharmed: player.isCharmed,
                  observerRole: myRole,
                  observerIsCharmed: myIsCharmed,
                  isDevMode: isDevMode,
                )) ...[
                  const AnimatedStatusBadge(
                    child: Icon(Icons.music_note_rounded,
                        size: 11, color: Color(0xFF06D6A0)),
                  ),
                  const SizedBox(width: 2),
                ],
                if (player.isDoused && (isMe || myRole == GameRole.pyromaniac || isDevMode || isDead)) ...[
                  const AnimatedStatusBadge(
                    child: Icon(Icons.local_fire_department_rounded,
                        size: 11, color: Color(0xFFFF4800)),
                  ),
                  const SizedBox(width: 2),
                ],
                if (player.isMuted) ...[
                  const AnimatedStatusBadge(
                    child: Icon(Icons.mic_off_rounded,
                        size: 11, color: Color(0xFFFF3333)),
                  ),
                  const SizedBox(width: 2),
                ],
                Flexible(
                  child: Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                      color: isDead
                          ? LupusColors.textMuted
                          : (isWolfPeer && !isMe
                              ? const Color(0xFFFF8B8B)
                              : (isMe
                                  ? LupusColors.moonIndigo
                                  : LupusColors.textPrimary)),
                      decoration: isDead ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (canSeeRole) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: (isWolfPeer && !isMe && !isDevMode && effectiveSeerRole == null)
                    ? LupusColors.bloodRed.withValues(alpha: 0.25)
                    : roleToDisplay.accentColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: (isWolfPeer && !isMe && !isDevMode && effectiveSeerRole == null)
                      ? LupusColors.bloodRed.withValues(alpha: 0.6)
                      : roleToDisplay.accentColor.withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
              child: Text(
                roleLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: (isWolfPeer && !isMe && !isDevMode && effectiveSeerRole == null)
                      ? const Color(0xFFFF8B8B)
                      : roleToDisplay.accentColor,
                ),
              ),
            ),
          ] else ...[
            Text(
              isDead ? context.tr('eliminated') : context.tr('alive'),
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: isDead ? LupusColors.textMuted : LupusColors.poisonGreen,
                letterSpacing: 0.6,
              ),
            ),
          ],

          if (votesCount > 0)
            AnimatedStatusBadge(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: LupusColors.bloodRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$votesCount ${votesCount > 1 ? context.tr("votes_suffix") : context.tr("vote_suffix")}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }
}
