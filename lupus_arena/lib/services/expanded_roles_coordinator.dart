import '../models/player_model.dart';

class ExpandedRolesCoordinator {

  static List<GameRole> computeNightSequence({
    required int currentTurn,
    required List<GameRole> activeRolesInGame,
    required bool hasDeadWolves,
    required bool wolfCubDiedYesterday,
  }) {
    final sequence = <GameRole>[];

    for (final role in GameRole.values) {
      if (!activeRolesInGame.contains(role)) continue;

      if (role.actionType == ActionType.firstNightOnly && currentTurn > 1) {
        continue;
      }

      if (role == GameRole.bigBadWolf && hasDeadWolves) {
        continue;
      }

      if (role.nightPriority != null) {
        sequence.add(role);
      }
    }

    sequence.sort((a, b) => a.nightPriority!.compareTo(b.nightPriority!));
    return sequence;
  }

  static List<String> getFoxTrioIds({
    required String targetPlayerId,
    required List<String> alivePlayerIdsInOrder,
  }) {
    final targetIndex = alivePlayerIdsInOrder.indexOf(targetPlayerId);
    if (targetIndex == -1) return [targetPlayerId];

    final n = alivePlayerIdsInOrder.length;
    final leftNeighborId = alivePlayerIdsInOrder[(targetIndex - 1 + n) % n];
    final rightNeighborId = alivePlayerIdsInOrder[(targetIndex + 1) % n];

    return [targetPlayerId, leftNeighborId, rightNeighborId];
  }

  static bool resolveFoxSniff({
    required String targetPlayerId,
    required List<String> alivePlayerIdsInOrder,
    required Map<String, GameRole> playerRoles,
    required String? infectedPlayerId,
  }) {
    final trio = getFoxTrioIds(
      targetPlayerId: targetPlayerId,
      alivePlayerIdsInOrder: alivePlayerIdsInOrder,
    );

    return trio.any((id) {
      final role = playerRoles[id];
      final isWolf = role?.camp == Camp.wolves || id == infectedPlayerId;
      return isWolf;
    });
  }

  static bool shouldBearGrowl({
    required String bearTamerPlayerId,
    required List<String> alivePlayerIdsInOrder,
    required Map<String, GameRole> playerRoles,
    required String? infectedPlayerId,
  }) {
    if (bearTamerPlayerId == infectedPlayerId) return true;

    final index = alivePlayerIdsInOrder.indexOf(bearTamerPlayerId);
    if (index == -1) return false;

    final n = alivePlayerIdsInOrder.length;
    final leftId = alivePlayerIdsInOrder[(index - 1 + n) % n];
    final rightId = alivePlayerIdsInOrder[(index + 1) % n];

    for (final neighborId in [leftId, rightId]) {
      final role = playerRoles[neighborId];
      if (role?.camp == Camp.wolves || neighborId == infectedPlayerId) {
        return true;
      }
    }
    return false;
  }

  static bool resolveBearTamerGrowl({
    required String bearTamerPlayerId,
    required List<String> alivePlayerIdsInOrder,
    required Map<String, GameRole> playerRoles,
    required String? infectedPlayerId,
  }) {
    return shouldBearGrowl(
      bearTamerPlayerId: bearTamerPlayerId,
      alivePlayerIdsInOrder: alivePlayerIdsInOrder,
      playerRoles: playerRoles,
      infectedPlayerId: infectedPlayerId,
    );
  }

  static Map<String, int> applyCrowBonusVotes({
    required Map<String, int> baseVoteCounts,
    required String? crowTargetId,
  }) {
    final result = Map<String, int>.from(baseVoteCounts);
    if (crowTargetId != null) {
      result[crowTargetId] = (result[crowTargetId] ?? 0) + 2;
    }
    return result;
  }

  static String? resolveScapegoatTie({
    required List<PlayerModel> alivePlayers,
    Map<String, GameRole>? realRoles,
    required List<String> tiedCandidates,
  }) {
    if (tiedCandidates.length <= 1) return null;
    final scapegoat = alivePlayers.where((p) {
      final role = realRoles?[p.id] ?? p.role;
      return role == GameRole.scapegoat;
    }).firstOrNull;
    return scapegoat?.id;
  }

