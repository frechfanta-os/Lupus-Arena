import 'dart:math';

import '../models/player_model.dart';
import 'expanded_roles_coordinator.dart';

class SeerActionHandler {
  const SeerActionHandler();

  int calculateInitialVisions(int totalPlayers) {
    if (totalPlayers <= 4) return 1;
    if (totalPlayers <= 9) return 2;
    if (totalPlayers <= 14) return 3;
    return totalPlayers ~/ 4;
  }

  GameRole getPerceivedRole(GameRole realRole) {
    if (realRole == GameRole.whiteWerewolf) {
      return GameRole.simpleVillager;
    }
    return realRole;
  }

  bool canInspect({required PlayerModel seer, bool isAdmin = false}) {
    if (isAdmin) return true;
    return seer.isAlive && seer.visionsRestantes > 0;
  }
}

class WitchActionHandler {
  const WitchActionHandler();

  int calculateInitialPotions(int totalPlayers) {
    return max(1, totalPlayers ~/ 10);
  }

  bool canSave({
    required PlayerModel witch,
    required String? wolfVictimId,
    required bool alreadyHealedThisNight,
    bool isAdmin = false,
  }) {
    if (wolfVictimId == null || alreadyHealedThisNight) return false;
    if (isAdmin) return true;
    return witch.isAlive && witch.potionsVie > 0;
  }

  bool canPoison({
    required PlayerModel witch,
    required PlayerModel? target,
    required String? alreadyPoisonedThisNight,
    bool isAdmin = false,
  }) {
    if (target == null || !target.isAlive || alreadyPoisonedThisNight != null) {
      return false;
    }
    if (isAdmin) return true;
    return witch.isAlive && witch.potionsMort > 0;
  }
}

class LoverActionHandler {
  const LoverActionHandler();

  String? handleLoverDeath(
    String deadPlayerId,
    Map<String, PlayerModel> players,
    List<String> logs,
  ) {
    final dead = players[deadPlayerId];
    if (dead == null || !dead.isLover || dead.loverId == null) return null;

    final partnerId = dead.loverId!;
    final partner = players[partnerId];
    if (partner != null && partner.isAlive) {
      logs.add(
        '💔 Amour brisé : ${partner.name} ne peut survivre à la perte de son âme sœur ${dead.name} et meurt de chagrin !',
      );
      return partnerId;
    }
    return null;
  }
}

class RoleActionDispatcher {
  final SeerActionHandler seer = const SeerActionHandler();
  final WitchActionHandler witch = const WitchActionHandler();
  final LoverActionHandler lover = const LoverActionHandler();

  const RoleActionDispatcher();

  bool resolveFoxSniff({
    required String targetPlayerId,
    required List<String> alivePlayerIdsInOrder,
    required Map<String, GameRole> playerRoles,
    String? infectedPlayerId,
  }) {
    return ExpandedRolesCoordinator.resolveFoxSniff(
      targetPlayerId: targetPlayerId,
      alivePlayerIdsInOrder: alivePlayerIdsInOrder,
      playerRoles: playerRoles,
      infectedPlayerId: infectedPlayerId,
    );
  }

  bool resolveBearTamerGrowl({
    required String bearTamerPlayerId,
    required List<String> alivePlayerIdsInOrder,
    required Map<String, GameRole> playerRoles,
    String? infectedPlayerId,
  }) {
    return ExpandedRolesCoordinator.shouldBearGrowl(
      bearTamerPlayerId: bearTamerPlayerId,
      alivePlayerIdsInOrder: alivePlayerIdsInOrder,
      playerRoles: playerRoles,
      infectedPlayerId: infectedPlayerId,
    );
  }
}
