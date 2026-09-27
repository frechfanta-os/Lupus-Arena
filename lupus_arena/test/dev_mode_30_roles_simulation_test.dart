import 'package:flutter_test/flutter_test.dart';

enum Camp { village, werewolves, solo, neutral }

enum Role {

  villager,
  seer,
  witch,
  hunter,
  cupid,
  littleGirl,
  guard,
  elder,
  idiot,
  fox,
  bearTamer,
  knightWithRustySword,
  servant,
  twoSisters,
  threeBrothers,
  stutteringJudge,
  raven,
  pyromaniac,

  werewolf,
  bigBadWolf,
  whiteWerewolf,
  wolfHound,
  wildChild,
  infectedFatherOfWolves,

  piper,
  angel,
  thief,
  actor,
  abominableSectarian,
  charlatan,
}

class Player {
  final String id;
  final String name;
  Role role;
  Camp camp;
  bool isAlive;
  bool isProtected;
  bool isCharmed;
  bool isInfected;
  int lives;
  String? inLoveWithId;

  Player({
    required this.id,
    required this.name,
    required this.role,
    required this.camp,
    this.isAlive = true,
    this.isProtected = false,
    this.isCharmed = false,
    this.isInfected = false,
    this.lives = 1,
    this.inLoveWithId,
  });

  @override
  String toString() =>
      '[$id] $name | ${role.name.padRight(22)} | Camp: ${camp.name.padRight(10)} | '
      'Vivant: $isAlive | Charmé: $isCharmed | Protégé: $isProtected';
}

class FullGameSimulator {
  final Map<String, Player> players = {};
  int currentNight = 1;

  String? werewolfVictimId;
  String? whiteWolfVictimId;
  String? bigBadWolfVictimId;
  String? witchHealedId;
  String? witchKilledId;
  String? guardProtectedId;
  String? ravenAccusedId;
  final Set<String> charmedTonight = {};
  bool witchHasHeal = true;
  bool witchHasDeath = true;
  bool infectionAvailable = true;

  FullGameSimulator(List<Player> playerList) {
    for (var p in playerList) {
      players[p.id] = p;
    }
  }

  Player _p(String id) => players[id] ?? (throw Exception('ID invalide: $id'));

  void devSetRole(String id, Role newRole, Camp newCamp) {
    final p = _p(id);
    p.role = newRole;
    p.camp = newCamp;

    print('[DEV] Rôle forcé: ${p.name} -> ${newRole.name} (${newCamp.name})');
  }

  void devKill(String id, {required String reason}) {
    final p = _p(id);
    if (!p.isAlive) return;

    if (p.lives > 1 && reason == 'attaque des loups') {
      p.lives--;

      print('[DEV RESISTANCE] ${p.name} survit à l\'assaut (Vies restantes: ${p.lives}).');
      return;
    }

    p.isAlive = false;

    print('[DEV MORT] ${p.name} (${p.role.name}) est éliminé -> Raison: $reason');

    if (p.inLoveWithId != null) {
      final lover = _p(p.inLoveWithId!);
      if (lover.isAlive) {

        print('[AMOUR] ${lover.name} succombe au chagrin.');
        devKill(lover.id, reason: 'chagrin d\'amour');
      }
    }

    if (p.role == Role.hunter) {

      print('[POUVOIR] Le Chasseur ${p.name} doit tirer avant de sombrer.');
    }

    if (p.role == Role.knightWithRustySword && reason.contains('loup')) {

      print('[POUVOIR] Le Chevalier empoisonne un loup avec sa rouille pour la nuit suivante.');
    }
  }

  void powerThief(String thiefId, Role chosenRole, Camp chosenCamp) {
    final p = _p(thiefId);
    if (p.role != Role.thief || !p.isAlive) return;
    p.role = chosenRole;
    p.camp = chosenCamp;

    print('[NUIT 0 - VOLEUR] ${p.name} vole le rôle : ${chosenRole.name}');
  }

  void powerCupid(String cupidId, String id1, String id2) {
    final c = _p(cupidId);
    if (c.role != Role.cupid || !c.isAlive) return;
    final p1 = _p(id1);
    final p2 = _p(id2);
    p1.inLoveWithId = p2.id;
    p2.inLoveWithId = p1.id;

    print('[NUIT - CUPIDON] ${p1.name} et ${p2.name} sont liés.');
  }

  void powerGuard(String guardId, String targetId) {
    final g = _p(guardId);
    if (g.role != Role.guard || !g.isAlive) return;
    guardProtectedId = targetId;
    _p(targetId).isProtected = true;

    print('[NUIT - SALVATEUR] ${g.name} déploie son bouclier sur ${_p(targetId).name}.');
  }

  void powerSeer(String seerId, String targetId) {
    final s = _p(seerId);
    if (s.role != Role.seer || !s.isAlive) return;
    final target = _p(targetId);

    print('[NUIT - VOYANTE] ${s.name} découvre que ${target.name} est [${target.role.name}].');
  }