  static Map<String, dynamic> tallyDayVotes({
    required Map<String, String> playerVotes,
    required String? crowTargetId,
    required String? scapegoatPlayerId,
    required List<String> alivePlayerIds,
  }) {
    final scores = <String, int>{};
    for (final id in alivePlayerIds) {
      scores[id] = 0;
    }

    playerVotes.forEach((_, target) {
      if (scores.containsKey(target)) {
        scores[target] = scores[target]! + 1;
      }
    });

    if (crowTargetId != null && scores.containsKey(crowTargetId)) {
      scores[crowTargetId] = scores[crowTargetId]! + 2;
    }

    int highestScore = -1;
    final candidates = <String>[];

    scores.forEach((playerId, score) {
      if (score > highestScore) {
        highestScore = score;
        candidates
          ..clear()
          ..add(playerId);
      } else if (score == highestScore && score > 0) {
        candidates.add(playerId);
      }
    });

    if (candidates.length > 1) {

      if (scapegoatPlayerId != null && alivePlayerIds.contains(scapegoatPlayerId)) {
        return {
          'eliminatedPlayerId': scapegoatPlayerId,
          'reason': 'scapegoat_sacrifice',
          'scores': scores,
        };
      }
      return {
        'eliminatedPlayerId': null,
        'reason': 'tie_no_death',
        'scores': scores,
      };
    }

    return {
      'eliminatedPlayerId': candidates.isNotEmpty ? candidates.first : null,
      'reason': 'majority_vote',
      'scores': scores,
    };
  }

  static bool checkElderDeathConsequences({
    required String killedPlayerId,
    required GameRole killedRole,
    required String eliminationSource,
  }) {
    if (killedRole == GameRole.elder && eliminationSource != 'wolves') {

      return true;
    }
    return false;
  }

  static String? findWolfToContaminate({
    required String knightPlayerId,
    required List<String> alivePlayerIdsInOrder,
    required Map<String, GameRole> playerRoles,
    required String? infectedPlayerId,
  }) {
    final startIndex = alivePlayerIdsInOrder.indexOf(knightPlayerId);
    if (startIndex == -1) return null;

    final n = alivePlayerIdsInOrder.length;

    for (int i = 1; i < n; i++) {
      final candidateId = alivePlayerIdsInOrder[(startIndex - i + n) % n];
      final role = playerRoles[candidateId];
      if (role?.camp == Camp.wolves || candidateId == infectedPlayerId) {
        return candidateId;
      }
    }
    return null;
  }

  static bool checkSectarianVictory({
    required String sectarianPlayerId,
    required List<String> alivePlayerIds,
    required Map<String, List<String>> sectarianTeams,
  }) {
    if (!alivePlayerIds.contains(sectarianPlayerId)) return false;

    final teamA = sectarianTeams['teamA'] ?? [];
    final teamB = sectarianTeams['teamB'] ?? [];

    final isSectarianInA = teamA.contains(sectarianPlayerId);
    final opposingTeam = isSectarianInA ? teamB : teamA;

    return opposingTeam.every((id) => !alivePlayerIds.contains(id));
  }

  static String? checkSectarianWin({
    required List<PlayerModel> alivePlayers,
    required List<String> sectarianTeamA,
    required List<String> sectarianTeamB,
  }) {
    final sectarian = alivePlayers.where((p) => p.role == GameRole.sectLeader).firstOrNull;
    if (sectarian == null) return null;
    final aliveIds = alivePlayers.map((p) => p.id).toSet();
    final isInA = sectarianTeamA.contains(sectarian.id);
    final opposingTeam = isInA ? sectarianTeamB : sectarianTeamA;
    if (opposingTeam.isNotEmpty && opposingTeam.every((id) => !aliveIds.contains(id))) {
      return 'abominableSectarian';
    }
    return null;
  }
}
