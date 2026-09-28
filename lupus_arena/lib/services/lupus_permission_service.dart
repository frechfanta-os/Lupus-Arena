import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LupusPermissionService with WidgetsBindingObserver {
  static final LupusPermissionService _instance =
      LupusPermissionService._internal();
  factory LupusPermissionService() => _instance;
  LupusPermissionService._internal();

  static const String _keyPermissionsRequested =
      'lupus_permissions_requested_once';
  static const String _keyMicGranted = 'lupus_permission_mic_granted';
  static const String _keyNotificationGranted =
      'lupus_permission_notification_granted';
  static const String _keyBluetoothGranted =
      'lupus_permission_bluetooth_granted';
  static const String _keyLastRequested = 'lupus_permissions_timestamp';
  static const String _keyTermsAccepted = 'lupus_terms_accepted';

  final ValueNotifier<bool> isMicGrantedNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isNotificationGrantedNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isBluetoothGrantedNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isTermsAcceptedNotifier = ValueNotifier(false);

  static void Function()? onPermissionsRefreshed;

  Timer? _backgroundTimer;
  bool _isMonitoring = false;

  void startBackgroundPermissionMonitor() {
    if (_isMonitoring) return;
    _isMonitoring = true;

    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (e) {
      debugPrint('[LupusPermissionService] Erreur ajout observateur: $e');
    }

    refreshPermissionsSilently();

    _backgroundTimer?.cancel();
    _backgroundTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      refreshPermissionsSilently();
    });

    debugPrint('[LupusPermissionService] Moniteur de permissions en arrière-plan démarré.');
  }

  void stopBackgroundPermissionMonitor() {
    _isMonitoring = false;
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('[LupusPermissionService] Application reprise (resumed) -> Rafraîchissement des autorisations...');
      refreshPermissionsSilently();
    }
  }

  static List<Permission> get requiredPermissions {
    if (kIsWeb) {

      return const [
        Permission.microphone,
        Permission.notification,
      ];
    }
    return const [
      Permission.microphone,
      Permission.notification,
      Permission.bluetoothConnect,
    ];
  }

  Future<bool> hasRequestedPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyPermissionsRequested) ?? false;
    } catch (e) {
      debugPrint('[LupusPermissionService] Erreur lecture SharedPreferences: $e');
      return false;
    }
  }

  Future<Map<Permission, PermissionStatus>> requestAllPermissionsOnce({
    bool force = false,
  }) async {
    final alreadyRequested = await hasRequestedPermissions();

    if (alreadyRequested && !force) {
      debugPrint(
        '[LupusPermissionService] Permissions déjà demandées précédemment. '
        'Synchronisation silencieuse sans ré-interpeller l\'utilisateur.',
      );
      return await refreshPermissionsSilently();
    }

    debugPrint('[LupusPermissionService] Première demande groupée des permissions...');
    final Map<Permission, PermissionStatus> statuses = {};
    try {

      for (final perm in requiredPermissions) {
        try {
          final status = await perm.request();
          statuses[perm] = status;
        } catch (e) {
          debugPrint('[LupusPermissionService] Permission non gérée ou ignorée pour $perm: $e');
          statuses[perm] = PermissionStatus.denied;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPermissionsRequested, true);

      final micGranted = statuses[Permission.microphone]?.isGranted ?? false;
      final notifGranted = statuses[Permission.notification]?.isGranted ?? false;
      final btGranted = kIsWeb
          ? true
          : (statuses[Permission.bluetoothConnect]?.isGranted ?? false);

      await prefs.setBool(_keyMicGranted, micGranted);
      await prefs.setBool(_keyNotificationGranted, notifGranted);
      await prefs.setBool(_keyBluetoothGranted, btGranted);
      await prefs.setString(
        _keyLastRequested,
        DateTime.now().toIso8601String(),
      );

      isMicGrantedNotifier.value = micGranted;
      isNotificationGrantedNotifier.value = notifGranted;
      isBluetoothGrantedNotifier.value = btGranted;

      onPermissionsRefreshed?.call();

      debugPrint(
        '[LupusPermissionService] Choix sauvegardés avec succès -> '
        'Micro: $micGranted, Notif: $notifGranted, Bluetooth/Baffles: $btGranted',
      );
    } catch (e) {
      debugPrint('[LupusPermissionService] Erreur lors de la demande: $e');
    }

    return statuses;
  }

  Future<Map<Permission, PermissionStatus>> refreshPermissionsSilently() async {
    final statuses = <Permission, PermissionStatus>{};
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final permission in requiredPermissions) {
        try {
          final status = await permission.status;
          statuses[permission] = status;
        } catch (_) {
          statuses[permission] = PermissionStatus.denied;
        }
      }

      final micGranted = statuses[Permission.microphone]?.isGranted ?? false;
      final notifGranted = statuses[Permission.notification]?.isGranted ?? false;
      final btGranted = kIsWeb
          ? true
          : (statuses[Permission.bluetoothConnect]?.isGranted ?? false);

      await prefs.setBool(_keyMicGranted, micGranted);
      await prefs.setBool(_keyNotificationGranted, notifGranted);
      if (!kIsWeb) {
        await prefs.setBool(_keyBluetoothGranted, btGranted);
      }

      final bool micChanged = isMicGrantedNotifier.value != micGranted;
      isMicGrantedNotifier.value = micGranted;
      isNotificationGrantedNotifier.value = notifGranted;
      isBluetoothGrantedNotifier.value = btGranted;

      if (micChanged) {
        debugPrint('[LupusPermissionService] Statut Microphone actualisé: $micGranted');
      }

      onPermissionsRefreshed?.call();
    } catch (e) {
      debugPrint('[LupusPermissionService] Erreur synchronisation silencieuse: $e');
    }
    return statuses;
  }

  Future<bool> ensureMicrophonePermission() async {
    try {
      final micStatus = await Permission.microphone.status;
      if (micStatus.isGranted) {
        isMicGrantedNotifier.value = true;
        return true;
      }

      final requestStatus = await Permission.microphone.request();
      final isGranted = requestStatus.isGranted;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyMicGranted, isGranted);
      isMicGrantedNotifier.value = isGranted;

      onPermissionsRefreshed?.call();
      return isGranted;
    } catch (e) {
      debugPrint('[LupusPermissionService] Erreur ensureMicrophonePermission: $e');
      return false;
    }
  }

  Future<bool> isMicGranted() async {
    try {
      final status = await Permission.microphone.status;
      isMicGrantedNotifier.value = status.isGranted;
      return status.isGranted;
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getBool(_keyMicGranted) ?? false;
      isMicGrantedNotifier.value = val;
      return val;
    }
  }

  Future<bool> isNotificationGranted() async {
    try {
      final status = await Permission.notification.status;
      isNotificationGrantedNotifier.value = status.isGranted;
      return status.isGranted;
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getBool(_keyNotificationGranted) ?? false;
      isNotificationGrantedNotifier.value = val;
      return val;
    }
  }

  Future<bool> isBluetoothGranted() async {
    try {
      final status = await Permission.bluetoothConnect.status;
      isBluetoothGrantedNotifier.value = status.isGranted;
      return status.isGranted;
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getBool(_keyBluetoothGranted) ?? false;
      isBluetoothGrantedNotifier.value = val;
      return val;
    }
  }

  Future<bool> hasAcceptedTerms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getBool(_keyTermsAccepted) ?? false;
      isTermsAcceptedNotifier.value = val;
      return val;
    } catch (_) {
      return false;
    }
  }

  Future<void> setTermsAccepted(bool accepted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyTermsAccepted, accepted);
      isTermsAcceptedNotifier.value = accepted;
    } catch (e) {
      debugPrint('[LupusPermissionService] Erreur setTermsAccepted: $e');
    }
  }

  Future<void> resetPermissionsChoice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPermissionsRequested);
    await prefs.remove(_keyMicGranted);
    await prefs.remove(_keyNotificationGranted);
    await prefs.remove(_keyBluetoothGranted);
    await prefs.remove(_keyLastRequested);
    await prefs.remove(_keyTermsAccepted);
    isMicGrantedNotifier.value = false;
    isNotificationGrantedNotifier.value = false;
    isBluetoothGrantedNotifier.value = false;
    isTermsAcceptedNotifier.value = false;
    debugPrint('[LupusPermissionService] Choix des permissions réinitialisé.');
  }
}