  void powerFox(String foxId, String idA, String idB, String idC) {
    final f = _p(foxId);
    if (f.role != Role.fox || !f.isAlive) return;
    final group = [idA, idB, idC].map((id) => _p(id));
    final hasWolf = group.any((p) => p.camp == Camp.werewolves);

    print('[NUIT - RENARD] ${f.name} flaire le trio : ${hasWolf ? "Loup détecté !" : "Aucun loup, pouvoir perdu."}');
  }

  void powerWerewolvesVote(String victimId) {
    werewolfVictimId = victimId;

    print('[NUIT - MEUTE] Cible désignée par la meute : ${_p(victimId).name}');
  }

  void powerBigBadWolf(String wolfId, String victimId) {
    final b = _p(wolfId);
    if (b.role != Role.bigBadWolf || !b.isAlive) return;
    bigBadWolfVictimId = victimId;

    print('[NUIT - GRAND MÉCHANT LOUP] Deuxième victime ciblée : ${_p(victimId).name}');
  }

  void powerInfectFather(String fatherId) {
    final f = _p(fatherId);
    if (f.role != Role.infectedFatherOfWolves || !f.isAlive || !infectionAvailable) return;
    if (werewolfVictimId != null) {
      final victim = _p(werewolfVictimId!);
      victim.isInfected = true;
      victim.camp = Camp.werewolves;
      infectionAvailable = false;
      werewolfVictimId = null;

      print('[NUIT - INFECTION] Le Père des Loups infecte ${victim.name} qui rejoint la meute.');
    }
  }

  void powerWhiteWolf(String whiteWolfId, String wolfTargetId) {
    final w = _p(whiteWolfId);
    if (w.role != Role.whiteWerewolf || !w.isAlive) return;
    final target = _p(wolfTargetId);
    if (target.camp == Camp.werewolves) {
      whiteWolfVictimId = target.id;

      print('[NUIT - LOUP BLANC] Trahison : ${w.name} vise ${target.name}');
    }
  }

  void powerWitch({
    required String witchId,
    bool heal = false,
    String? poisonTargetId,
  }) {
    final w = _p(witchId);
    if (w.role != Role.witch || !w.isAlive) return;

    if (heal && witchHasHeal && werewolfVictimId != null) {
      witchHealedId = werewolfVictimId;
      witchHasHeal = false;

      print('[NUIT - SORCIÈRE] Potion de vie utilisée sur ${_p(werewolfVictimId!).name}.');
    }
    if (poisonTargetId != null && witchHasDeath) {
      witchKilledId = poisonTargetId;
      witchHasDeath = false;

      print('[NUIT - SORCIÈRE] Potion de mort versée sur ${_p(poisonTargetId).name}.');
    }
  }

  void powerPiper(String piperId, List<String> targetIds) {
    final p = _p(piperId);
    if (p.role != Role.piper || !p.isAlive) return;
    for (var id in targetIds) {
      charmedTonight.add(id);
      _p(id).isCharmed = true;
    }

    print('[NUIT - FLÛTE] Joueurs enchantés cette nuit: ${targetIds.map((id) => _p(id).name).join(", ")}');
  }

  void powerRaven(String ravenId, String targetId) {
    final r = _p(ravenId);
    if (r.role != Role.raven || !r.isAlive) return;
    ravenAccusedId = targetId;

    print('[NUIT - CORBEAU] Affiche anonyme clouée contre ${_p(targetId).name} (+2 votes demain).');
  }

  void triggerHunterShot(String hunterId, String targetId) {
    final h = _p(hunterId);

    print('[CHASSEUR] ${h.name} fait feu sur ${_p(targetId).name} !');
    devKill(targetId, reason: 'tir de riposte du chasseur');
  }

  void resolveNight() {

    print('\n==================== AUBE (FIN NUIT $currentNight) ====================');

    if (werewolfVictimId != null) {
      final victim = _p(werewolfVictimId!);
      if (victim.id == witchHealedId || victim.isProtected) {

        print('[RÉSOLU] L\'attaque de la meute a été contrée (soin/bouclier).');
      } else {
        devKill(victim.id, reason: 'attaque des loups');
      }
    }

    if (bigBadWolfVictimId != null) {
      final victim = _p(bigBadWolfVictimId!);
      if (!victim.isProtected) {
        devKill(victim.id, reason: 'attaque du Grand Méchant Loup');
      }
    }

    if (whiteWolfVictimId != null) {
      devKill(whiteWolfVictimId!, reason: 'carnage du Loup Blanc');
    }

    if (witchKilledId != null) {
      devKill(witchKilledId!, reason: 'poison de la sorcière');
    }

    if (guardProtectedId != null) {
      _p(guardProtectedId!).isProtected = false;
      guardProtectedId = null;
    }
    werewolfVictimId = null;
    whiteWolfVictimId = null;
    bigBadWolfVictimId = null;
    witchHealedId = null;
    witchKilledId = null;
    charmedTonight.clear();
    currentNight++;

    print('===============================================================\n');
  }

