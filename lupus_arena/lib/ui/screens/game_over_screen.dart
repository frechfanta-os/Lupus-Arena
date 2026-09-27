import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../AgoraVoiceService.dart';
import '../../GameNotifier.dart';
import '../../models/game_room.dart';
import '../../models/player_model.dart';
import '../../services/app_translations.dart';
import '../bento/bento_card.dart';
import '../bento/role_card_image.dart';
import '../theme/lupus_theme.dart';

class VictoryThemeConfig {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final List<BoxShadow> glowShadows;

  const VictoryThemeConfig({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.glowShadows,
  });
}

class GameOverScreen extends ConsumerStatefulWidget {
  final GameRoom room;
  final LupusGameState gameState;

  const GameOverScreen({
    super.key,
    required this.room,
    required this.gameState,
  });

  @override
  ConsumerState<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends ConsumerState<GameOverScreen>
    with SingleTickerProviderStateMixin {
  final AgoraVoiceService _voiceService = AgoraVoiceService();
  Timer? _debriefingTimer;
  int _secondsRemaining = 60;
  late AnimationController _bannerAnimController;
  late Animation<double> _bannerScaleAnimation;

  @override
  void initState() {
    super.initState();

    _bannerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _bannerScaleAnimation = CurvedAnimation(
      parent: _bannerAnimController,
      curve: Curves.easeOutBack,
    );

    _bannerAnimController.forward();

    _secondsRemaining = widget.room.timerSeconds > 0 && widget.room.timerSeconds <= 60
        ? widget.room.timerSeconds
        : 60;

    _startDebriefingTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _joinGlobalVoiceChannel();
    });
  }

  void _startDebriefingTimer() {
    _debriefingTimer?.cancel();
    _debriefingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        _onTimeExpired();
      }
    });
  }

  void _onTimeExpired() {

    ref.read(gameNotifierProvider.notifier).leaveRoom();
  }

  Future<void> _joinGlobalVoiceChannel() async {
    final roomCode = widget.room.roomCode;
    final uid = widget.gameState.agoraUid;

    final globalChannel = 'lupus_$roomCode';

    try {
      await _voiceService.joinChannel(
        channelId: globalChannel,
        uid: uid > 0 ? uid : null,
        initialMute: false,
      );

      _voiceService.muteSpeaker(false);
    } catch (e) {
      debugPrint('[GameOverVoice] Erreur connexion canal global: $e');
    }
  }

  @override
  void dispose() {
    _debriefingTimer?.cancel();
    _bannerAnimController.dispose();
    super.dispose();
  }

  VictoryThemeConfig _resolveVictoryConfig(BuildContext context, String? winner) {
    final w = winner?.toLowerCase().trim() ?? '';

    if (w == 'werewolves' || w == 'wolves') {
      return VictoryThemeConfig(
        title: context.tr('victory_werewolves_alt'),
        subtitle: context.tr('victory_werewolves_alt_desc'),
        icon: Icons.pets_rounded,
        primaryColor: const Color(0xFFDC2626),
        secondaryColor: const Color(0xFF7F1D1D),
        glowShadows: [
          const BoxShadow(
            color: Color(0x99DC2626),
            blurRadius: 28,
            spreadRadius: 2,
          ),
          const BoxShadow(
            color: Color(0x667F1D1D),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      );
    } else if (w == 'lovers') {
      return VictoryThemeConfig(
        title: context.tr('victory_lovers'),
        subtitle: context.tr('victory_lovers_alt_desc'),
        icon: Icons.favorite_rounded,
        primaryColor: const Color(0xFFF43F5E),
        secondaryColor: const Color(0xFF881337),
        glowShadows: [
          const BoxShadow(
            color: Color(0x99F43F5E),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      );
    } else if (w == 'piedpiper' || w == 'piper') {
      return VictoryThemeConfig(
        title: context.tr('victory_piper_alt'),
        subtitle: context.tr('victory_piper_alt_desc'),
        icon: Icons.music_note_rounded,
        primaryColor: const Color(0xFFA855F7),
        secondaryColor: const Color(0xFF581C87),
        glowShadows: [
          const BoxShadow(
            color: Color(0x99A855F7),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      );
    } else if (w == 'whitewerewolf') {
      return VictoryThemeConfig(
        title: context.tr('victory_white_wolf'),
        subtitle: context.tr('victory_white_wolf_desc'),
        icon: Icons.nightlight_round,
        primaryColor: const Color(0xFFE2E8F0),
        secondaryColor: const Color(0xFF64748B),
        glowShadows: [
          const BoxShadow(
            color: Color(0xCCFFFFFF),
            blurRadius: 26,
            spreadRadius: 2,
          ),
          const BoxShadow(
            color: Color(0x6694A3B8),
            blurRadius: 36,
            spreadRadius: 3,
          ),
        ],
      );
    } else if (w == 'angel') {
      return VictoryThemeConfig(
        title: context.tr('victory_angel_alt'),
        subtitle: context.tr('victory_angel_alt_desc'),
        icon: Icons.auto_awesome_rounded,
        primaryColor: const Color(0xFFF59E0B),
        secondaryColor: const Color(0xFFB45309),
        glowShadows: [
          const BoxShadow(
            color: Color(0xAAF59E0B),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      );
    } else if (w == 'pyromaniac' || w == 'pyro') {
      return VictoryThemeConfig(
        title: context.tr('victory_pyro'),
        subtitle: context.tr('victory_pyro_desc'),
        icon: Icons.local_fire_department_rounded,
        primaryColor: const Color(0xFFF97316),
        secondaryColor: const Color(0xFF9A3412),
        glowShadows: [
          const BoxShadow(
            color: Color(0xAAF97316),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      );
    } else if (w == 'abominablesectarian' || w == 'sectleader') {
      return VictoryThemeConfig(
        title: context.tr('victory_sect'),
        subtitle: context.tr('victory_sect_desc'),
        icon: Icons.all_inclusive_rounded,
        primaryColor: const Color(0xFF10B981),
        secondaryColor: const Color(0xFF064E3B),
        glowShadows: [
          const BoxShadow(
            color: Color(0xAA10B981),
            blurRadius: 26,
            spreadRadius: 2,
          ),
        ],
      );
    } else if (w == 'draw') {
      return VictoryThemeConfig(
        title: context.tr('victory_draw'),
        subtitle: context.tr('victory_draw_desc'),
        icon: Icons.balance_rounded,
        primaryColor: const Color(0xFF94A3B8),
        secondaryColor: const Color(0xFF334155),
        glowShadows: [
          const BoxShadow(
            color: Color(0x6694A3B8),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      );
    } else {

      return VictoryThemeConfig(
        title: context.tr('victory_village_alt'),
        subtitle: context.tr('victory_village_alt_desc'),
        icon: Icons.shield_rounded,
        primaryColor: const Color(0xFF06B6D4),
        secondaryColor: const Color(0xFF0E7490),
        glowShadows: [
          const BoxShadow(
            color: Color(0xAA06B6D4),
            blurRadius: 28,
            spreadRadius: 2,
          ),
          const BoxShadow(
            color: Color(0x55F59E0B),
            blurRadius: 36,
            spreadRadius: 3,
          ),
        ],
      );
    }
  }

  bool _isPlayerInWinningCamp(PlayerModel player, String? winner) {
    final w = winner?.toLowerCase().trim() ?? '';
    final role = player.trueOriginalRole;

    if (w == 'werewolves' || w == 'wolves') {
      return role.isEvil;
    } else if (w == 'lovers') {
      return player.isLover;
    } else if (w == 'piedpiper' || w == 'piper') {
      return role == GameRole.piedPiper;
    } else if (w == 'whitewerewolf') {
      return role == GameRole.whiteWerewolf;
    } else if (w == 'angel') {
      return role == GameRole.angel;
    } else if (w == 'pyromaniac' || w == 'pyro') {
      return role == GameRole.pyromaniac;
    } else if (w == 'abominablesectarian' || w == 'sectleader') {
      return role == GameRole.sectLeader;
    } else if (w == 'village' || w == 'villagers') {
      return !role.isEvil && role.defaultTeam != Team.solo;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final gameState = widget.gameState;
    final winner = room.winner;
    final victoryConfig = _resolveVictoryConfig(context, winner);
    final allPlayers = room.playerList;
    final totalPlayers = allPlayers.length;
    final readyCount = room.replayReadyCount;
    final isMeReady = room.isPlayerReadyReplay(gameState.currentUserId);
    final isHost = gameState.isHost;

    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    final timeFormatted = '$minutes:$seconds';
    final progress = (_secondsRemaining / 60.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0612),
      body: Stack(
        fit: StackFit.expand,
        children: [

          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.4),
                  radius: 1.2,
                  colors: [
                    Color(0xFF1E1035),
                    Color(0xFF120A24),
                    Color(0xFF0A0612),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [

                _buildTopHeader(timeFormatted, progress),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Column(
                      children: [

                        _buildCinematicVictoryBanner(victoryConfig),

                        const SizedBox(height: 16),

                        _buildHonorBoard(allPlayers, winner, gameState.currentUserId),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                _buildBottomActionDock(
                  context: context,
                  isMeReady: isMeReady,
                  readyCount: readyCount,
                  totalPlayers: totalPlayers,
                  isHost: isHost,
                  room: room,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(String timeFormatted, double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xCC140E24),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_rounded,
                  color: Color(0xFFFBBF24),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  timeFormatted,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Color(0xFFFDE68A),
                  ),
                ),
              ],
            ),
          ),

          Row(
            children: [
              const Icon(
                Icons.record_voice_over_rounded,
                color: Color(0xFF10B981),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                context.tr('debriefing_voice_free'),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: Color(0xFFCBD5E1),
                ),
              ),
            ],
          ),

          ValueListenableBuilder<bool>(
            valueListenable: _voiceService.isMuted,
            builder: (context, isMuted, _) {
              final micColor = isMuted ? const Color(0xFFEF4444) : const Color(0xFF10B981);

              return GestureDetector(
                onTap: () => _voiceService.toggleMute(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xCC140E24),
                    border: Border.all(
                      color: micColor.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: micColor.withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    color: micColor,
                    size: 20,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCinematicVictoryBanner(VictoryThemeConfig config) {
    return ScaleTransition(
      scale: _bannerScaleAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xE6160F2B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: config.primaryColor.withValues(alpha: 0.8),
            width: 1.8,
          ),
          boxShadow: config.glowShadows,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    config.primaryColor.withValues(alpha: 0.3),
                    config.secondaryColor.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: config.primaryColor.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: Icon(
                config.icon,
                color: config.primaryColor,
                size: 36,
              ),
            ),
            const SizedBox(height: 12),

            Text(
              config.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: config.primaryColor,
                shadows: [
                  Shadow(
                    color: config.primaryColor.withValues(alpha: 0.6),
                    blurRadius: 14,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Text(
              config.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFFCBD5E1),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHonorBoard(
    List<PlayerModel> players,
    String? winner,
    String currentUserId,
  ) {
    return BentoCard(
      borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.35),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFFF59E0B),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('honor_board_title'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: Color(0xFFFDE68A),
                ),
              ),
              const Spacer(),
              Text(
                context.tr('players_count', {'count': players.length}),
                style: const TextStyle(
                  fontSize: 11,
                  color: LupusColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: players.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.32,
            ),
            itemBuilder: (context, index) {
              final player = players[index];
              final isWinner = _isPlayerInWinningCamp(player, winner);
              final isMe = player.id == currentUserId;
              final originalRole = player.trueOriginalRole;
              final isDegraded = player.estDechu ||
                  (player.role == GameRole.simpleVillager &&
                      originalRole != GameRole.simpleVillager);

              return _buildPlayerHonorTile(
                player: player,
                originalRole: originalRole,
                isWinner: isWinner,
                isMe: isMe,
                isDegraded: isDegraded,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerHonorTile({
    required PlayerModel player,
    required GameRole originalRole,
    required bool isWinner,
    required bool isMe,
    required bool isDegraded,
  }) {
    final borderColor = isWinner
        ? const Color(0xFFF59E0B)
        : (player.isAlive
            ? const Color(0x38A855F7)
            : const Color(0x22FFFFFF));

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isWinner
            ? const Color(0x26F59E0B)
            : const Color(0x99130D24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isWinner ? 1.5 : 1.0,
        ),
        boxShadow: isWinner
            ? [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 48,
              height: 68,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RoleCardImage(
                    role: originalRole,
                    showBorder: false,
                  ),
                  if (!player.isAlive)
                    Container(
                      color: Colors.black.withValues(alpha: 0.65),
                      child: const Center(
                        child: Text(
                          '💀',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                Row(
                  children: [
                    Flexible(
                      child: Text(
                        player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isMe ? const Color(0xFF38BDF8) : Colors.white,
                        ),
                      ),
                    ),
                    if (isWinner) ...[
                      const SizedBox(width: 4),
                      const Text('🏆', style: TextStyle(fontSize: 11)),
                    ],
                    if (player.isCaptain) ...[
                      const SizedBox(width: 3),
                      const Text('👑', style: TextStyle(fontSize: 10)),
                    ],
                    if (player.isLover) ...[
                      const SizedBox(width: 3),
                      const Text('💖', style: TextStyle(fontSize: 10)),
                    ],
                  ],
                ),
                const SizedBox(height: 3),

                Text(
                  originalRole.getDisplayName(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: originalRole.accentColor,
                  ),
                ),

                if (isDegraded) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0x3364748B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      context.tr('fallen_role_villager'),
                      style: TextStyle(
                        fontSize: 8,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: player.isAlive
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      player.isAlive ? context.tr('survivor') : context.tr('eliminated'),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: player.isAlive
                            ? const Color(0xFF10B981)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionDock({
    required BuildContext context,
    required bool isMeReady,
    required int readyCount,
    required int totalPlayers,
    required bool isHost,
    required GameRoom room,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xF20E081A),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isMeReady
                    ? const Color(0xFF10B981)
                    : const Color(0xFFD97706),
                foregroundColor: Colors.white,
                elevation: 6,
                shadowColor: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isMeReady
                        ? const Color(0xFF34D399)
                        : const Color(0xFFFBBF24),
                    width: 1.5,
                  ),
                ),
              ),
              icon: Icon(
                isMeReady ? Icons.check_circle_rounded : Icons.replay_rounded,
                size: 22,
                color: Colors.white,
              ),
              label: Text(
                isMeReady
                    ? context.tr('rematch_ready_status', {'ready': readyCount, 'total': totalPlayers})
                    : context.tr('replay_status_btn', {'ready': readyCount, 'total': totalPlayers}),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              onPressed: () {
                final uid = widget.gameState.currentUserId;
                final roomCode = room.roomCode;
                if (isMeReady) {
                  ref.read(gameNotifierProvider.notifier).playerCancelReplay(
                        userId: uid,
                        roomId: roomCode,
                      );
                } else {
                  ref.read(gameNotifierProvider.notifier).playerReadyReplay(
                        userId: uid,
                        roomId: roomCode,
                      );
                }
              },
            ),
          ),
          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF94A3B8),
                side: BorderSide(
                  color: const Color(0x38A855F7).withValues(alpha: 0.5),
                  width: 1.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                ref.read(gameNotifierProvider.notifier).leaveRoom();
              },
              child: Text(
                context.tr('quit_arena_menu'),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
