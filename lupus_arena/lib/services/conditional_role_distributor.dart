import 'dart:math';

import '../models/game_phase.dart';
import '../models/player_model.dart';
import 'role_security_service.dart';

class RoleDistributionResult {
  final Map<String, PlayerModel> updatedPlayers;
  final Map<String, String> secretRoleTokens;
  final String encryptedWolfRoster;
  final List<String> seatingOrder;
  final GamePhase startingPhase;
  final int maxVisions;
  final int maxPotions;

  const RoleDistributionResult({
    required this.updatedPlayers,
    required this.secretRoleTokens,
    required this.encryptedWolfRoster,
    required this.seatingOrder,
    required this.startingPhase,
    required this.maxVisions,
    required this.maxPotions,
  });
}

class ConditionalRoleDistributor {

  static int computeVisionsQuota(int playerCount) {
    return max(1, playerCount ~/ 4);
  }

  static int computePotionsQuota(int playerCount) {
    return max(1, playerCount ~/ 10);
  }

  static List<GameRole> expandRolePool(Map<String, int> rolePool, int targetCount) {
    final List<GameRole> roles = [];
    rolePool.forEach((roleKey, count) {
      final role = GameRole.fromId(roleKey);
      if (role == GameRole.mayor) return;
      for (int i = 0; i < count; i++) {
        roles.add(role);
      }
    });

    while (roles.length < targetCount) {
      roles.add(GameRole.simpleVillager);
    }
    if (roles.length > targetCount) {
      roles.removeRange(targetCount, roles.length);
    }

    return roles;
  }

  static void fisherYatesShuffle<T>(List<T> list, Random random) {
    for (int i = list.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
  }

  static RoleDistributionResult distribute({
    required Map<String, PlayerModel> currentPlayers,
    required Map<String, int> rolePool,
    required String roomCode,
    Map<String, GameRole>? previousRoles,
  }) {
    final playerList = currentPlayers.values.toList();
    final int playerCount = playerList.length;
    final rand = Random.secure();

    final maxVisions = computeVisionsQuota(playerCount);
    final maxPotions = computePotionsQuota(playerCount);

    final expandedRoles = expandRolePool(rolePool, playerCount);
    fisherYatesShuffle(expandedRoles, rand);
    fisherYatesShuffle(expandedRoles, rand);

    final playerUids = playerList.map((p) => p.id).toList();
    fisherYatesShuffle(playerUids, rand);

    final assignedRoles = _optimizeRoleAssignment(
      playerUids: playerUids,
      availableRoles: List<GameRole>.from(expandedRoles),
      previousRoles: previousRoles ?? {},
      rand: rand,
    );

    final seatingOrder = List<String>.from(playerUids);
    fisherYatesShuffle(seatingOrder, rand);

    final Map<String, PlayerModel> updatedPlayers = {};
    final Map<String, String> secretRoleTokens = {};
    final List<String> wolfUids = [];

    for (int i = 0; i < playerList.length; i++) {
      final oldPlayer = playerList[i];
      final uid = oldPlayer.id;
      final assignedRole = assignedRoles[uid] ?? GameRole.simpleVillager;
      final seatIndex = seatingOrder.indexOf(uid);

      if (assignedRole.isEvil) {
        wolfUids.add(uid);
      }

      final encryptedToken = RoleSecurityService.encryptRole(
        assignedRole.id,
        uid,
        roomCode,
      );
      secretRoleTokens[uid] = encryptedToken;

      final updatedPlayer = oldPlayer.copyWith(
        role: assignedRole,
        roleInitial: assignedRole,
        initialRole: assignedRole,
        estDechu: false,
        potionsVie: (assignedRole == GameRole.witch) ? maxPotions : 0,
        potionsMort: (assignedRole == GameRole.witch) ? maxPotions : 0,
        visionsRestantes: (assignedRole == GameRole.seer) ? maxVisions : 0,
        isAlive: true,
        isSpeaking: false,
        isMuted: false,
        clearTargetVote: true,
        isLover: false,
        loverId: null,
        isCaptain: false,
        isCharmed: false,
        isDoused: false,
        hasUsedHealPotion: false,
        hasUsedPoisonPotion: false,
        encryptedRole: encryptedToken,
        seatIndex: seatIndex,
        pv: 100,
        isReadyReplay: false,
        wantsRematch: false,
      );

      updatedPlayers[uid] = updatedPlayer;
    }

    final encryptedWolfRoster = RoleSecurityService.encryptWolfRoster(
      wolfUids,
      roomCode,
    );

    final startingPhase = _resolveStartingPhase(updatedPlayers.values);

    return RoleDistributionResult(
      updatedPlayers: updatedPlayers,
      secretRoleTokens: secretRoleTokens,
      encryptedWolfRoster: encryptedWolfRoster,
      seatingOrder: seatingOrder,
      startingPhase: startingPhase,
      maxVisions: maxVisions,
      maxPotions: maxPotions,
    );
  }

  static Map<String, GameRole> _optimizeRoleAssignment({
    required List<String> playerUids,
    required List<GameRole> availableRoles,
    required Map<String, GameRole> previousRoles,
    required Random rand,
  }) {
    final Map<String, GameRole> assignments = {};
    final remainingRoles = List<GameRole>.from(availableRoles);

    for (final uid in playerUids) {
      final prev = previousRoles[uid];
      int candidateIndex = -1;

      if (prev != null) {

        for (int i = 0; i < remainingRoles.length; i++) {
          if (remainingRoles[i] != prev) {
            candidateIndex = i;
            break;
          }
        }
      }

      if (candidateIndex == -1 && remainingRoles.isNotEmpty) {
        candidateIndex = rand.nextInt(remainingRoles.length);
      }

      if (candidateIndex >= 0 && candidateIndex < remainingRoles.length) {
        assignments[uid] = remainingRoles.removeAt(candidateIndex);
      } else {
        assignments[uid] = GameRole.simpleVillager;
      }
    }

    return assignments;
  }

  static GamePhase _resolveStartingPhase(Iterable<PlayerModel> players) {
    bool hasRole(GameRole role) => players.any((p) => p.role == role);
    bool hasWolves() => players.any((p) => p.role.isEvil);

    if (hasRole(GameRole.thief) || hasRole(GameRole.thiefOfHearts)) return GamePhase.nightThief;
    if (hasRole(GameRole.cupid)) return GamePhase.nightCupid;
    if (hasRole(GameRole.defender)) return GamePhase.nightDefender;
    if (hasWolves()) return GamePhase.nightWerewolves;
    if (hasRole(GameRole.blackWolf)) return GamePhase.nightBlackWolf;
    if (hasRole(GameRole.seer)) return GamePhase.nightSeer;
    if (hasRole(GameRole.witch)) return GamePhase.nightWitch;
    if (hasRole(GameRole.pyromaniac)) return GamePhase.nightPyromaniac;
    return GamePhase.morningAnnouncement;
  }
}
