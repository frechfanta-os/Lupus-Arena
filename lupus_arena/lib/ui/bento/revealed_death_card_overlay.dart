import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../models/game_role.dart';
import '../../services/app_translations.dart';
import '../theme/lupus_theme.dart';
import 'role_card_image.dart';

class DeathAnnouncementEvent {
  final String playerId;
  final String playerName;
  final GameRole role;
  final String cause;
  final int timestamp;

  const DeathAnnouncementEvent({
    required this.playerId,
    required this.playerName,
    required this.role,
    required this.cause,
    this.timestamp = 0,
  });

  String get key => '${playerId}_${cause}_$timestamp';

  String getCauseLabel([BuildContext? context]) {
    switch (cause.toUpperCase()) {
      case 'MORSURE_LOUPS':
        return AppTranslations.getText(context, 'death_cause_wolf_bite');
      case 'POISON_SORCIERE':
        return AppTranslations.getText(context, 'death_cause_witch_poison');
      case 'VOTE_VILLAGE':
        return AppTranslations.getText(context, 'death_cause_village_vote');
      case 'CHASSEUR':
      case 'TIR_CHASSEUR':
        return AppTranslations.getText(context, 'death_cause_hunter_shot');
      case 'AMOUREUX':
      case 'CHAGRIN':
        return AppTranslations.getText(context, 'death_cause_heartbreak');
      case 'PETITE_FILLE_SURPRISE':
      case 'PETITE_FILLE':
        return AppTranslations.getText(context, 'death_cause_little_girl_caught');
      default:
        return AppTranslations.getText(context, 'death_cause_elimination');
    }
  }

  String get causeLabel => getCauseLabel();

  IconData get causeIcon {
    switch (cause.toUpperCase()) {
      case 'MORSURE_LOUPS':
        return Icons.pets_rounded;
      case 'POISON_SORCIERE':
        return Icons.science_rounded;
      case 'VOTE_VILLAGE':
        return Icons.local_fire_department_rounded;
      case 'CHASSEUR':
      case 'TIR_CHASSEUR':
        return Icons.track_changes_rounded;
      case 'AMOUREUX':
      case 'CHAGRIN':
        return Icons.favorite_rounded;
      case 'PETITE_FILLE_SURPRISE':
      case 'PETITE_FILLE':
        return Icons.visibility_off_rounded;
      default:
        return Icons.dangerous_rounded;
    }
  }

