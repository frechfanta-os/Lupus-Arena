import 'package:flutter/foundation.dart';
import '../models/player_model.dart';

class DeathRegistryService {
  DeathRegistryService._internal();
  static final DeathRegistryService _instance = DeathRegistryService._internal();
  static DeathRegistryService get instance => _instance;
  factory DeathRegistryService() => _instance;

  final Set<String> _cemeteryUids = <String>{};

  Set<String> get deadPlayerIds => Set.unmodifiable(_cemeteryUids);

  bool isDead(String? playerId) {
    if (playerId == null || playerId.isEmpty) return false;
    return _cemeteryUids.contains(playerId);
  }

  bool isAlive(String? playerId) {
    if (playerId == null || playerId.isEmpty) return false;
    return !_cemeteryUids.contains(playerId);
  }

  void markDead(String? playerId) {
    if (playerId == null || playerId.isEmpty) return;
    if (_cemeteryUids.add(playerId)) {
      debugPrint('[DeathRegistryService] 💀 Joueur inscrit au cimetière définitif: $playerId');
    }
  }

  void markDeadBatch(Iterable<String?> playerIds) {
    for (final id in playerIds) {
      if (id != null && id.isNotEmpty) {
        markDead(id);
      }
    }
  }

  void allowWitchRevive(String? victimId) {
    if (victimId == null || victimId.isEmpty) return;
    if (_cemeteryUids.remove(victimId)) {
      debugPrint('[DeathRegistryService] ✨ Potion de la Sorcière : joueur $victimId réanimé du cimetière.');
    }
  }

  void clearForNewGame() {
    debugPrint('[DeathRegistryService] 🔄 Réinitialisation du registre de mort pour une nouvelle partie.');
    _cemeteryUids.clear();
  }

  PlayerModel enforcePlayer(PlayerModel player) {
    if (isDead(player.id)) {
      if (player.isAlive) {
        debugPrint('[DeathRegistryService] 🛡️ Tentative de résurrection bloquée pour ${player.id} (${player.name})');
        return player.copyWith(isAlive: false);
      }
      return player;
    } else if (!player.isAlive) {

      markDead(player.id);
    }
    return player;
  }

  Map<String, PlayerModel> filterOrEnforce(Map<String, PlayerModel> players) {
    final Map<String, PlayerModel> enforced = {};
    for (final entry in players.entries) {
      final pid = entry.key;
      final player = entry.value;

      if (isDead(pid)) {

        enforced[pid] = player.isAlive ? player.copyWith(isAlive: false) : player;
      } else if (!player.isAlive) {

        markDead(pid);
        enforced[pid] = player;
      } else {
        enforced[pid] = player;
      }
    }
    return enforced;
  }

  void syncFromFirebase(dynamic rawCemetery, [dynamic rawMorningVictims]) {
    if (rawCemetery is Map) {
      rawCemetery.forEach((key, val) {
        if (val == true || val == 1 || val == 'true') {
          markDead(key.toString());
        }
      });
    } else if (rawCemetery is List) {
      for (final id in rawCemetery) {
        if (id != null) markDead(id.toString());
      }
    }

    if (rawMorningVictims is List) {
      for (final id in rawMorningVictims) {
        if (id != null) markDead(id.toString());
      }
    }
  }

  Map<String, dynamic> generateFirebaseCemeteryUpdates() {
    final updates = <String, dynamic>{};
    for (final pid in _cemeteryUids) {
      updates['players/$pid/isAlive'] = false;
      updates['cemetery/$pid'] = true;
    }
    return updates;
  }
}
