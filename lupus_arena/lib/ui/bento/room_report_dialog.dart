import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../AgoraVoiceService.dart';
import '../../models/game_room.dart';
import '../../models/player_model.dart';
import '../../services/app_translations.dart';
import '../theme/lupus_avatars.dart';
import '../theme/lupus_theme.dart';

class RoomReportDialog extends StatelessWidget {
  final GameRoom room;
  final String currentUserId;

  const RoomReportDialog({
    super.key,
    required this.room,
    required this.currentUserId,
  });

  static Future<void> show(BuildContext context, {
    required GameRoom room,
    required String currentUserId,
  }) {
    return showDialog(
      context: context,
      builder: (context) => RoomReportDialog(
        room: room,
        currentUserId: currentUserId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final otherPlayers = room.playerList.where((p) => p.id != currentUserId).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: LupusColors.surfaceElevated,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: LupusColors.border.withValues(alpha: 0.8),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: LupusColors.bloodRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: LupusColors.bloodRed.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: LupusColors.bloodRed,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('report_and_moderation'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: LupusColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Code Room : ${room.roomCode}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: LupusColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: LupusColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: LupusColors.border, height: 1),
            Flexible(
              child: otherPlayers.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people_outline_rounded,
                            size: 40,
                            color: LupusColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.tr('no_other_players'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: LupusColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: otherPlayers.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final player = otherPlayers[index];
                        return _PlayerModerationCard(
                          player: player,
                          roomCode: room.roomCode,
                          currentUserId: currentUserId,
                        );
                      },
                    ),
            ),
            const Divider(color: LupusColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: LupusColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Le mute local s\'applique immédiatement uniquement pour vous.',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: LupusColors.textSecondary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerModerationCard extends StatelessWidget {
  final PlayerModel player;
  final String roomCode;
  final String currentUserId;

  const _PlayerModerationCard({
    required this.player,
    required this.roomCode,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final voiceService = AgoraVoiceService();
    final avatarItem = LupusAvatars.getByIndex(player.avatarIndex);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: LupusColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LupusColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: avatarItem.gradientColors,
              ),
              border: Border.all(
                color: avatarItem.borderColor,
                width: 1.2,
              ),
            ),
            child: Center(
              child: Icon(
                avatarItem.icon,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (player.isHost) ...[
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: LupusColors.sunAmber,
                      ),
                      const SizedBox(width: 3),
                    ],
                    Flexible(
                      child: Text(
                        player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: LupusColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                ValueListenableBuilder<Set<int>>(
                  valueListenable: voiceService.locallyMutedUids,
                  builder: (context, mutedUids, _) {
                    final isLocallyMuted = mutedUids.contains(player.agoraUid);
                    return Text(
                      isLocallyMuted
                          ? 'Audio coupé localement'
                          : 'Audio actif',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isLocallyMuted
                            ? LupusColors.bloodRed
                            : LupusColors.poisonGreen,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          ValueListenableBuilder<Set<int>>(
            valueListenable: voiceService.locallyMutedUids,
            builder: (context, mutedUids, _) {
              final isLocallyMuted = mutedUids.contains(player.agoraUid);
              return IconButton(
                tooltip: isLocallyMuted
                    ? context.tr('local_unmute')
                    : context.tr('local_mute'),
                icon: Icon(
                  isLocallyMuted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  color: isLocallyMuted
                      ? LupusColors.bloodRed
                      : LupusColors.textSecondary,
                  size: 20,
                ),
                onPressed: () {
                  voiceService.toggleMuteRemoteUser(player.agoraUid);
                  final nextMuted = !isLocallyMuted;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 2),
                      backgroundColor: LupusColors.surfaceLight,
                      content: Text(
                        nextMuted
                            ? '${player.name} est rendu muet pour vous.'
                            : 'Audio rétabli pour ${player.name}.',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            tooltip: context.tr('report_player'),
            icon: const Icon(
              Icons.flag_outlined,
              color: LupusColors.arcaneGold,
              size: 20,
            ),
            onPressed: () => _openReportPlayerSheet(context),
          ),
        ],
      ),
    );
  }

  void _openReportPlayerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReportPlayerModal(
        player: player,
        roomCode: roomCode,
        currentUserId: currentUserId,
      ),
    );
  }
}

class _ReportPlayerModal extends StatefulWidget {
  final PlayerModel player;
  final String roomCode;
  final String currentUserId;

  const _ReportPlayerModal({
    required this.player,
    required this.roomCode,
    required this.currentUserId,
  });

  @override
  State<_ReportPlayerModal> createState() => _ReportPlayerModalState();
}

class _ReportPlayerModalState extends State<_ReportPlayerModal> {
  String? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) return;
    setState(() => _isSending = true);

    try {
      final reportRef = FirebaseDatabase.instance.ref('reports').push();
      await reportRef.set({
        'reportedId': widget.player.id,
        'reportedName': widget.player.name,
        'reportedAgoraUid': widget.player.agoraUid,
        'reporterId': widget.currentUserId,
        'roomCode': widget.roomCode,
        'reason': _selectedReason,
        'details': _detailsController.text.trim(),
        'timestamp': ServerValue.timestamp,
      });

      if (!mounted) return;

      AgoraVoiceService().muteRemoteAudioStream(widget.player.agoraUid, true);

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          backgroundColor: const Color(0xFF1E1035),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: LupusColors.poisonGreen, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('report_sent_success'),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: LupusColors.bloodRed,
          content: Text('Erreur lors de l\'envoi du signalement : $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reasons = [
      {'key': 'report_reason_hate', 'label': context.tr('report_reason_hate')},
      {'key': 'report_reason_toxic', 'label': context.tr('report_reason_toxic')},
      {'key': 'report_reason_cheat', 'label': context.tr('report_reason_cheat')},
      {'key': 'report_reason_spam', 'label': context.tr('report_reason_spam')},
      {'key': 'report_reason_other', 'label': context.tr('report_reason_other')},
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: LupusColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: LupusColors.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: LupusColors.arcaneGold, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Signaler ${widget.player.name}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: LupusColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Sélectionnez le motif principal du signalement :',
            style: TextStyle(
              fontSize: 12,
              color: LupusColors.textSecondary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 10),
          ...reasons.map((r) {
            final isSelected = _selectedReason == r['label'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () => setState(() => _selectedReason = r['label']),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? LupusColors.arcaneGold.withValues(alpha: 0.15)
                        : LupusColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? LupusColors.arcaneGold
                          : LupusColors.border,
                      width: isSelected ? 1.4 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 16,
                        color: isSelected
                            ? LupusColors.arcaneGold
                            : LupusColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          r['label']!,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : LupusColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          TextField(
            controller: _detailsController,
            maxLines: 2,
            maxLength: 250,
            style: const TextStyle(fontSize: 12, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Précisions facultatives...',
              hintStyle: const TextStyle(fontSize: 12, color: LupusColors.textMuted),
              filled: true,
              fillColor: LupusColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: LupusColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: LupusColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: LupusColors.arcaneGold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: (_selectedReason != null && !_isSending) ? _submitReport : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: LupusColors.bloodRed,
              disabledBackgroundColor: LupusColors.bloodRed.withValues(alpha: 0.3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text(
                    'Envoyer le signalement & Muter localement',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
          ),
        ],
      ),
    );
  }
}
