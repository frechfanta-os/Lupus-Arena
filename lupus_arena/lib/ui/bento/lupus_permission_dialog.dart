import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/app_translations.dart';
import '../../services/lupus_permission_service.dart';
import '../theme/lupus_assets.dart';
import '../theme/lupus_theme.dart';
import 'bento_card.dart';

class LupusPermissionDialog extends StatefulWidget {
  final VoidCallback? onCompleted;

  const LupusPermissionDialog({super.key, this.onCompleted});

  static Future<void> showIfNeeded(BuildContext context) async {
    if (kIsWeb) return;
    try {
      final service = LupusPermissionService();
      final alreadyRequested = await service.hasRequestedPermissions();
      if (!alreadyRequested && context.mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withValues(alpha: 0.85),
          builder: (_) => const LupusPermissionDialog(),
        );
      }
    } catch (e) {
      debugPrint('[LupusPermissionDialog] Erreur showIfNeeded: $e');
    }
  }

  static Future<void> showForce(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => const LupusPermissionDialog(),
    );
  }

  @override
  State<LupusPermissionDialog> createState() => _LupusPermissionDialogState();
}

class _LupusPermissionDialogState extends State<LupusPermissionDialog> {
  final LupusPermissionService _service = LupusPermissionService();

  static const String _privacyUrl =
      'https://ghdinteractivestudio.github.io/lupus-arena-privacy.html';

  bool _isRequesting = false;
  bool _termsAccepted = false;
  bool _showTermsWarning = false;
  bool? _micGranted;
  bool? _notifGranted;
  bool? _bluetoothGranted;

  @override
  void initState() {
    super.initState();
    _checkCurrentStatuses();
  }

  Future<void> _checkCurrentStatuses() async {
    final mic = await _service.isMicGranted();
    final notif = await _service.isNotificationGranted();
    final bt = await _service.isBluetoothGranted();
    final terms = await _service.hasAcceptedTerms();

    if (mounted) {
      setState(() {
        _micGranted = mic;
        _notifGranted = notif;
        _bluetoothGranted = bt;
        _termsAccepted = terms;
      });
    }
  }