  void printStatus() {

    print('\n--- STATUT GLOBAL DU PLATEAU (30 JOUEURS) ---');

    players.values.forEach(print);

    print('--------------------------------------------\n');
  }
}

List<Player> createInitial30Players() {
  return [

    Player(id: '01', name: 'Alice', role: Role.villager, camp: Camp.village),
    Player(id: '02', name: 'Bob', role: Role.seer, camp: Camp.village),
    Player(id: '03', name: 'Charlie', role: Role.witch, camp: Camp.village),
    Player(id: '04', name: 'David', role: Role.hunter, camp: Camp.village),
    Player(id: '05', name: 'Emma', role: Role.cupid, camp: Camp.village),
    Player(id: '06', name: 'Fiona', role: Role.littleGirl, camp: Camp.village),
    Player(id: '07', name: 'Gabriel', role: Role.guard, camp: Camp.village),
    Player(id: '08', name: 'Helena', role: Role.elder, camp: Camp.village, lives: 2),
    Player(id: '09', name: 'Isaac', role: Role.idiot, camp: Camp.village),
    Player(id: '10', name: 'Julia', role: Role.fox, camp: Camp.village),
    Player(id: '11', name: 'Kevin', role: Role.bearTamer, camp: Camp.village),
    Player(id: '12', name: 'Liam', role: Role.knightWithRustySword, camp: Camp.village),
    Player(id: '13', name: 'Mia', role: Role.servant, camp: Camp.village),
    Player(id: '14', name: 'Nora', role: Role.twoSisters, camp: Camp.village),
    Player(id: '15', name: 'Oscar', role: Role.threeBrothers, camp: Camp.village),
    Player(id: '16', name: 'Paul', role: Role.stutteringJudge, camp: Camp.village),
    Player(id: '17', name: 'Quentin', role: Role.raven, camp: Camp.village),
    Player(id: '18', name: 'Rose', role: Role.pyromaniac, camp: Camp.village),

    Player(id: '19', name: 'Sam', role: Role.werewolf, camp: Camp.werewolves),
    Player(id: '20', name: 'Tom', role: Role.werewolf, camp: Camp.werewolves),
    Player(id: '21', name: 'Ulysse', role: Role.bigBadWolf, camp: Camp.werewolves),
    Player(id: '22', name: 'Victor', role: Role.whiteWerewolf, camp: Camp.werewolves),
    Player(id: '23', name: 'Wendy', role: Role.wolfHound, camp: Camp.village),
    Player(id: '24', name: 'Xavier', role: Role.infectedFatherOfWolves, camp: Camp.werewolves),

    Player(id: '25', name: 'Yann', role: Role.wildChild, camp: Camp.village),
    Player(id: '26', name: 'Zoe', role: Role.piper, camp: Camp.solo),
    Player(id: '27', name: 'Arthur', role: Role.angel, camp: Camp.solo),
    Player(id: '28', name: 'Bastien', role: Role.thief, camp: Camp.neutral),
    Player(id: '29', name: 'Chloe', role: Role.actor, camp: Camp.neutral),
    Player(id: '30', name: 'Damien', role: Role.abominableSectarian, camp: Camp.solo),
  ];
}

void main() {
  test('Simulation Dev Mode complète sur 30 rôles', () {
    final initial30Players = createInitial30Players();
    final engine = FullGameSimulator(initial30Players);
    expect(engine.players.length, equals(30));

    engine.powerThief('28', Role.villager, Camp.village);
    expect(engine.players['28']!.role, equals(Role.villager));

    engine.powerCupid('05', '04', '19');
    expect(engine.players['04']!.inLoveWithId, equals('19'));
    expect(engine.players['19']!.inLoveWithId, equals('04'));

    engine.powerGuard('07', '02');
    expect(engine.players['02']!.isProtected, isTrue);

    engine.powerSeer('02', '21');
    engine.powerFox('10', '18', '19', '20');

    engine.powerWerewolvesVote('08');
    engine.powerBigBadWolf('21', '01');
    engine.powerWhiteWolf('22', '20');

    engine.powerWitch(witchId: '03', heal: false, poisonTargetId: '30');
    engine.powerPiper('26', ['06', '09', '11']);
    expect(engine.players['06']!.isCharmed, isTrue);
    expect(engine.players['09']!.isCharmed, isTrue);
    expect(engine.players['11']!.isCharmed, isTrue);

    engine.powerRaven('17', '19');
    expect(engine.ravenAccusedId, equals('19'));

    engine.resolveNight();

    expect(engine.players['08']!.isAlive, isTrue);
    expect(engine.players['08']!.lives, equals(1));

    expect(engine.players['01']!.isAlive, isFalse);

    expect(engine.players['20']!.isAlive, isFalse);

    expect(engine.players['30']!.isAlive, isFalse);

    expect(engine.currentNight, equals(2));
  });
}