  Color get causeColor {
    switch (cause.toUpperCase()) {
      case 'MORSURE_LOUPS':
        return const Color(0xFFEF4444);
      case 'POISON_SORCIERE':
        return const Color(0xFFA855F7);
      case 'VOTE_VILLAGE':
        return const Color(0xFFF97316);
      case 'CHASSEUR':
      case 'TIR_CHASSEUR':
        return const Color(0xFFEAB308);
      case 'AMOUREUX':
      case 'CHAGRIN':
        return const Color(0xFFEC4899);
      case 'PETITE_FILLE_SURPRISE':
      case 'PETITE_FILLE':
        return const Color(0xFFFFC6FF);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  factory DeathAnnouncementEvent.fromMap(Map<dynamic, dynamic> map) {
    return DeathAnnouncementEvent(
      playerId: (map['joueurId'] ?? map['playerId'] ?? '').toString(),
      playerName: (map['nom'] ?? map['playerName'] ?? 'Inconnu').toString(),
      role: GameRole.fromString(map['role']?.toString()),
      cause: (map['cause'] ?? 'MORSURE_LOUPS').toString(),
      timestamp: (map['timestamp'] is int)
          ? map['timestamp'] as int
          : (int.tryParse(map['timestamp']?.toString() ?? '0') ?? 0),
    );
  }
}

class RevealedDeathCardOverlay extends StatefulWidget {
  final List<DeathAnnouncementEvent> queue;
  final VoidCallback? onSequenceCompleted;
  final VoidCallback? onCompleted;
  final dynamic event;

  const RevealedDeathCardOverlay({
    super.key,
    List<DeathAnnouncementEvent>? queue,
    this.onSequenceCompleted,
    this.onCompleted,
    this.event,
  }) : queue = queue ?? const [];

  @override
  State<RevealedDeathCardOverlay> createState() =>
      _RevealedDeathCardOverlayState();
}

class _RevealedDeathCardOverlayState extends State<RevealedDeathCardOverlay>
    with TickerProviderStateMixin {
  final List<DeathAnnouncementEvent> _pendingQueue = [];
  final Set<String> _playedKeys = {};
  DeathAnnouncementEvent? _currentEvent;

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  late AnimationController _exitController;
  late Animation<double> _exitFadeAnimation;
  late Animation<double> _exitScaleAnimation;

  Timer? _freezeTimer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      final ev = widget.event;
      final deathEvent = DeathAnnouncementEvent(
        playerId: ev.joueurId?.toString() ?? '',
        playerName: ev.nomJoueur?.toString() ?? '',
        role: GameRole.fromString(ev.roleOriginal?.toString()),
        cause: ev.causeMort?.toString() ?? 'VOTE_VILLAGE',
      );
      if (deathEvent.playerId.isNotEmpty) {
        _pendingQueue.add(deathEvent);
      }
    } else {
      final seenIds = <String>{};
      for (final ev in widget.queue) {
        if (ev.playerId.isNotEmpty && seenIds.add(ev.playerId)) {
          _pendingQueue.add(ev);
        }
      }
    }

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: math.pi).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutCubic),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _exitFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInQuad),
    );
    _exitScaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInQuad),
    );

    _flipController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {

        _startTwoSecondsFreeze();
      }
    });

    _exitController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {

        _advanceQueue();
      }
    });

    _playNextCard();
  }

  @override
  void didUpdateWidget(RevealedDeathCardOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    for (final ev in widget.queue) {
      final isAlreadyHandled = _playedKeys.contains(ev.key) ||
          _playedKeys.contains(ev.playerId) ||
          _pendingQueue.any((e) => e.playerId == ev.playerId) ||
          (_currentEvent?.playerId == ev.playerId);
      if (!isAlreadyHandled && ev.playerId.isNotEmpty) {
        _pendingQueue.add(ev);
      }
    }
    if (_currentEvent == null && _pendingQueue.isNotEmpty) {
      _playNextCard();
    }
  }

  void _playNextCard() {
    if (_pendingQueue.isEmpty) {
      if (mounted) {
        setState(() {
          _currentEvent = null;
        });
        widget.onSequenceCompleted?.call();
        widget.onCompleted?.call();
      }
      return;
    }

    final nextEvent = _pendingQueue.removeAt(0);
    _playedKeys.add(nextEvent.key);
    _playedKeys.add(nextEvent.playerId);

    setState(() {
      _currentEvent = nextEvent;
    });

    _exitController.reset();
    _flipController.forward(from: 0.0);
  }

  void _startTwoSecondsFreeze() {
    _freezeTimer?.cancel();

    _freezeTimer = Timer(const Duration(milliseconds: 2500), () {
      if (_isDisposed || !mounted) return;
      _exitController.forward(from: 0.0);
    });
  }

  void _advanceQueue() {
    if (_isDisposed || !mounted) return;
    _playNextCard();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _freezeTimer?.cancel();
    _flipController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentEvent == null) {
      return const SizedBox.shrink();
    }

    final event = _currentEvent!;
    const double cardWidth = 70.0;
    const double cardHeight = 84.0;
    const double maxContainerWidth = 92.0;
    const double maxContainerHeight = 138.0;

    return Center(
      child: Container(
        key: const Key('death_card_container'),
        constraints: const BoxConstraints(
          maxWidth: maxContainerWidth,
          maxHeight: maxContainerHeight,
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([_flipAnimation, _exitController]),
          builder: (context, _) {
            final angle = _flipAnimation.value;
            final isFront = angle >= (math.pi / 2);
            final fade = _exitFadeAnimation.value;
            final scale = _exitScaleAnimation.value;

            return Opacity(
              opacity: fade,
              child: Transform.scale(
                scale: scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.002)
                        ..rotateY(angle),
                      child: isFront
                          ? Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(math.pi),
                              child: _buildCardFront(event, cardWidth, cardHeight),
                            )
                          : _buildCardBack(cardWidth, cardHeight),
                    ),

                    const SizedBox(height: 4),

                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isFront ? 1.0 : 0.0,
                      child: _buildVictimInfo(event, maxContainerWidth),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardBack(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: LupusColors.arcanePurple.withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: LupusColors.arcanePurple.withValues(alpha: 0.35),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.asset(
          RoleAssetMap.cardBackPath,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {

            return Image.asset(
              RoleAssetMap.cardBackFallback,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, st) {

                return Container(
                  width: width,
                  height: height,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E1035), Color(0xFF0D061A)],
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/lupus_seal.png',
                      width: 42,
                      height: 42,
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.shield_moon_rounded,
                        color: LupusColors.arcanePurple,
                        size: 36,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardFront(
    DeathAnnouncementEvent event,
    double width,
    double height,
  ) {
    final role = event.role;
    final accentColor = role.isEvil ? LupusColors.arcaneCrimson : role.accentColor;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.85),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.45),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          fit: StackFit.expand,
          children: [

            RoleCardImage(
              role: role,
              width: width,
              height: height,
              showBorder: false,
              fit: BoxFit.cover,
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVictimInfo(DeathAnnouncementEvent event, double maxWidth) {
    return Container(
      width: maxWidth,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          Text(
            event.playerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.3,
              shadows: [
                Shadow(color: Colors.black, blurRadius: 6),
              ],
            ),
          ),

          const SizedBox(height: 1),

          Text(
            event.role.getDisplayName(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: event.role.isEvil
                  ? const Color(0xFFFCA5A5)
                  : LupusColors.arcaneGold,
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 4),
              ],
            ),
          ),

          const SizedBox(height: 2),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: event.causeColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: event.causeColor.withValues(alpha: 0.5),
                width: 0.7,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  event.causeIcon,
                  size: 9,
                  color: event.causeColor,
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    event.getCauseLabel(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: event.causeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
