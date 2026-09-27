import 'package:flutter/material.dart';
import '../../services/audio_manager.dart';
import '../theme/lupus_theme.dart';

class MusicMuteButton extends StatelessWidget {
  final double size;
  final bool isCompact;

  const MusicMuteButton({
    super.key,
    this.size = 32.0,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: LupusAudioManager.instance.isMusicMutedNotifier,
      builder: (context, isMuted, _) {
        final tooltip = isMuted
            ? 'Musique coupée • Cliquer pour activer'
            : 'Musique active • Cliquer pour couper';
        final icon = isMuted ? Icons.music_off_rounded : Icons.music_note_rounded;
        final iconColor = isMuted ? LupusColors.bloodRed : LupusColors.arcaneGold;
        final bgColor = isMuted
            ? LupusColors.bloodRed.withValues(alpha: 0.18)
            : const Color(0xC012182E);
        final borderColor = isMuted
            ? LupusColors.bloodRed.withValues(alpha: 0.5)
            : LupusColors.arcaneGold.withValues(alpha: 0.45);

        if (isCompact) {
          return Tooltip(
            message: tooltip,
            child: GestureDetector(
              onTap: () => LupusAudioManager.instance.toggleMusicMute(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgColor,
                  border: Border.all(
                    color: borderColor,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isMuted
                          ? LupusColors.bloodRed.withValues(alpha: 0.25)
                          : LupusColors.arcaneGold.withValues(alpha: 0.25),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: size * 0.55,
                    color: iconColor,
                  ),
                ),
              ),
            ),
          );
        }

        return Tooltip(
          message: tooltip,
          child: IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: bgColor,
              side: BorderSide(
                color: borderColor,
                width: 1.0,
              ),
            ),
            onPressed: () => LupusAudioManager.instance.toggleMusicMute(),
            icon: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
        );
      },
    );
  }
}
