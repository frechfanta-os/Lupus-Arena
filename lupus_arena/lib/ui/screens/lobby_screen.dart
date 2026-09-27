import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../GameNotifier.dart';
import '../../models/game_phase.dart';
import '../../models/game_room.dart';
import '../admin/admin_control_sheet.dart';
import '../admin/admin_secret_dialog.dart';
import '../bento/bento_card.dart';
import '../bento/bento_voice_controls.dart';
import '../bento/medieval_fantasy_button.dart';
import '../bento/role_selector_bento.dart';
import '../bento/lupus_permission_dialog.dart';
import '../theme/lupus_assets.dart';
import '../theme/lupus_avatars.dart';
import '../theme/lupus_theme.dart';
import '../../services/audio_manager.dart';
import '../../services/locale_provider.dart';
import '../../services/lupus_permission_service.dart';
import '../../services/app_translations.dart';
import '../bento/language_dialog.dart';
import '../bento/music_mute_button.dart';
import 'arena_game_screen.dart';
import '../../services/room_share_service.dart';
import '../bento/room_report_dialog.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  final LocaleProvider? localeProvider;

  const LobbyScreen({super.key, this.localeProvider});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> with WidgetsBindingObserver {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _isNavigatingToArena = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final locale = widget.localeProvider ?? LocaleProvider.instance;
    locale.addListener(_onLocaleChanged);
    final state = ref.read(gameNotifierProvider);
    _nameController.text = state.currentUserName;

    SharedPreferences.getInstance().then((prefs) {
      final savedName = prefs.getString('player_nickname');
      if (savedName != null && savedName.trim().isNotEmpty && mounted) {
        setState(() {
          _nameController.text = savedName.trim();
        });
        ref.read(gameNotifierProvider.notifier).updateProfile(name: savedName.trim());
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await LanguageDialog.showFirstLaunchIfNeeded(
        context,
        widget.localeProvider ?? LocaleProvider.instance,
      );
      if (!mounted) return;
      LupusPermissionDialog.showIfNeeded(context);
    });

    LupusPermissionService().startBackgroundPermissionMonitor();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (ref.read(gameNotifierProvider).room == null) {
          LupusAudioManager.instance.playLobbyMusic();
        } else {
          LupusAudioManager.instance.playRoomMusic();
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      LobbyAudioManager.instance.pauseLobbyMusic();
      LobbyAudioManager.instance.pauseRoomMusic();
    } else if (state == AppLifecycleState.resumed) {
      if (ref.read(gameNotifierProvider).room == null) {
        LobbyAudioManager.instance.resumeLobbyMusic();
      } else {
        LobbyAudioManager.instance.resumeRoomMusic();
      }
    }
  }

  void _onLocaleChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final locale = widget.localeProvider ?? LocaleProvider.instance;
    locale.removeListener(_onLocaleChanged);
    LobbyAudioManager.instance.stopLobbyMusic();

    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LupusGameState>(gameNotifierProvider, (previous, next) {
      if (next.room == null) {
        LobbyAudioManager.instance.playLobbyMusic();
      } else {
        LobbyAudioManager.instance.playRoomMusic();
      }
    });

    final gameState = ref.watch(gameNotifierProvider);
    final room = gameState.room;

    if (room != null && room.phase != GamePhase.lobby) {
      if (!_isNavigatingToArena) {
        _isNavigatingToArena = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final nav = Navigator.of(context);

          await LobbyAudioManager.instance.fadeOutAndStopLobbyMusic();

          if (mounted) {
            nav.pushReplacement(
              MaterialPageRoute(builder: (_) => const ArenaGameScreen()),
            );
          }
        });
      }
    } else {
      _isNavigatingToArena = false;
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          LobbyAudioManager.instance.stopLobbyMusic();
          LobbyAudioManager.instance.stopRoomMusic();
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF04060E),
          resizeToAvoidBottomInset: false,
          body: SizedBox.expand(
            child: room == null
                ? _buildMainMenu(context, gameState)
                : _buildWaitingLobby(context, gameState, room),
          ),
        ),
      ),
    );
  }

  Widget _buildMainMenu(BuildContext context, LupusGameState gameState) {
    final media = MediaQuery.of(context);
    final locale = widget.localeProvider ?? LocaleProvider.instance;

    return ListenableBuilder(
      listenable: locale,
      builder: (context, _) {
        return SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: LupusAssets.buildLobbyBackground(),
              ),

              Positioned(
                top: media.padding.top > 0 ? media.padding.top : 24,
                left: 0,
                right: 0,
                height: 140,
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onDoubleTap: () => _openAdminTrigger(context),
                    onLongPress: () => _openAdminTrigger(context),
                    child: const SizedBox(width: 170, height: 140),
                  ),
                ),
              ),

              AnimatedPositioned(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOutCubic,
                bottom: media.viewInsets.bottom > 0
                    ? media.viewInsets.bottom + 12.0
                    : math.max(
                        (media.padding.bottom > 0 ? media.padding.bottom : 16.0) + 16.0,
                        media.size.height * 0.275,
                      ),
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: Center(
                    child: _buildActionButtonsColumn(context, gameState),
                  ),
                ),
              ),

              if (gameState.errorMessage != null)
                Positioned(
                  left: 18,
                  right: 18,
                  top: (media.padding.top > 0 ? media.padding.top : 24) + 65,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: LupusColors.bloodRed.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white30),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black87,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            gameState.errorMessage!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                          onPressed: () => ref.read(gameNotifierProvider.notifier).clearError(),
                        ),
                      ],
                    ),
                  ),
                ),

              Positioned(
                top: (media.padding.top > 0 ? media.padding.top : 24) + 6,
                left: 18,
                right: 18,
                child: _buildTopBar(context, gameState),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNameEditDialog(BuildContext context, String currentName) {
    _nameController.text = currentName;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1424),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: LupusColors.arcaneGold, width: 1.5),
        ),
        title: Text(
          context.tr('player_name'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        content: TextField(
          controller: _nameController,
          autofocus: true,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          cursorColor: LupusColors.arcaneGold,
          decoration: InputDecoration(
            hintText: context.tr('name_hint'),
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: LupusColors.arcaneGold.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: LupusColors.arcaneGold, width: 2),
            ),
          ),
          onSubmitted: (val) {
            final trimmed = val.trim();
            if (trimmed.isNotEmpty) {
              ref.read(gameNotifierProvider.notifier).updateProfile(name: trimmed);
            }
            Navigator.of(ctx).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              context.tr('cancel'),
              style: const TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: LupusColors.arcaneGold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final trimmed = _nameController.text.trim();
              if (trimmed.isNotEmpty) {
                ref.read(gameNotifierProvider.notifier).updateProfile(name: trimmed);
              }
              Navigator.of(ctx).pop();
            },
            child: Text(context.tr('ok_btn'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, LupusGameState gameState) {
    final displayName = gameState.currentUserName.isNotEmpty
        ? gameState.currentUserName
        : context.tr('role_simple_werewolf');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [

        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showNameEditDialog(context, gameState.currentUserName),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
            decoration: BoxDecoration(
              color: const Color(0xCC12182E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: LupusColors.arcaneGold.withValues(alpha: 0.6),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: LupusColors.arcaneGold.withValues(alpha: 0.12),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showAvatarSelector(context),
                  child: ClipOval(
                    child: Image.asset(
                      LupusAssets.wolfSealAsset,
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Image.network(
                        LupusAssets.wolfSealUrl,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => const Icon(
                          Icons.pets_rounded,
                          color: LupusColors.arcaneGold,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 105),
                  child: Text(
                    displayName,
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      color: LupusColors.arcaneGold,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.edit_rounded,
                  color: LupusColors.arcaneGold.withValues(alpha: 0.75),
                  size: 11,
                ),
              ],
            ),
          ),
        ),

        const Spacer(),

        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            if (gameState.isAdmin) ...[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => AdminControlSheet.show(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF422006),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: LupusColors.arcaneGold.withValues(alpha: 0.6),
                      width: 0.8,
                    ),
                    boxShadow: LupusTheme.glowGold(opacity: 0.3),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('👑', style: TextStyle(fontSize: 11)),
                      SizedBox(width: 3),
                      Text(
                        'DEV',
                        style: TextStyle(
                          color: LupusColors.arcaneGold,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],

            const MusicMuteButton(isCompact: true, size: 32),
            const SizedBox(width: 6),

            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => LanguageDialog.show(
                context,
                widget.localeProvider ?? LocaleProvider.instance,
              ),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xC012182E),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: LupusColors.arcaneGold.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.language_rounded,
                  size: 16,
                  color: LupusColors.arcaneGold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtonsColumn(BuildContext context, LupusGameState gameState) {
    return LobbyActionButtons(
      gameState: gameState,
      codeController: _codeController,
      localeProvider: widget.localeProvider ?? LocaleProvider.instance,
      onJoin: _handleJoinOrAdmin,
      onCreate: () async {
        await LobbyAudioManager.instance.fadeOutAndStopLobbyMusic();
        await ref.read(gameNotifierProvider.notifier).createRoom();
      },
    );
  }

  Widget _buildWaitingLobby(BuildContext context, LupusGameState gameState, GameRoom room) {

    if (!LupusAudioManager.instance.isRoomPlaying) {
      LupusAudioManager.instance.playRoomMusic();
    }

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [

          Positioned.fill(
            child: LupusAssets.adaptiveImage(
              assetPath: LupusAssets.villageNightBgAsset,
              networkUrl: LupusAssets.villageNightBgUrl,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF060A18).withValues(alpha: 0.90),
                    const Color(0xFF070B1D).withValues(alpha: 0.55),
                    const Color(0xFF04060E).withValues(alpha: 0.95),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => LanguageDialog.show(
                                  context,
                                  widget.localeProvider ?? LocaleProvider.instance,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10162A).withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: LupusColors.arcaneGold.withValues(alpha: 0.6),
                                      width: 1.2,
                                    ),
                                    boxShadow: LupusTheme.glowGold(opacity: 0.25),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.language_rounded,
                                        color: LupusColors.arcaneGold,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        LocaleProvider.instance.languageCode == 'ar'
                                            ? 'العربية'
                                            : (LocaleProvider.instance.languageCode == 'en'
                                                ? 'English'
                                                : 'Français'),
                                        style: const TextStyle(
                                          color: LupusColors.arcaneGold,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const MusicMuteButton(isCompact: true, size: 32),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    onPressed: () => ref.read(gameNotifierProvider.notifier).leaveRoom(),
                                    icon: const Icon(Icons.logout_rounded, size: 16, color: LupusColors.bloodRed),
                                    label: Text(
                                      context.tr('leave_room'),
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onLongPress: () => _openAdminTrigger(context),
                    onDoubleTap: () => _openAdminTrigger(context),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                      child: Column(
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: LupusTheme.glowPurple(opacity: 0.55),
                            ),
                            child: ClipOval(
                              child: LupusAssets.adaptiveImage(
                                assetPath: LupusAssets.wolfSealAsset,
                                networkUrl: LupusAssets.wolfSealUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'LUPUS ARENA',
                                style: TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.2,
                                  color: Colors.white,
                                ),
                              ),
                              if (gameState.isAdmin) ...[
                                const SizedBox(width: 6),
                                const Text('👑', style: TextStyle(fontSize: 16)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.tr('app_subtitle'),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: LupusColors.arcaneGold.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (gameState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: LupusColors.bloodRed.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: LupusColors.bloodRed.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: LupusColors.bloodRed),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.tr(gameState.errorMessage!),
                            style: const TextStyle(color: LupusColors.bloodRed, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (gameState.isAdmin) ...[
                  GestureDetector(
                    onTap: () => AdminControlSheet.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF422006), Color(0xFF1E1405), Color(0xFF0F0B02)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: LupusColors.arcaneGold, width: 1.5),
                        boxShadow: LupusTheme.glowGold(opacity: 0.35),
                      ),
                      child: Row(
                        children: [
                          const Text('👑', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('dev_mode_active_banner'),
                                  style: const TextStyle(
                                    color: LupusColors.arcaneGold,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  context.tr('dev_mode_tap_to_open'),
                                  style: const TextStyle(color: LupusColors.textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              color: LupusColors.arcaneGold, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],

                BentoCard(
                  borderColor: LupusColors.sunAmber.withValues(alpha: 0.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('enter_room_code').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: LupusColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            room.roomCode,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4.0,
                              color: LupusColors.sunAmber,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton.filledTonal(
                            tooltip: context.tr('copy_code'),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: room.roomCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(context.tr('copy_code'))),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 20),
                          ),
                          const SizedBox(width: 8),
                          Builder(
                            builder: (shareBtnContext) => IconButton.filledTonal(
                              tooltip: context.tr('share_code'),
                              onPressed: () {
                                final box = shareBtnContext.findRenderObject() as RenderBox?;
                                final origin = box != null && box.hasSize
                                    ? (box.localToGlobal(Offset.zero) & box.size)
                                    : null;
                                RoomShareService.shareRoomCode(
                                  context: shareBtnContext,
                                  roomCode: room.roomCode,
                                  sharePositionOrigin: origin,
                                );
                              },
                              icon: const Icon(Icons.share, size: 20),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            tooltip: context.tr('report_and_moderation'),
                            onPressed: () => RoomReportDialog.show(
                              context,
                              room: room,
                              currentUserId: gameState.currentUserId,
                            ),
                            icon: const Icon(Icons.shield_outlined, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                BentoVoiceControls(),

                const SizedBox(height: 14),

                BentoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr('warriors_assembled_count', {
                              'current': room.playerList.length,
                              'total': 12,
                            }),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: LupusColors.textSecondary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: room.playerList.length == 12
                                  ? LupusColors.poisonGreen.withValues(alpha: 0.2)
                                  : LupusColors.bloodRed.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              room.playerList.length == 12
                                  ? context.tr('ready_to_launch_12')
                                  : context.tr('warriors_count', {
                                      'current': room.playerList.length,
                                      'total': 12,
                                    }),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: room.playerList.length == 12
                                    ? LupusColors.poisonGreen
                                    : LupusColors.bloodRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: room.playerList.map((player) {
                          final isMe = player.id == gameState.currentUserId;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? LupusColors.moonIndigo.withValues(alpha: 0.2)
                                  : LupusColors.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isMe ? LupusColors.moonIndigo : LupusColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (player.isHost) ...[
                                  const Icon(Icons.star_rounded,
                                      size: 14, color: LupusColors.sunAmber),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  player.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                                    color: isMe ? LupusColors.moonIndigo : LupusColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                RoleSelectorBento(
                  room: room,
                  isHost: gameState.isHost,
                ),

                const SizedBox(height: 16),

                if (gameState.isHost) ...[
                  Builder(
                    builder: (context) {
                      final totalRoles = room.totalRolesInPool;
                      final totalPlayers = room.playerList.length;
                      final is12Players = totalPlayers == 12;
                      final is12Roles = totalRoles == 12;
                      final canLaunch = is12Players && is12Roles;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (totalPlayers < 12) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: LupusColors.bloodRed.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: LupusColors.bloodRed.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.group_rounded,
                                      color: LupusColors.bloodRed, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      context.tr('waiting_12_warriors', {'current': totalPlayers, 'total': 12}),
                                      style: const TextStyle(
                                        color: LupusColors.bloodRed,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (totalPlayers > 12) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: LupusColors.bloodRed.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: LupusColors.bloodRed.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded,
                                      color: LupusColors.bloodRed, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      context.tr('lobby_exceeds_12', {'current': totalPlayers, 'total': 12}),
                                      style: const TextStyle(
                                        color: LupusColors.bloodRed,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (!is12Roles) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: LupusColors.sunAmber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: LupusColors.sunAmber.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded,
                                      color: LupusColors.sunAmber, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      context.tr('deck_must_be_12_cards', {'current': totalRoles}),
                                      style: const TextStyle(
                                        color: LupusColors.sunAmber,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          SizedBox(
                            height: 52,
                            child: canLaunch
                                ? MedievalFantasyButton.ruby(
                                    borderRadius: 16,
                                    onTap: () => ref.read(gameNotifierProvider.notifier).startGame(),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          context.tr('start_game').toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.8,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black,
                                                blurRadius: 4,
                                                offset: Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : MedievalFantasyButton.stone(
                                    borderRadius: 16,
                                    enabled: false,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.lock_rounded,
                                          color: Color(0xFF94A3B8),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${context.tr('start_game').toUpperCase()} ($totalRoles / $totalPlayers)',
                                          style: const TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: LupusColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: LupusColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: LupusColors.moonIndigo,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          context.tr('waiting_players'),
                          style: const TextStyle(
                            color: LupusColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: LupusColors.textMuted,
                  ),
                  onPressed: () =>
                      ref.read(gameNotifierProvider.notifier).leaveRoom(),
                  icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                  label: Text(context.tr('leave_room')),
                ),
              ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAvatarSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0C0E1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Color(0xFF6B4A8E), width: 1.5),
      ),
      builder: (ctx) {
        final currentAvatar = ref.watch(gameNotifierProvider).currentUserAvatar;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  context.tr('choose_your_avatar'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('choose_your_avatar_desc'),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.55,
                  ),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: List.generate(LupusAvatars.all.length, (index) {
                        final avatarItem = LupusAvatars.all[index];
                        final isSelected = currentAvatar == index;
                        return GestureDetector(
                          onTap: () {
                            ref.read(gameNotifierProvider.notifier).updateProfile(avatarIndex: index);
                            Navigator.of(ctx).pop();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 76,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? avatarItem.borderColor.withValues(alpha: 0.18)
                                  : const Color(0xFF141829),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? avatarItem.borderColor
                                    : Colors.white12,
                                width: isSelected ? 2.0 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: avatarItem.glowColor,
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: avatarItem.gradientColors,
                                    ),
                                    border: Border.all(
                                      color: avatarItem.borderColor.withValues(alpha: 0.7),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      avatarItem.icon,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  avatarItem.getName(context),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                                    fontSize: 9.5,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleJoinOrAdmin() async {
    final inputCode = _codeController.text.trim();
    if (inputCode == '03031994') {
      ref.read(gameNotifierProvider.notifier).unlockAdmin('03031994');
      _codeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('👑', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                context.tr('dev_mode_unlocked').toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          backgroundColor: LupusColors.arcaneGold,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
      AdminControlSheet.show(context);
      return;
    }
    if (inputCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('enter_valid_code')),
          backgroundColor: LupusColors.bloodRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    await LobbyAudioManager.instance.fadeOutAndStopLobbyMusic();
    if (mounted) {
      ref.read(gameNotifierProvider.notifier).joinRoom(inputCode);
    }
  }

  void _openAdminTrigger(BuildContext context) {
    final isAdmin = ref.read(gameNotifierProvider).isAdmin;
    if (isAdmin) {
      AdminControlSheet.show(context);
    } else {
      AdminSecretDialog.show(context);
    }
  }
}

class LobbyActionButtons extends StatefulWidget {
  final LupusGameState gameState;
  final TextEditingController codeController;
  final LocaleProvider? localeProvider;
  final VoidCallback onJoin;
  final VoidCallback onCreate;

  const LobbyActionButtons({
    super.key,
    required this.gameState,
    required this.codeController,
    this.localeProvider,
    required this.onJoin,
    required this.onCreate,
  });

  @override
  State<LobbyActionButtons> createState() => _LobbyActionButtonsState();
}

class _LobbyActionButtonsState extends State<LobbyActionButtons> {
  late final FocusNode _codeFocusNode;
  late final LocaleProvider _localeProvider;

  @override
  void initState() {
    super.initState();
    _codeFocusNode = FocusNode();
    _codeFocusNode.addListener(_onStateChanged);
    widget.codeController.addListener(_onStateChanged);
    _localeProvider = widget.localeProvider ?? LocaleProvider.instance;
    _localeProvider.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _codeFocusNode.removeListener(_onStateChanged);
    widget.codeController.removeListener(_onStateChanged);
    _codeFocusNode.dispose();
    _localeProvider.removeListener(_onStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _localeProvider,
      builder: (context, _) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 460 / 294,
                      child: _LobbyPressableButton(
                        onTap: widget.gameState.isLoading ? null : widget.onCreate,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final fontSize = math.max(10.0, constraints.maxWidth * 0.115);
                            return Stack(
                              alignment: Alignment.center,
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  LupusAssets.btnCreateRoomBlankAsset,
                                  fit: BoxFit.contain,
                                ),
                                Positioned(
                                  left: constraints.maxWidth * 0.10,
                                  right: constraints.maxWidth * 0.10,
                                  top: constraints.maxHeight * 0.38,
                                  bottom: constraints.maxHeight * 0.18,
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        context.tr('create_room').toUpperCase(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: const Color(0xFFF3E8FF),
                                          fontWeight: FontWeight.w900,
                                          fontSize: fontSize,
                                          letterSpacing: 1.2,
                                          fontFamily: 'serif',
                                          shadows: const [
                                            Shadow(color: Color(0xFFC084FC), blurRadius: 8),
                                            Shadow(color: Color(0xFF9333EA), blurRadius: 16),
                                            Shadow(color: Colors.black, blurRadius: 3, offset: Offset(0, 1.2)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (widget.gameState.isLoading)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black45,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Color(0xFFE9D5FF),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 460 / 294,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (!_codeFocusNode.hasFocus) {
                            _codeFocusNode.requestFocus();
                          }
                        },
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final fontSize = math.max(10.0, constraints.maxWidth * 0.115);
                            final hintText = context.tr('enter_room_code').toUpperCase();
                            return Stack(
                              alignment: Alignment.center,
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  LupusAssets.btnCodeRoomBlankAsset,
                                  fit: BoxFit.contain,
                                ),
                                Positioned(
                                  left: constraints.maxWidth * 0.10,
                                  right: constraints.maxWidth * 0.10,
                                  top: constraints.maxHeight * 0.38,
                                  bottom: constraints.maxHeight * 0.18,
                                  child: Center(
                                    child: TextField(
                                      controller: widget.codeController,
                                      focusNode: _codeFocusNode,
                                      textAlign: TextAlign.center,
                                      textCapitalization: TextCapitalization.characters,
                                      textInputAction: TextInputAction.go,
                                      maxLength: 8,
                                      cursorColor: const Color(0xFFE9D5FF),
                                      cursorWidth: 2.0,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                                        LengthLimitingTextInputFormatter(8),
                                        _UpperCaseTextFormatter(),
                                      ],
                                      style: TextStyle(
                                        color: const Color(0xFFF3E8FF),
                                        fontWeight: FontWeight.w900,
                                        fontSize: fontSize,
                                        letterSpacing: 1.2,
                                        fontFamily: 'serif',
                                        shadows: const [
                                          Shadow(color: Color(0xFFC084FC), blurRadius: 8),
                                          Shadow(color: Color(0xFF9333EA), blurRadius: 16),
                                          Shadow(color: Colors.black, blurRadius: 3, offset: Offset(0, 1.2)),
                                        ],
                                      ),
                                      decoration: InputDecoration(
                                        hintText: widget.codeController.text.isEmpty ? hintText : null,
                                        hintStyle: TextStyle(
                                          color: const Color(0xFFE9D5FF).withValues(alpha: 0.55),
                                          fontWeight: FontWeight.w900,
                                          fontSize: fontSize,
                                          letterSpacing: 1.2,
                                          fontFamily: 'serif',
                                        ),
                                        border: InputBorder.none,
                                        counterText: '',
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onSubmitted: (_) => widget.onJoin(),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 460 / 294,
                      child: _LobbyPressableButton(
                        onTap: widget.gameState.isLoading ? null : widget.onJoin,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final fontSize = math.max(10.0, constraints.maxWidth * 0.115);
                            return Stack(
                              alignment: Alignment.center,
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  LupusAssets.btnJoinRoomBlankAsset,
                                  fit: BoxFit.contain,
                                ),
                                Positioned(
                                  left: constraints.maxWidth * 0.10,
                                  right: constraints.maxWidth * 0.10,
                                  top: constraints.maxHeight * 0.38,
                                  bottom: constraints.maxHeight * 0.18,
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        context.tr('join').toUpperCase(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: const Color(0xFFF3E8FF),
                                          fontWeight: FontWeight.w900,
                                          fontSize: fontSize,
                                          letterSpacing: 1.2,
                                          fontFamily: 'serif',
                                          shadows: const [
                                            Shadow(color: Color(0xFFC084FC), blurRadius: 8),
                                            Shadow(color: Color(0xFF9333EA), blurRadius: 16),
                                            Shadow(color: Colors.black, blurRadius: 3, offset: Offset(0, 1.2)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LobbyPressableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _LobbyPressableButton({
    required this.child,
    this.onTap,
  });

  @override
  State<_LobbyPressableButton> createState() => _LobbyPressableButtonState();
}

class _LobbyPressableButtonState extends State<_LobbyPressableButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _isPressed = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _isPressed = false),
      onTap: () {
        if (widget.onTap != null) {
          HapticFeedback.lightImpact();
          widget.onTap!();
        }
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