  Future<void> _openPrivacyUrl() async {
    final uri = Uri.parse(_privacyUrl);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        debugPrint('[LupusPermissionDialog] Impossible d\'ouvrir $_privacyUrl');
      }
    } catch (e) {
      debugPrint('[LupusPermissionDialog] Erreur ouverture URL: $e');
    }
  }

  Future<void> _requestAll() async {
    if (!_termsAccepted) {
      setState(() => _showTermsWarning = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('perm_terms_required')),
          backgroundColor: LupusColors.arcaneCrimson,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _showTermsWarning = false;
      _isRequesting = true;
    });

    try {
      await _service.setTermsAccepted(true);
      final statuses = await _service.requestAllPermissionsOnce(force: true);

      final micOk = statuses[Permission.microphone]?.isGranted ?? false;
      final notifOk = statuses[Permission.notification]?.isGranted ?? false;
      final btOk = kIsWeb
          ? true
          : (statuses[Permission.bluetoothConnect]?.isGranted ?? false);

      if (mounted) {
        setState(() {
          _micGranted = micOk;
          _notifGranted = notifOk;
          _bluetoothGranted = btOk;
          _isRequesting = false;
        });

        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) {
          widget.onCompleted?.call();
          Navigator.of(context).pop();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  void _skip() {
    widget.onCompleted?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final allGranted = (_micGranted == true) &&
        (_notifGranted == true) &&
        (kIsWeb || _bluetoothGranted == true);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: BentoCard(
        padding: const EdgeInsets.all(22),
        backgroundColor: const Color(0xF50A0F1E),
        borderColor: LupusColors.arcanePurple,
        glowing: true,
        borderRadius: 24,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: LupusTheme.glowPurple(opacity: 0.6),
                  ),
                  child: ClipOval(
                    child: LupusAssets.adaptiveImage(
                      assetPath: LupusAssets.wolfSealAsset,
                      networkUrl: LupusAssets.wolfSealUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                context.tr('perm_welcome_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('perm_welcome_subtitle'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 20),

              _buildPermissionTile(
                icon: Icons.mic_rounded,
                iconColor: LupusColors.voiceActive,
                title: context.tr('perm_mic_title'),
                description: context.tr('perm_mic_desc'),
                isGranted: _micGranted,
                isRequired: true,
              ),
              const SizedBox(height: 10),

              if (!kIsWeb) ...[
                _buildPermissionTile(
                  icon: Icons.headset_rounded,
                  iconColor: LupusColors.arcaneCyan,
                  title: context.tr('perm_bt_title'),
                  description: context.tr('perm_bt_desc'),
                  isGranted: _bluetoothGranted,
                  isRequired: false,
                ),
                const SizedBox(height: 10),
              ],

              _buildPermissionTile(
                icon: Icons.notifications_active_rounded,
                iconColor: LupusColors.arcaneGold,
                title: context.tr('perm_notif_title'),
                description: context.tr('perm_notif_desc'),
                isGranted: _notifGranted,
                isRequired: false,
              ),

              const SizedBox(height: 16),

              _buildTermsTile(),

              const SizedBox(height: 20),

              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isRequesting ? null : _requestAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (allGranted && _termsAccepted)
                        ? LupusColors.poisonGreen
                        : LupusColors.arcanePurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 6,
                  ),
                  icon: _isRequesting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon((allGranted && _termsAccepted)
                          ? Icons.check_circle
                          : Icons.security),
                  label: Text(
                    _isRequesting
                        ? context.tr('perm_requesting')
                        : ((allGranted && _termsAccepted)
                            ? context.tr('perm_confirmed')
                            : context.tr('perm_grant_all')),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    (allGranted && _termsAccepted)
                        ? context.tr('perm_close')
                        : context.tr('perm_later'),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsTile() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _showTermsWarning
            ? LupusColors.arcaneCrimson.withValues(alpha: 0.15)
            : LupusColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _showTermsWarning
              ? LupusColors.arcaneCrimson
              : (_termsAccepted
                  ? LupusColors.poisonGreen.withValues(alpha: 0.6)
                  : LupusColors.border),
          width: (_showTermsWarning || _termsAccepted) ? 1.4 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Theme(
            data: ThemeData(
              unselectedWidgetColor: Colors.white54,
            ),
            child: Checkbox(
              value: _termsAccepted,
              activeColor: LupusColors.poisonGreen,
              checkColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              onChanged: (val) {
                final accepted = val ?? false;
                setState(() {
                  _termsAccepted = accepted;
                  if (accepted) _showTermsWarning = false;
                });
                _service.setTermsAccepted(accepted);
              },
            ),
          ),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  context.tr('perm_terms_prefix'),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                InkWell(
                  onTap: _openPrivacyUrl,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      context.tr('perm_terms_link'),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: LupusColors.daylightCyan,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                        decorationColor: LupusColors.daylightCyan,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: LupusColors.daylightCyan,
            ),
            tooltip: context.tr('perm_terms_link'),
            onPressed: _openPrivacyUrl,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool? isGranted,
    required bool isRequired,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: LupusColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGranted == true
              ? LupusColors.poisonGreen.withValues(alpha: 0.6)
              : LupusColors.border,
          width: isGranted == true ? 1.4 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (isRequired)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: LupusColors.bloodRed.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          context.tr('perm_required'),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: LupusColors.bloodRed,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.3,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: isGranted == true
                ? const Icon(
                    Icons.check_circle,
                    color: LupusColors.poisonGreen,
                    size: 18,
                  )
                : Icon(
                    Icons.radio_button_unchecked,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 18,
                  ),
          ),
        ],
      ),
    );
  }
}
