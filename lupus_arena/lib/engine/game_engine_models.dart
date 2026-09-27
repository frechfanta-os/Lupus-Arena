enum RoleType {
  villager,
  werewolf,
  stealer,
  cupid,
  actor,
  seer,
  fox,
  crow,
  pyromaniac,
  bodyguard,
  fatherOfWolves,
  bigBadWolf,
  whiteWolf,
  witch,
  dedicatedMaid,
  stutteringJudge,
  hunter,
}

enum Faction {
  village,
  werewolves,
  whiteWolf,
  lovers,
}

enum GamePhase {
  initialization,
  preliminaryNight,
  night,
  dayAnnounceDeaths,
  dayDiscussion,
  dayVoting,
  dayExecution,
  checkWinConditions,
  gameOver,
}

enum GameStep {

  preStealer,
  preCupid,

  roleActor,
  roleSeer,
  roleFox,
  roleCrow,
  rolePyromaniac,
  roleBodyguard,
  roleWerewolves,
  roleBigBadWolf,
  roleWhiteWolf,
  roleWitch,

  hookDedicatedMaid,
}

enum KillSource {
  werewolves,
  bigBadWolf,
  whiteWolf,
  witchPoison,
  pyromaniacFire,
  brokenHeart,
  villageExecution,
}

class KillIntent {
  final String targetPlayerId;
  final KillSource source;

  const KillIntent({required this.targetPlayerId, required this.source});
}

class NightActionBuffer {
  final List<KillIntent> killIntents = [];
  String? protectedPlayerId;
  String? healedPlayerId;
  bool isInfected = false;

  void clear() {
    killIntents.clear();
    protectedPlayerId = null;
    healedPlayerId = null;
    isInfected = false;
  }
}

class Player {
  final String id;
  final String name;
  RoleType role;
  Faction faction;
  bool isAlive;
  bool isCaptain;
  bool isDousedWithGas;
  Set<String> loversIds;

  Player({
    required this.id,
    required this.name,
    required this.role,
    this.faction = Faction.village,
    this.isAlive = true,
    this.isCaptain = false,
    this.isDousedWithGas = false,
    Set<String>? loversIds,
  }) : loversIds = loversIds ?? {};

  Player copyWith({
    String? id,
    String? name,
    RoleType? role,
    Faction? faction,
    bool? isAlive,
    bool? isCaptain,
    bool? isDousedWithGas,
    Set<String>? loversIds,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      faction: faction ?? this.faction,
      isAlive: isAlive ?? this.isAlive,
      isCaptain: isCaptain ?? this.isCaptain,
      isDousedWithGas: isDousedWithGas ?? this.isDousedWithGas,
      loversIds: loversIds ?? Set.from(this.loversIds),
    );
  }
}
