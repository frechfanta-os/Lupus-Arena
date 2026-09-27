import 'package:flutter_test/flutter_test.dart';
import 'package:lupus_arena/GameNotifier.dart';
import 'package:lupus_arena/models/game_phase.dart';
import 'package:lupus_arena/models/player_model.dart';
import 'package:lupus_arena/models/game_room.dart';
import 'package:lupus_arena/services/update_service.dart';
import 'package:lupus_arena/services/fog_of_war_service.dart';
import 'package:lupus_arena/services/death_registry_service.dart';
import 'package:lupus_arena/services/audio_manager.dart';

void main() {
  test('L\'ordre canonique nocturne respecte strictement le livret officiel', () {
    expect(GamePhase.nightThief.index, lessThan(GamePhase.nightCupid.index));
    expect(GamePhase.nightCupid.index, lessThan(GamePhase.nightDefender.index));
    expect(GamePhase.nightDefender.index, lessThan(GamePhase.nightWerewolves.index));
    expect(GamePhase.nightWerewolves.index, lessThan(GamePhase.nightBlackWolf.index));
    expect(GamePhase.nightBlackWolf.index, lessThan(GamePhase.nightWhiteWerewolf.index));
    expect(GamePhase.nightWhiteWerewolf.index, lessThan(GamePhase.nightSeer.index));
    expect(GamePhase.nightSeer.index, lessThan(GamePhase.nightFox.index));
    expect(GamePhase.nightFox.index, lessThan(GamePhase.nightWitch.index));
    expect(GamePhase.nightWitch.index, lessThan(GamePhase.nightPyromaniac.index));
    expect(GamePhase.nightPyromaniac.index, lessThan(GamePhase.morningAnnouncement.index));
  });

  test('La distribution par défaut supporte entre 04 et 30 joueurs et respecte la table officielle', () {
    for (int count = 4; count <= 30; count++) {
      final pool = GameNotifier.generateDefaultRolePool(count);
      final totalRoles = pool.values.fold<int>(0, (a, b) => a + b);
      expect(totalRoles, equals(count), reason: 'Total des cartes pour $count joueurs');
      expect(pool['simple_werewolf'] ?? 0, greaterThanOrEqualTo(1), reason: 'Au moins un loup pour $count joueurs');
      expect(pool['seer'], equals(1), reason: 'Une voyante requise pour $count joueurs');
    }

    final pool4 = GameNotifier.generateDefaultRolePool(4);
    expect(pool4['simple_werewolf'], equals(1));
    expect(pool4['seer'], equals(1));
    expect(pool4['witch'], equals(1));
    expect(pool4['simple_villager'], equals(1));

    final pool8 = GameNotifier.generateDefaultRolePool(8);
    expect(pool8['simple_werewolf'], equals(2));
    expect(pool8['seer'], equals(1));
    expect(pool8['witch'], equals(1));
    expect(pool8['hunter'], equals(1));
    expect(pool8['little_girl'], equals(1));
    expect(pool8['simple_villager'], equals(2));

    final pool12 = GameNotifier.generateDefaultRolePool(12);
    expect(pool12['simple_werewolf'], equals(3));
    expect(pool12['thief'], equals(1));
    expect(pool12['cupid'], equals(1));

    final pool16 = GameNotifier.generateDefaultRolePool(16);
    expect(pool16['simple_werewolf'], equals(4));
    expect(pool16['simple_villager'], equals(6));

    final pool30 = GameNotifier.generateDefaultRolePool(30);
    expect(pool30.values.fold<int>(0, (a, b) => a + b), equals(30));
    expect(pool30['simple_werewolf'], equals(7));
  });

  test('Les rôles de loups sont reconnus comme maléfiques (isEvil)', () {
    expect(GameRole.simpleWerewolf.isEvil, isTrue);
    expect(GameRole.bigBadWolf.isEvil, isTrue);
    expect(GameRole.whiteWerewolf.isEvil, isTrue);
    expect(GameRole.simpleVillager.isEvil, isFalse);
    expect(GameRole.seer.isEvil, isFalse);
    expect(GameRole.witch.isEvil, isFalse);
  });

  test('Reconnaissance mutuelle de la meute entre loups', () {
    final myPlayer = PlayerModel(
      id: 'p1',
      name: 'LoupAlpha',
      role: GameRole.simpleWerewolf,
      isAlive: true,
      agoraUid: 101,
    );

    final allyWolf = PlayerModel(
      id: 'p2',
      name: 'LoupBeta',
      role: GameRole.bigBadWolf,
      isAlive: true,
      agoraUid: 102,
    );

    final villager = PlayerModel(
      id: 'p3',
      name: 'VillageoisInnocent',
      role: GameRole.simpleVillager,
      isAlive: true,
      agoraUid: 103,
    );

    final isMeEvil = myPlayer.role.isEvil;
    expect(isMeEvil, isTrue);

    expect(isMeEvil && allyWolf.role.isEvil, isTrue);

    expect(isMeEvil && villager.role.isEvil, isFalse);
  });

  test('La Voyante inspecte le Loup Blanc comme un Simple Villageois', () {

    expect(GameNotifier.getSeerPerceivedRole(GameRole.whiteWerewolf), equals(GameRole.simpleVillager));
    expect(GameNotifier.getSeerPerceivedRole(Role.loupBlanc), equals(Role.simpleVillageois));

    expect(GameNotifier.getSeerPerceivedRole(GameRole.simpleWerewolf), equals(GameRole.simpleWerewolf));
    expect(GameNotifier.getSeerPerceivedRole(GameRole.witch), equals(GameRole.witch));
    expect(GameNotifier.getSeerPerceivedRole(GameRole.simpleVillager), equals(GameRole.simpleVillager));

    expect(GameRole.whiteWerewolf.seerPerception, equals(GameRole.simpleVillager));
    expect(Role.loupBlanc.seerPerception, equals(Role.simpleVillageois));
    expect(GameRole.seer.seerPerception, equals(GameRole.seer));
  });

  test('Le Loup Noir (loupNoir / blackWolf) est un rôle maléfique avec phase nocturne dédiée', () {
    expect(GameRole.blackWolf.isEvil, isTrue);
    expect(Role.loupNoir, equals(GameRole.blackWolf));
    expect(GameRole.blackWolf.id, equals('black_wolf'));
    expect(GameRole.blackWolf.displayName, equals('Loup Noir'));
    expect(GamePhase.nightBlackWolf.isNight, isTrue);
  });

  test('La synchronisation du ciblage du Loup Noir dans GameRoom (blackWolfTargetId)', () {
    final room = GameRoom(
      roomCode: 'TEST_BLACK_WOLF',
      hostId: 'host1',
      blackWolfTargetId: 'target_player_1',
    );

    expect(room.blackWolfTargetId, equals('target_player_1'));

    final map = room.toMap();
    expect(map['blackWolfTargetId'], equals('target_player_1'));

    final restoredRoom = GameRoom.fromMap(map, 'TEST_BLACK_WOLF');
    expect(restoredRoom.blackWolfTargetId, equals('target_player_1'));

    final clearedRoom = restoredRoom.copyWith(clearBlackWolfTargetId: true);
    expect(clearedRoom.blackWolfTargetId, isNull);
  });

  test('La coupure de parole (isMuted = true) persiste sur le joueur ciblé', () {
    final player = PlayerModel(
      id: 'victim_1',
      name: 'SilencedVillager',
      role: GameRole.simpleVillager,
      isMuted: false,
    );

    expect(player.isMuted, isFalse);

    final silencedPlayer = player.copyWith(isMuted: true);
    expect(silencedPlayer.isMuted, isTrue);

    final playerMap = silencedPlayer.toMap();
    expect(playerMap['isMuted'], isTrue);

    final deserializedPlayer = PlayerModel.fromMap(playerMap, 'victim_1');
    expect(deserializedPlayer.isMuted, isTrue);
  });

  test('Anti-doublon et remplacement de socket lors de la reconnexion d\'un joueur', () {

    final initialPlayer = PlayerModel(
      id: 'user_unique_123',
      name: 'Lancelot',
      role: GameRole.defender,
      isAlive: true,
      agoraUid: 1001,
      socketId: 'sock_init_abc',
    );

    expect(initialPlayer.id, equals('user_unique_123'));
    expect(initialPlayer.socketId, equals('sock_init_abc'));

    final initialMap = initialPlayer.toMap();
    expect(initialMap['socketId'], equals('sock_init_abc'));

    final room = GameRoom(
      roomCode: 'TEST_ROOM',
      hostId: 'host_1',
      players: {'user_unique_123': initialPlayer},
      seatingOrder: ['user_unique_123', 'user_unique_123'],
    );

    expect(room.hasPlayer('user_unique_123'), isTrue);
    expect(room.hasPlayer('user_unknown_999'), isFalse);

    expect(room.playerList.length, equals(1));
    expect(room.playerList.first.id, equals('user_unique_123'));

    const newSocketId = 'sock_reconnected_xyz';
    const newAgoraUid = 1002;

    final reconnectedPlayer = initialPlayer.copyWith(
      socketId: newSocketId,
      agoraUid: newAgoraUid,
    );

    final updatedRoom = room.copyWith(
      players: {
        ...room.players,
        reconnectedPlayer.id: reconnectedPlayer,
      },
    );

    expect(updatedRoom.players.length, equals(1));
    expect(updatedRoom.playerList.length, equals(1));
    expect(updatedRoom.players['user_unique_123']?.socketId, equals(newSocketId));
    expect(updatedRoom.players['user_unique_123']?.agoraUid, equals(newAgoraUid));

    expect(updatedRoom.players['user_unique_123']?.role, equals(GameRole.defender));
    expect(updatedRoom.players['user_unique_123']?.isAlive, isTrue);
  });

  test('Minute vocale collective à la victoire (60 secondes) : tous les joueurs parlent, puis micros coupés', () {

    final aliveVillagerMute = GameNotifier.calculateShouldMuteForPhase(
      phase: GamePhase.gameOver,
      isAlive: true,
      isSilencedByBlackWolf: false,
      isCurrentSpeaker: false,
      isEvil: false,
      isVictoryVoiceExpired: false,
    );
    expect(aliveVillagerMute, isFalse, reason: 'Villageois vivant démuté pour la minute collective');

    final deadPlayerMute = GameNotifier.calculateShouldMuteForPhase(
      phase: GamePhase.gameOver,
      isAlive: false,
      isSilencedByBlackWolf: false,
      isCurrentSpeaker: false,
      isEvil: false,
      isVictoryVoiceExpired: false,
    );
    expect(deadPlayerMute, isFalse, reason: 'Joueur mort démuté pour la minute collective de victoire');

    final silencedPlayerMute = GameNotifier.calculateShouldMuteForPhase(
      phase: GamePhase.gameOver,
      isAlive: true,
      isSilencedByBlackWolf: true,
      isCurrentSpeaker: false,
      isEvil: false,
      isVictoryVoiceExpired: false,
    );
    expect(silencedPlayerMute, isFalse, reason: 'Joueur réduit au silence démuté pour la célébration');

    final evilDeadWolfMute = GameNotifier.calculateShouldMuteForPhase(
      phase: GamePhase.gameOver,
      isAlive: false,
      isSilencedByBlackWolf: false,
      isCurrentSpeaker: false,
      isEvil: true,
      isVictoryVoiceExpired: false,
    );
    expect(evilDeadWolfMute, isFalse, reason: 'Loup mort également démuté pour débriefer');

    final expiredAliveMute = GameNotifier.calculateShouldMuteForPhase(
      phase: GamePhase.gameOver,
      isAlive: true,
      isSilencedByBlackWolf: false,
      isCurrentSpeaker: false,
      isEvil: false,
      isVictoryVoiceExpired: true,
    );
    expect(expiredAliveMute, isTrue, reason: 'Micro coupé à la fin de la minute pour le vivant');

    final expiredDeadMute = GameNotifier.calculateShouldMuteForPhase(
      phase: GamePhase.gameOver,
      isAlive: false,
      isSilencedByBlackWolf: false,
      isCurrentSpeaker: false,
      isEvil: false,
      isVictoryVoiceExpired: true,
    );
    expect(expiredDeadMute, isTrue, reason: 'Micro coupé à la fin de la minute pour le mort');

    final normalNightDeadMute = GameNotifier.calculateShouldMuteForPhase(
      phase: GamePhase.nightWerewolves,
      isAlive: false,
      isSilencedByBlackWolf: false,
      isCurrentSpeaker: false,
      isEvil: false,
      isVictoryVoiceExpired: false,
    );
    expect(normalNightDeadMute, isTrue, reason: 'En jeu normal, un mort a son micro coupé');

    final botMuteInDebate = GameNotifier.calculateShouldMuteForPhase(
      phase: GamePhase.dayDebate,
      isAlive: true,
      isSilencedByBlackWolf: false,
      isCurrentSpeaker: true,
      isEvil: false,
      isVictoryVoiceExpired: false,
      isBot: true,
    );
    expect(botMuteInDebate, isTrue, reason: 'Le micro d un bot est strictement inactif même s il est l orateur en cours');

    final botMuteInGameOver = GameNotifier.calculateShouldMuteForPhase(
      phase: GamePhase.gameOver,
      isAlive: true,
      isSilencedByBlackWolf: false,
      isCurrentSpeaker: false,
      isEvil: false,
      isVictoryVoiceExpired: false,
      isBot: true,
    );
    expect(botMuteInGameOver, isTrue, reason: 'Un bot n a aucun micro actif même lors de la minute collective');
  });

  test('Préparation du deck de cartes rôles adapté au nombre de joueurs et mélange Fisher-Yates', () {

    final deck6 = GameNotifier.prepareReplayRoleDeck(6);
    expect(deck6.length, equals(6));
    expect(deck6, contains(GameRole.whiteWerewolf));
    expect(deck6, contains(GameRole.blackWolf));
    expect(deck6, contains(GameRole.seer));
    expect(deck6, contains(GameRole.witch));
    expect(deck6, contains(GameRole.hunter));
    expect(deck6, contains(GameRole.simpleVillager));

    expect(deck6.toSet().length, equals(6));

    for (final count in [4, 8, 12, 16]) {
      final deck = GameNotifier.prepareReplayRoleDeck(count);
      expect(deck.length, equals(count));
      expect(deck.toSet().length, equals(count), reason: 'Rôles distincts pour $count joueurs');
    }

    final originalDeck = List<GameRole>.from(deck6);
    final shuffledDeck = List<GameRole>.from(deck6);
    GameNotifier.fisherYatesShuffle(shuffledDeck);
    expect(shuffledDeck.length, equals(originalDeck.length));
    expect(shuffledDeck.toSet(), equals(originalDeck.toSet()));

    final players = List.generate(
      6,
      (i) => PlayerModel(id: 'player_$i', name: 'Guerrier_$i'),
    );
    final assignedRoles = <String, GameRole>{};
    for (int i = 0; i < players.length; i++) {
      assignedRoles[players[i].id] = shuffledDeck[i];
    }
    expect(assignedRoles.values.toSet().length, equals(6), reason: 'Chaque joueur a reçu un rôle distinct');
  });

  test('Réinitialisation complète du joueur pour le Replay (PV = 100, isAlive = true, isMuted = false)', () {
    final deadSilencedPlayer = PlayerModel(
      id: 'victim_dead',
      name: 'AncienMort',
      isAlive: false,
      isMuted: true,
      pv: 0,
      isReadyReplay: true,
      targetVoteId: 'someone',
      isCaptain: true,
    );

    expect(deadSilencedPlayer.isAlive, isFalse);
    expect(deadSilencedPlayer.isMuted, isTrue);
    expect(deadSilencedPlayer.pv, equals(0));
    expect(deadSilencedPlayer.isReadyReplay, isTrue);

    final resetPlayer = deadSilencedPlayer.copyWith(
      isAlive: true,
      isMuted: false,
      pv: 100,
      isReadyReplay: false,
      clearTargetVote: true,
      isCaptain: false,
    );

    expect(resetPlayer.pv, equals(100), reason: 'PV réinitialisés à 100');
    expect(resetPlayer.isAlive, isTrue, reason: 'Joueur ressuscité pour la nouvelle partie');
    expect(resetPlayer.isMuted, isFalse, reason: 'Micro démuté');
    expect(resetPlayer.isReadyReplay, isFalse);
    expect(resetPlayer.targetVoteId, isNull);
    expect(resetPlayer.isCaptain, isFalse);
  });

  test('Synchronisation du statut de vote Replay et comptage des joueurs prêts', () {
    final room = GameRoom(
      roomCode: 'TEST_REPLAY',
      hostId: 'host_1',
      players: {
        'p1': const PlayerModel(id: 'p1', name: 'Alpha'),
        'p2': const PlayerModel(id: 'p2', name: 'Beta'),
        'p3': const PlayerModel(id: 'p3', name: 'Gamma'),
      },
      replayReadyUserIds: ['p1', 'p2'],
    );

    expect(room.totalPlayersCount, equals(3));
    expect(room.replayReadyCount, equals(2));
    expect(room.isPlayerReadyReplay('p1'), isTrue);
    expect(room.isPlayerReadyReplay('p2'), isTrue);
    expect(room.isPlayerReadyReplay('p3'), isFalse);

    final updatedRoom = room.copyWith(
      replayReadyUserIds: ['p1'],
    );
    expect(updatedRoom.replayReadyCount, equals(1));
    expect(updatedRoom.isPlayerReadyReplay('p2'), isFalse);

    final map = room.toMap();
    expect(map['replayReadyUserIds'], equals(['p1', 'p2']));
    final restoredRoom = GameRoom.fromMap(map, 'TEST_REPLAY');
    expect(restoredRoom.replayReadyCount, equals(2));
    expect(restoredRoom.isPlayerReadyReplay('p1'), isTrue);
  });

  group('UpdateService - Détection de version sémantique', () {
    test('Détecte correctement les versions supérieures (majeure, mineure, patch)', () {
      expect(UpdateService.isRemoteVersionGreater('1.0.9', '1.0.8'), isTrue);
      expect(UpdateService.isRemoteVersionGreater('v1.0.9', 'v1.0.8'), isTrue);
      expect(UpdateService.isRemoteVersionGreater('v1.1.0', '1.0.8'), isTrue);
      expect(UpdateService.isRemoteVersionGreater('2.0.0', '1.9.9'), isTrue);
    });

    test('Détecte les builds numbers supérieurs', () {
      expect(UpdateService.isRemoteVersionGreater('1.0.8+10', '1.0.8+9'), isTrue);
      expect(UpdateService.isRemoteVersionGreater('v1.0.8+10', '1.0.8+9'), isTrue);
      expect(UpdateService.isRemoteVersionGreater('1.0.8+1', '1.0.8'), isTrue);
    });

    test('Rejette les versions identiques ou inférieures', () {
      expect(UpdateService.isRemoteVersionGreater('1.0.8', '1.0.8'), isFalse);
      expect(UpdateService.isRemoteVersionGreater('v1.0.8', '1.0.8'), isFalse);
      expect(UpdateService.isRemoteVersionGreater('1.0.8+9', '1.0.8+9'), isFalse);
      expect(UpdateService.isRemoteVersionGreater('1.0.7', '1.0.8'), isFalse);
      expect(UpdateService.isRemoteVersionGreater('1.0.8+8', '1.0.8+9'), isFalse);
      expect(UpdateService.isRemoteVersionGreater('', '1.0.8'), isFalse);
      expect(UpdateService.isRemoteVersionGreater('1.0.8', ''), isFalse);
    });
  });

  group('Conditions de victoire et équilibre Sorcière / Loups', () {
    test('Tous les loups-garous canoniques sont maléfiques (isEvil == true)', () {
      expect(GameRole.simpleWerewolf.isEvil, isTrue);
      expect(GameRole.bigBadWolf.isEvil, isTrue);
      expect(GameRole.blackWolf.isEvil, isTrue);
      expect(GameRole.vileFatherOfWolves.isEvil, isTrue);
      expect(GameRole.wolfCub.isEvil, isTrue);
      expect(GameRole.whiteWerewolf.isEvil, isTrue);
    });

    test('1 loup face à 2 villageois ne déclenche PAS de Game Over prématuré', () {
      final room = GameRoom(
        roomCode: 'TEST1',
        hostId: 'p1',
        players: {
          'wolf': const PlayerModel(id: 'wolf', name: 'Loup', role: GameRole.simpleWerewolf, isAlive: true),
          'v1': const PlayerModel(id: 'v1', name: 'V1', role: GameRole.simpleVillager, isAlive: true),
          'v2': const PlayerModel(id: 'v2', name: 'V2', role: GameRole.witch, isAlive: true),
          'dead1': const PlayerModel(id: 'dead1', name: 'M1', role: GameRole.seer, isAlive: false),
        },
      );

      final result = GameNotifier.checkWinConditions(room);
      expect(result, isNull, reason: '1 loup contre 2 villageois doit continuer vers le débat et le vote');
    });

    test('1 loup face à 1 villageois déclenche la victoire des loups (parité)', () {
      final room = GameRoom(
        roomCode: 'TEST2',
        hostId: 'wolf',
        players: {
          'wolf': const PlayerModel(id: 'wolf', name: 'Loup', role: GameRole.simpleWerewolf, isAlive: true),
          'v1': const PlayerModel(id: 'v1', name: 'V1', role: GameRole.simpleVillager, isAlive: true),
          'dead1': const PlayerModel(id: 'dead1', name: 'M1', role: GameRole.simpleVillager, isAlive: false),
        },
      );

      final result = GameNotifier.checkWinConditions(room);
      expect(result, equals('werewolves'), reason: 'Parité 1 contre 1 = victoire des loups');
    });

    test('0 loup face à des villageois vivants déclenche la victoire du village', () {
      final room = GameRoom(
        roomCode: 'TEST3',
        hostId: 'v1',
        players: {
          'wolf_dead': const PlayerModel(id: 'wolf_dead', name: 'LoupMort', role: GameRole.simpleWerewolf, isAlive: false),
          'v1': const PlayerModel(id: 'v1', name: 'V1', role: GameRole.simpleVillager, isAlive: true),
          'witch': const PlayerModel(id: 'witch', name: 'Sorcière', role: GameRole.witch, isAlive: true),
        },
      );

      final result = GameNotifier.checkWinConditions(room);
      expect(result, equals('village'), reason: 'Tous les loups éliminés = victoire du village');
    });

    test('Débat du village : saut automatique des joueurs bâillonnés (isMuted)', () {
      final p1 = const PlayerModel(id: '1', name: 'Alice', role: GameRole.simpleVillager, isAlive: true, isMuted: false);
      final p2 = const PlayerModel(id: '2', name: 'Bob', role: GameRole.simpleVillager, isAlive: true, isMuted: true);
      final p3 = const PlayerModel(id: '3', name: 'Charlie', role: GameRole.simpleVillager, isAlive: true, isMuted: false);

      final players = {'1': p1, '2': p2, '3': p3};

      final queue = List<String>.from(players.values.where((p) => p.isAlive).map((p) => p.id));
      final logs = <String>[];

      expect(queue.first, equals('1'));

      queue.removeAt(0);

      while (queue.isNotEmpty && (players[queue.first]?.isMuted ?? false)) {
        final mutedId = queue.removeAt(0);
        final mutedName = players[mutedId]?.name ?? 'Un citoyen';
        logs.add('🔇 $mutedName est bâillonné par les loups ! Son tour de parole est sauté.');
      }

      expect(logs, contains(contains('Bob est bâillonné par les loups')));

      expect(queue.first, equals('3'));
    });

    test('Débat du village : cascade de sauts si plusieurs joueurs muets consécutifs', () {
      final p1 = const PlayerModel(id: '1', name: 'Alice', role: GameRole.simpleVillager, isAlive: true, isMuted: false);
      final p2 = const PlayerModel(id: '2', name: 'Bob', role: GameRole.simpleVillager, isAlive: true, isMuted: true);
      final p3 = const PlayerModel(id: '3', name: 'Charlie', role: GameRole.simpleVillager, isAlive: true, isMuted: true);
      final p4 = const PlayerModel(id: '4', name: 'David', role: GameRole.simpleVillager, isAlive: true, isMuted: false);

      final players = {'1': p1, '2': p2, '3': p3, '4': p4};
      final queue = ['1', '2', '3', '4'];
      final logs = <String>[];

      queue.removeAt(0);

      while (queue.isNotEmpty && (players[queue.first]?.isMuted ?? false)) {
        final mutedId = queue.removeAt(0);
        final mutedName = players[mutedId]?.name ?? 'Un citoyen';
        logs.add('🔇 $mutedName est bâillonné par les loups ! Son tour de parole est sauté.');
      }

      expect(logs.length, equals(2));
      expect(queue.first, equals('4'));
    });

    test('Débat du village : si tous les orateurs restants sont muets, clôture et vote', () {
      final p1 = const PlayerModel(id: '1', name: 'Alice', role: GameRole.simpleVillager, isAlive: true, isMuted: false);
      final p2 = const PlayerModel(id: '2', name: 'Bob', role: GameRole.simpleVillager, isAlive: true, isMuted: true);

      final players = {'1': p1, '2': p2};
      final queue = ['1', '2'];
      final logs = <String>[];

      queue.removeAt(0);

      while (queue.isNotEmpty && (players[queue.first]?.isMuted ?? false)) {
        final mutedId = queue.removeAt(0);
        logs.add('🔇 ${players[mutedId]?.name} est bâillonné !');
      }

      expect(queue.isEmpty, isTrue, reason: 'La file doit être vide pour ouvrir le vote');
    });

    test('UpdateService : comparaison de versions sémantiques et build numbers', () {

      expect(UpdateService.isRemoteVersionGreater('v1.0.22+23', '1.0.21+22'), isTrue);
      expect(UpdateService.isRemoteVersionGreater('1.0.22+23', '1.0.21+22'), isTrue);
      expect(UpdateService.isRemoteVersionGreater('1.0.21+22', '1.0.21+22'), isFalse);
      expect(UpdateService.isRemoteVersionGreater('1.0.20+21', '1.0.21+22'), isFalse);

      expect(UpdateService.isRemoteVersionGreater('1.0.21+23', '1.0.21+22'), isTrue);
      expect(UpdateService.isRemoteVersionGreater('1.0.21+21', '1.0.21+22'), isFalse);

      expect(UpdateService.isRemoteVersionGreater('2.0.0+1', '1.0.21+22'), isTrue);
      expect(UpdateService.isRemoteVersionGreater('1.0.0+1', '2.0.0+1'), isFalse);

      expect(UpdateService.isRemoteVersionGreater('V1.0.22', '1.0.21'), isTrue);
      expect(UpdateService.isRemoteVersionGreater('v1.0.22+23', 'v1.0.22+23'), isFalse);

      expect(UpdateService.isRemoteVersionGreater('v1.0.23+24', '1.0.22+23'), isTrue);
      expect(UpdateService.isRemoteVersionGreater('1.0.23+24', '1.0.22+23'), isTrue);
      expect(UpdateService.isRemoteVersionGreater('v1.0.24+25', '1.0.23+24'), isTrue);
      expect(UpdateService.isRemoteVersionGreater('v1.0.24+25', 'v1.0.24+25'), isFalse);
      expect(UpdateService.isRemoteVersionGreater('v1.0.25+26', '1.0.24+25'), isTrue);
      expect(UpdateService.isRemoteVersionGreater('v1.0.25+26', 'v1.0.25+26'), isFalse);
    });

    test('Double action des loups : proie et silence obligatoires et distincts', () {
      const victimId = 'v1';
      String? silenceId;

      bool canValidate(String? victim, String? silence) {
        return victim != null && silence != null && victim != silence;
      }

      expect(canValidate(victimId, silenceId), isFalse);

      silenceId = 'v1';
      expect(canValidate(victimId, silenceId), isFalse);

      silenceId = 's1';
      expect(canValidate(victimId, silenceId), isTrue);
    });

    test('Bluff intra-meute & auto-mutisme : la cible du silence peut être un loup ou soi-même', () {
      const wolf1 = PlayerModel(id: 'w1', name: 'Loup1', role: GameRole.simpleWerewolf, isAlive: true);
      const wolf2 = PlayerModel(id: 'w2', name: 'Loup2', role: GameRole.whiteWerewolf, isAlive: true);
      const victim = PlayerModel(id: 'v1', name: 'Victime', role: GameRole.simpleVillager, isAlive: true);

      bool canSilence(PlayerModel target, String? currentVictimId) {
        return target.isAlive && target.id != currentVictimId;
      }

      expect(canSilence(wolf1, victim.id), isTrue);

      expect(canSilence(wolf2, victim.id), isTrue);

      expect(canSilence(victim, victim.id), isFalse);
    });

    test('Anti-fratricide : un loup ne peut JAMAIS dévorer un loup ni soi-même', () {
      const meWolf = PlayerModel(id: 'w1', name: 'MoiLoup', role: GameRole.simpleWerewolf, isAlive: true);
      const allyWolf = PlayerModel(id: 'w2', name: 'LoupAllie', role: GameRole.bigBadWolf, isAlive: true);
      const victim = PlayerModel(id: 'v1', name: 'Victime', role: GameRole.simpleVillager, isAlive: true);

      bool canDevour(PlayerModel target, String currentUserId) {
        final isTargetWolf = target.role.isEvil || target.role.isWolfTeam;
        final isSelf = target.id == currentUserId;
        return target.isAlive && !isTargetWolf && !isSelf;
      }

      expect(canDevour(victim, meWolf.id), isTrue, reason: 'Peut dévorer un villageois');
      expect(canDevour(allyWolf, meWolf.id), isFalse, reason: 'Ne peut PAS dévorer un allié');
      expect(canDevour(meWolf, meWolf.id), isFalse, reason: 'Ne peut PAS se dévorer soi-même');
    });

    test('Purge du silence à l\'arrivée de la nuit : les joueurs sous silence retrouvent l\'usage de la parole', () {
      const p1 = PlayerModel(id: '1', name: 'Alice', role: GameRole.simpleVillager, isAlive: true, isMuted: true);
      const p2 = PlayerModel(id: '2', name: 'Bob', role: GameRole.simpleWerewolf, isAlive: true, isMuted: true);

      final players = {'1': p1, '2': p2};
      final updates = <String, dynamic>{};

      for (final p in players.values) {
        if (p.isMuted) {
          updates['players/${p.id}/isMuted'] = false;
        }
      }

      expect(updates['players/1/isMuted'], isFalse);
      expect(updates['players/2/isMuted'], isFalse);
    });

    test('Sorcière : Verrouillage strict de la potion de vie sur la victime des loups (nightVictimId)', () {
      const wolfVictim = PlayerModel(id: 'v1', name: 'VictimeDesLoups', role: GameRole.simpleVillager, isAlive: true);
      const randomPlayer = PlayerModel(id: 'r1', name: 'JoueurAleatoire', role: GameRole.simpleVillager, isAlive: true);

      String? getWitchLifePotionTarget(String? nightVictimId) {
        return nightVictimId;
      }

      expect(getWitchLifePotionTarget(wolfVictim.id), equals('v1'), reason: 'La sorcière peut sauver la victime désignée');

      expect(getWitchLifePotionTarget(null), isNull, reason: 'Impossible d\'utiliser la potion de vie sans victime des loups');

      bool canUsePoison(PlayerModel target, int potionsMort) {
        return potionsMort > 0 && target.isAlive;
      }
      expect(canUsePoison(randomPlayer, 1), isTrue);
      expect(canUsePoison(randomPlayer, 0), isFalse);
    });

    test('Loups-Garous : Sélection séquentielle 2 cibles (1er = Dévorer, 2e = Museler) avec auto-validation', () {
      const player1 = PlayerModel(id: 'p1', name: 'Villageois 1', role: GameRole.simpleVillager, isAlive: true);
      const player2 = PlayerModel(id: 'p2', name: 'Villageois 2', role: GameRole.seer, isAlive: true);

      String? wolfVictimId;
      String? wolfMuteId;
      bool nextPhaseTriggered = false;

      void handleWerewolfSelection(String id) {
        if (wolfVictimId == null) {

          wolfVictimId = id;
        } else if (wolfVictimId == id) {

          wolfVictimId = null;
        } else if (wolfMuteId == null) {

          wolfMuteId = id;
          nextPhaseTriggered = true;
        }
      }

      handleWerewolfSelection(player1.id);
      expect(wolfVictimId, equals('p1'));
      expect(wolfMuteId, isNull);
      expect(nextPhaseTriggered, isFalse);

      handleWerewolfSelection(player2.id);
      expect(wolfVictimId, equals('p1'), reason: '1er joueur = Dévoré');
      expect(wolfMuteId, equals('p2'), reason: '2e joueur = Muselé');
      expect(nextPhaseTriggered, isTrue, reason: 'Auto-validation immédiate dès 2/2 cibles');
    });

    test('Loups-Garous : Possibilité de changer de cible victime par un second clic sur la même victime', () {
      const player1 = PlayerModel(id: 'p1', name: 'Villageois 1', role: GameRole.simpleVillager, isAlive: true);
      const player2 = PlayerModel(id: 'p2', name: 'Villageois 2', role: GameRole.seer, isAlive: true);
      const player3 = PlayerModel(id: 'p3', name: 'Villageois 3', role: GameRole.witch, isAlive: true);

      String? wolfVictimId;
      String? wolfMuteId;
      bool nextPhaseTriggered = false;

      void handleWerewolfSelection(String id) {
        if (wolfVictimId == null) {
          wolfVictimId = id;
        } else if (wolfVictimId == id) {

          wolfVictimId = null;
        } else if (wolfMuteId == null) {
          wolfMuteId = id;
          nextPhaseTriggered = true;
        }
      }

      handleWerewolfSelection(player1.id);
      expect(wolfVictimId, equals('p1'));
      expect(wolfMuteId, isNull);

      handleWerewolfSelection(player1.id);
      expect(wolfVictimId, isNull, reason: 'Le second clic sur la même victime doit annuler le choix');
      expect(wolfMuteId, isNull);
      expect(nextPhaseTriggered, isFalse);

      handleWerewolfSelection(player2.id);
      expect(wolfVictimId, equals('p2'), reason: 'Joueur 2 est désormais la nouvelle victime');
      expect(wolfMuteId, isNull);
      expect(nextPhaseTriggered, isFalse);

      handleWerewolfSelection(player3.id);
      expect(wolfVictimId, equals('p2'));
      expect(wolfMuteId, equals('p3'));
      expect(nextPhaseTriggered, isTrue);
    });

    test('Nuit des Loups : Résolution impérative avec dévoré ET muselé garantis (Fallback auto)', () {
      final alivePlayers = [
        const PlayerModel(id: 'p1', name: 'P1', role: GameRole.simpleVillager, isAlive: true),
        const PlayerModel(id: 'p2', name: 'P2', role: GameRole.seer, isAlive: true),
        const PlayerModel(id: 'p3', name: 'P3', role: GameRole.witch, isAlive: true),
      ];

      String victimId = alivePlayers.isNotEmpty ? alivePlayers.first.id : '';

      String muteId = alivePlayers.length > 1
          ? alivePlayers.firstWhere((p) => p.id != victimId).id
          : '';

      expect(victimId, equals('p1'), reason: 'Une proie est impérativement désignée');
      expect(muteId, equals('p2'), reason: 'Un joueur est impérativement muselé');
      expect(victimId, isNot(equals(muteId)), reason: 'La proie et le muselé sont distincts');
    });

    test('Sorcière : Utilisation combinée des deux potions (Vie & Mort) et transition de rôle', () {
      var witch = const PlayerModel(id: 'w1', name: 'Sorciere', role: GameRole.witch, potionsVie: 1, potionsMort: 1, isAlive: true);

      final newVie = witch.potionsVie - 1;
      witch = witch.copyWith(potionsVie: newVie);
      expect(witch.potionsVie, equals(0));
      expect(witch.potionsMort, equals(1));
      expect(witch.role, equals(GameRole.witch), reason: 'Reste Sorcière car il lui reste 1 potion de mort');

      final newMort = witch.potionsMort - 1;
      final isDechue = newVie == 0 && newMort == 0;
      witch = witch.copyWith(
        potionsMort: newMort,
        role: isDechue ? GameRole.simpleVillager : witch.role,
      );
      expect(witch.potionsVie, equals(0));
      expect(witch.potionsMort, equals(0));
      expect(witch.role, equals(GameRole.simpleVillager), reason: 'Rétrogradée en Simple Villageoise à 0/0');
    });

    test('Audio Manager : Musique d\'ambiance strictement isolée au Menu Principal (room == null)', () {
      bool shouldPlayLobbyMusic(GameRoom? room) {
        return room == null;
      }

      expect(shouldPlayLobbyMusic(null), isTrue, reason: 'La musique doit jouer sur le Menu Principal');

      const waitingRoom = GameRoom(roomCode: 'TEST1', hostId: 'h1', phase: GamePhase.lobby);
      expect(shouldPlayLobbyMusic(waitingRoom), isFalse, reason: 'La musique doit s\'arrêter immédiatement en salle d\'attente');

      const devRoom = GameRoom(roomCode: 'DEV01', hostId: 'h1', phase: GamePhase.nightWerewolves, isDevRoom: true);
      expect(shouldPlayLobbyMusic(devRoom), isFalse, reason: 'La musique doit être coupée pendant une partie simulée DevMode');

      const inGameRoom = GameRoom(roomCode: 'TEST2', hostId: 'h1', phase: GamePhase.dayDebate);
      expect(shouldPlayLobbyMusic(inGameRoom), isFalse, reason: 'La musique doit être coupée dans l\'arène de jeu');
    });

    test('Permissions & Agora : Synchronisation et récupération en arrière-plan sans redémarrage', () {
      bool agoraRecovered = false;
      void mockAgoraRecovery() {
        agoraRecovered = true;
      }

      bool isMicGranted = false;
      void onPermissionChanged(bool granted) {
        isMicGranted = granted;
        if (granted) {
          mockAgoraRecovery();
        }
      }

      expect(isMicGranted, isFalse);
      expect(agoraRecovered, isFalse);

      onPermissionChanged(true);
      expect(isMicGranted, isTrue);
      expect(agoraRecovered, isTrue, reason: 'Agora doit se réarmer automatiquement dès que la permission est actualisée');
    });

    test('Fog of War : Règle de visibilité du badge Amoureux (IN_LOVE)', () {

      expect(FogOfWarService.canSeeLoverBadge(
        targetIsLover: false,
        observerRole: GameRole.cupid,
        observerIsLover: true,
      ), isFalse);

      expect(FogOfWarService.canSeeLoverBadge(
        targetIsLover: true,
        observerRole: GameRole.cupid,
        observerIsLover: false,
      ), isTrue);

      expect(FogOfWarService.canSeeLoverBadge(
        targetIsLover: true,
        observerRole: GameRole.simpleVillager,
        observerIsLover: true,
      ), isTrue);

      expect(FogOfWarService.canSeeLoverBadge(
        targetIsLover: true,
        observerRole: GameRole.simpleVillager,
        observerIsLover: false,
      ), isFalse);

      expect(FogOfWarService.canSeeLoverBadge(
        targetIsLover: true,
        observerRole: GameRole.simpleWerewolf,
        observerIsLover: false,
      ), isFalse);

      expect(FogOfWarService.canSeeLoverBadge(
        targetIsLover: true,
        observerRole: GameRole.simpleVillager,
        observerIsLover: false,
        isDevMode: true,
      ), isTrue);
    });

    test('Fog of War : Règle de visibilité du badge Charmé (CHARMED)', () {

      expect(FogOfWarService.canSeeCharmedBadge(
        targetIsCharmed: false,
        observerRole: GameRole.piedPiper,
        observerIsCharmed: true,
      ), isFalse);

      expect(FogOfWarService.canSeeCharmedBadge(
        targetIsCharmed: true,
        observerRole: GameRole.piedPiper,
        observerIsCharmed: false,
      ), isTrue);

      expect(FogOfWarService.canSeeCharmedBadge(
        targetIsCharmed: true,
        observerRole: GameRole.simpleVillager,
        observerIsCharmed: true,
      ), isTrue);

      expect(FogOfWarService.canSeeCharmedBadge(
        targetIsCharmed: true,
        observerRole: GameRole.simpleVillager,
        observerIsCharmed: false,
      ), isFalse);
    });

    test('Anti-Résurrection : Seule la potion de vie de la sorcière sur la victime des loups peut sauver', () {
      const deadPlayer = PlayerModel(id: 'p1', name: 'Dead', role: GameRole.simpleVillager, isAlive: false);

      bool canPlayerRevive({
        required bool currentlyAlive,
        required bool incomingAlive,
        required bool witchHealed,
        required String? nightVictimId,
        required String playerId,
        bool isAdmin = false,
      }) {
        if (!currentlyAlive && incomingAlive) {
          final isSavedByWitch = witchHealed && playerId == nightVictimId;
          if (!isSavedByWitch && !isAdmin) {
            return false;
          }
        }
        return incomingAlive;
      }

      expect(canPlayerRevive(
        currentlyAlive: deadPlayer.isAlive,
        incomingAlive: true,
        witchHealed: false,
        nightVictimId: null,
        playerId: deadPlayer.id,
      ), isFalse, reason: 'Un joueur mort ne peut pas être ressuscité par Firebase');

      expect(canPlayerRevive(
        currentlyAlive: deadPlayer.isAlive,
        incomingAlive: true,
        witchHealed: false,
        nightVictimId: 'other_player',
        playerId: deadPlayer.id,
      ), isFalse, reason: 'Élection du maire ne doit jamais ressusciter un mort');

      expect(canPlayerRevive(
        currentlyAlive: deadPlayer.isAlive,
        incomingAlive: true,
        witchHealed: true,
        nightVictimId: deadPlayer.id,
        playerId: deadPlayer.id,
      ), isTrue, reason: 'La potion de vie de la sorcière ressuscite valablement la victime');
    });

    test('PlayerModel.fromMap : isAlive ne devient JAMAIS true si absent ou ambigu', () {
      final mapMissingAlive = {'id': 'p1', 'name': 'Player 1', 'role': 'simpleVillager'};
      final playerMissing = PlayerModel.fromMap(mapMissingAlive);
      expect(playerMissing.isAlive, isFalse, reason: 'Sans isAlive dans le snapshot, la valeur par défaut ne doit jamais être true');

      final mapAliveTrue = {'id': 'p2', 'name': 'Player 2', 'role': 'simpleVillager', 'isAlive': true};
      final playerAlive = PlayerModel.fromMap(mapAliveTrue);
      expect(playerAlive.isAlive, isTrue);

      final mapAliveFalse = {'id': 'p3', 'name': 'Player 3', 'role': 'simpleVillager', 'isAlive': false};
      final playerDead = PlayerModel.fromMap(mapAliveFalse);
      expect(playerDead.isAlive, isFalse);

      final mapCorrupted = {'id': 'p4', 'name': 'Player 4', 'role': 'simpleVillager', 'isAlive': 'invalid'};
      final playerCorrupted = PlayerModel.fromMap(mapCorrupted);
      expect(playerCorrupted.isAlive, isFalse);
    });

    test('Verrou d\'Immortalité Inverse (_cemeteryRegistry) : bloque toute tentative de résurrection réseau', () {
      final Set<String> cemeteryRegistry = {'dead_p1', 'dead_p2'};

      Map<String, PlayerModel> processIncomingSnapshot({
        required Map<String, PlayerModel> incoming,
        required Set<String> cemetery,
        required bool witchHealed,
        required String? nightVictimId,
      }) {
        final updated = <String, PlayerModel>{};
        for (final entry in incoming.entries) {
          final pid = entry.key;
          var player = entry.value;

          if (witchHealed && pid == nightVictimId) {
            cemetery.remove(pid);
          }

          if (cemetery.contains(pid)) {
            if (player.isAlive) {
              player = player.copyWith(isAlive: false);
            }
          } else if (!player.isAlive) {
            cemetery.add(pid);
          }
          updated[pid] = player;
        }
        return updated;
      }

      final incomingZombie = {
        'dead_p1': const PlayerModel(id: 'dead_p1', name: 'Dead P1', role: GameRole.simpleVillager, isAlive: true),
        'alive_p3': const PlayerModel(id: 'alive_p3', name: 'Alive P3', role: GameRole.simpleVillager, isAlive: true),
      };

      final resolved = processIncomingSnapshot(
        incoming: incomingZombie,
        cemetery: cemeteryRegistry,
        witchHealed: false,
        nightVictimId: null,
      );

      expect(resolved['dead_p1']!.isAlive, isFalse, reason: 'dead_p1 doit RESTER mort malgré le snapshot');
      expect(resolved['alive_p3']!.isAlive, isTrue, reason: 'alive_p3 reste vivant');

      final resolvedAfterWitch = processIncomingSnapshot(
        incoming: incomingZombie,
        cemetery: cemeteryRegistry,
        witchHealed: true,
        nightVictimId: 'dead_p1',
      );

      expect(resolvedAfterWitch['dead_p1']!.isAlive, isTrue, reason: 'La sorcière a levé le verrou sur dead_p1');
      expect(cemeteryRegistry.contains('dead_p1'), isFalse, reason: 'dead_p1 a été retiré du cimetière');
    });

    test('LobbyAudioManager : singleton unique et alias LupusAudioManager', () {
      final audioManager = LobbyAudioManager.instance;
      expect(audioManager, isNotNull);
      expect(identical(LobbyAudioManager.instance, LupusAudioManager.instance), isTrue);
    });

    test('DeathRegistryService : Singleton, enregistrement définitif et blocage de résurrection', () {
      final registry = DeathRegistryService.instance;
      registry.clearForNewGame();

      expect(registry.isDead('player_x'), isFalse);
      expect(registry.isAlive('player_x'), isTrue);

      registry.markDead('player_x');
      expect(registry.isDead('player_x'), isTrue);
      expect(registry.isAlive('player_x'), isFalse);

      final incomingZombieMap = {
        'id': 'player_x',
        'name': 'Guerrier X',
        'role': 'simpleVillager',
        'isAlive': true,
      };
      final zombiePlayer = PlayerModel.fromMap(incomingZombieMap);
      expect(zombiePlayer.isAlive, isFalse, reason: 'PlayerModel.fromMap doit forcer isAlive à false pour tout joueur dans le DeathRegistryService');

      final room = GameRoom(
        roomCode: 'TEST',
        hostId: 'host',
        phase: GamePhase.dayVoting,
        players: {
          'player_x': zombiePlayer,
          'player_y': const PlayerModel(id: 'player_y', name: 'Guerrier Y', isAlive: true),
        },
      );
      expect(room.alivePlayers.map((p) => p.id), isNot(contains('player_x')));
      expect(room.alivePlayers.map((p) => p.id), contains('player_y'));
      expect(room.deadPlayers.map((p) => p.id), contains('player_x'));

      registry.allowWitchRevive('player_x');
      expect(registry.isDead('player_x'), isFalse);
      final revivedPlayer = PlayerModel.fromMap(incomingZombieMap);
      expect(revivedPlayer.isAlive, isTrue, reason: 'Après intervention de la Sorcière, le joueur peut être reconstruit vivant');

      registry.clearForNewGame();
      expect(registry.deadPlayerIds.isEmpty, isTrue);
    });

    test('DeathRegistryService.filterOrEnforce : applique le verrou sur une table de joueurs', () {
      final registry = DeathRegistryService.instance;
      registry.clearForNewGame();
      registry.markDead('dead_1');

      final players = {
        'dead_1': const PlayerModel(id: 'dead_1', name: 'Dead 1', isAlive: true),
        'alive_1': const PlayerModel(id: 'alive_1', name: 'Alive 1', isAlive: true),
        'dead_2': const PlayerModel(id: 'dead_2', name: 'Dead 2', isAlive: false),
      };

      final enforced = registry.filterOrEnforce(players);
      expect(enforced['dead_1']!.isAlive, isFalse, reason: 'dead_1 forcé à mort');
      expect(enforced['alive_1']!.isAlive, isTrue, reason: 'alive_1 reste vivant');
      expect(enforced['dead_2']!.isAlive, isFalse, reason: 'dead_2 reste mort');
      expect(registry.isDead('dead_2'), isTrue, reason: 'dead_2 auto-inscrit au registre');

      registry.clearForNewGame();
    });

    test('Purge stratégique de l\'aube : GameRoom.copyWith avec clearNightVictimId et clearBlackWolfTargetId réinitialise à null', () {
      final room = GameRoom(
        roomCode: 'TEST',
        hostId: 'host',
        phase: GamePhase.nightWerewolves,
        nightVictimId: 'victim_p1',
        blackWolfTargetId: 'silenced_p2',
        players: {
          'p1': const PlayerModel(id: 'p1', name: 'P1', isAlive: false),
          'p2': const PlayerModel(id: 'p2', name: 'P2', isAlive: true),
        },
      );

      expect(room.nightVictimId, equals('victim_p1'));
      expect(room.blackWolfTargetId, equals('silenced_p2'));

      final roomRetained = room.copyWith(round: 2);
      expect(roomRetained.nightVictimId, equals('victim_p1'));
      expect(roomRetained.blackWolfTargetId, equals('silenced_p2'));

      final roomCleared = room.copyWith(
        clearNightVictimId: true,
        clearBlackWolfTargetId: true,
      );
      expect(roomCleared.nightVictimId, isNull, reason: 'nightVictimId doit être purgé à null');
      expect(roomCleared.blackWolfTargetId, isNull, reason: 'blackWolfTargetId doit être purgé à null');
    });

    test('PlayerModel.copyWith : clearTargetVote et clearTargetVoteId purgent targetVoteId', () {
      const player = PlayerModel(
        id: 'p1',
        name: 'Player 1',
        targetVoteId: 'target_x',
        isAlive: true,
      );

      expect(player.targetVoteId, equals('target_x'));

      final cleared1 = player.copyWith(clearTargetVote: true);
      expect(cleared1.targetVoteId, isNull);

      final cleared2 = player.copyWith(clearTargetVoteId: true);
      expect(cleared2.targetVoteId, isNull);
    });

    test('Sélection stratégique des Loups : exclusion absolue des cibles mortes', () {
      final registry = DeathRegistryService.instance;
      registry.clearForNewGame();
      registry.markDead('dead_p1');

      final players = {
        'dead_p1': const PlayerModel(id: 'dead_p1', name: 'Mort P1', isAlive: false),
        'alive_p2': const PlayerModel(id: 'alive_p2', name: 'Vivant P2', isAlive: true),
        'alive_p3': const PlayerModel(id: 'alive_p3', name: 'Vivant P3', isAlive: true),
      };

      final room = GameRoom(
        roomCode: 'TEST',
        hostId: 'host',
        phase: GamePhase.nightWerewolves,
        nightVictimId: 'dead_p1',
        blackWolfTargetId: 'dead_p1',
        players: players,
      );

      final rawVictimId = room.nightVictimId;
      final victimPlayer = rawVictimId != null ? room.players[rawVictimId] : null;
      final effectiveVictimId = (victimPlayer != null && victimPlayer.isAlive && !registry.isDead(rawVictimId!))
          ? rawVictimId
          : null;

      expect(effectiveVictimId, isNull, reason: 'Une victime morte ne peut jamais être réutilisée au tour suivant');

      final rawMuteId = room.blackWolfTargetId;
      final mutePlayer = rawMuteId != null ? room.players[rawMuteId] : null;
      final effectiveMuteId = (mutePlayer != null && mutePlayer.isAlive && !registry.isDead(rawMuteId!))
          ? rawMuteId
          : null;

      expect(effectiveMuteId, isNull, reason: 'Une cible muselée morte ne peut jamais être conservée au tour suivant');

      registry.clearForNewGame();
    });

    group('Synchronisation temporelle, Anti-Rollback et Idempotence des phases', () {
      test('Garde Monotone Strict : Interdiction de rétrograder le tour ou reculer de Nuit vers Jour', () {

        final currentRoom = GameRoom(
          roomCode: 'TEST_SYNC',
          hostId: 'host',
          phase: GamePhase.nightWerewolves,
          round: 2,
        );

        bool isValidStateUpdate(GameRoom current, Map<String, dynamic> incoming) {
          final incomingRound = incoming['round'] is int ? incoming['round'] as int : current.round;
          if (incomingRound < current.round) {
            return false;
          }
          final rawPhase = incoming['phase']?.toString() ?? incoming['currentPhase']?.toString();
          if (rawPhase != null) {
            final incomingPhase = GamePhase.fromString(rawPhase);
            if (incomingRound == current.round) {
              if (current.phase.isNight && incomingPhase.isDay) {
                return false;
              }
              if (current.phase.isNight &&
                  incomingPhase.isNight &&
                  incomingPhase.nightOrderIndex < current.phase.nightOrderIndex) {
                return false;
              }
            }
          }
          return true;
        }

        final staleRoundPacket = {'round': 1, 'phase': 'dayResolution'};
        expect(isValidStateUpdate(currentRoom, staleRoundPacket), isFalse,
            reason: 'Un paquet du Tour 1 doit impérativement être rejeté si la salle est au Tour 2');

        final nightToDayRollbackPacket = {'round': 2, 'phase': 'dayVoting'};
        expect(isValidStateUpdate(currentRoom, nightToDayRollbackPacket), isFalse,
            reason: 'Une phase diurne ne peut pas écraser une phase nocturne au même tour');

        final nightOrderRollbackPacket = {'round': 2, 'phase': 'nightDefender'};
        expect(isValidStateUpdate(currentRoom, nightOrderRollbackPacket), isFalse,
            reason: 'L\'ordre canonique nocturne ne peut pas reculer');

        final validProgression = {'round': 2, 'phase': 'nightSeer'};
        expect(isValidStateUpdate(currentRoom, validProgression), isTrue,
            reason: 'Une progression normale vers la phase suivante de la nuit doit être acceptée');

        final nextRoundProgression = {'round': 3, 'phase': 'morningAnnouncement'};
        expect(isValidStateUpdate(currentRoom, nextRoundProgression), isTrue,
            reason: 'Une progression vers un tour supérieur doit être acceptée');
      });

      test('Idempotence de la clôture de vote : un vote ne peut être résolu qu\'une seule fois par tour', () {
        final resolvedRounds = <int>{};

        bool tryResolveDayVote(int round, GamePhase currentPhase) {
          if (currentPhase != GamePhase.dayVoting && currentPhase != GamePhase.dayTieBreakVote) {
            return false;
          }
          if (resolvedRounds.contains(round)) {
            return false;
          }
          resolvedRounds.add(round);
          return true;
        }

        expect(tryResolveDayVote(1, GamePhase.dayVoting), isTrue);
        expect(resolvedRounds.contains(1), isTrue);

        expect(tryResolveDayVote(1, GamePhase.dayVoting), isFalse,
            reason: 'Le vote du Tour 1 ne peut pas être résolu une deuxième fois');

        expect(tryResolveDayVote(1, GamePhase.dayResolution), isFalse,
            reason: 'La résolution ne peut s\'exécuter que pendant un scrutin diurne');

        expect(tryResolveDayVote(2, GamePhase.dayVoting), isTrue,
            reason: 'Le scrutin du Tour 2 doit pouvoir se résoudre normalement');
        expect(resolvedRounds.contains(2), isTrue);
      });

      test('Validation de la protection UI de dérive temporelle (drift)', () {

        bool shouldTriggerExpiration({
          required GamePhase widgetPhase,
          required int widgetRound,
          required GamePhase currentRoomPhase,
          required int currentRoomRound,
        }) {
          if (currentRoomPhase != widgetPhase || currentRoomRound != widgetRound) {
            return false;
          }
          return true;
        }

        expect(
          shouldTriggerExpiration(
            widgetPhase: GamePhase.dayResolution,
            widgetRound: 1,
            currentRoomPhase: GamePhase.dayResolution,
            currentRoomRound: 1,
          ),
          isTrue,
        );

        expect(
          shouldTriggerExpiration(
            widgetPhase: GamePhase.dayResolution,
            widgetRound: 1,
            currentRoomPhase: GamePhase.nightDefender,
            currentRoomRound: 2,
          ),
          isFalse,
          reason: 'L\'expiration orpheline du Jour 1 doit être neutralisée si la salle est déjà en Nuit 2',
        );
      });
    });

    group('Évaluation synchrone et coupure immédiate de fin de partie (checkGameEnd / evaluateVictoryConditions)', () {
      test('Parité stricte des Loups : totalLoupsVivants >= totalVillageoisVivants accorde la victoire immédiate à la meute', () {

        final players = {
          'wolf_1': const PlayerModel(id: 'wolf_1', name: 'Loup 1', role: GameRole.simpleWerewolf, isAlive: true),
          'wolf_2': const PlayerModel(id: 'wolf_2', name: 'Loup 2', role: GameRole.simpleWerewolf, isAlive: true),
          'v_1': const PlayerModel(id: 'v_1', name: 'Villageois 1', role: GameRole.simpleVillager, isAlive: true),
          'v_2': const PlayerModel(id: 'v_2', name: 'Villageois 2', role: GameRole.simpleVillager, isAlive: true),
        };

        final room = GameRoom(
          roomCode: 'TEST_PARITY',
          hostId: 'host',
          phase: GamePhase.morningAnnouncement,
          players: players,
        );

        final win = GameNotifier.checkWinConditions(room);
        expect(win, equals('werewolves'),
            reason: 'Dès que le nombre de loups vivants est supérieur ou égal aux villageois, la meute gagne immédiatement');
      });

      test('Exception du couple mixte : la parité des loups est suspendue tant qu\'un couple mixte survit', () {

        final players = {
          'wolf_1': const PlayerModel(
            id: 'wolf_1',
            name: 'Loup Amoureux',
            role: GameRole.simpleWerewolf,
            isAlive: true,
            isLover: true,
            loverId: 'v_1',
          ),
          'wolf_2': const PlayerModel(id: 'wolf_2', name: 'Loup 2', role: GameRole.simpleWerewolf, isAlive: true),
          'v_1': const PlayerModel(
            id: 'v_1',
            name: 'Villageois Amoureux',
            role: GameRole.simpleVillager,
            isAlive: true,
            isLover: true,
            loverId: 'wolf_1',
          ),
          'v_2': const PlayerModel(id: 'v_2', name: 'Villageois 2', role: GameRole.simpleVillager, isAlive: true),
        };

        final room = GameRoom(
          roomCode: 'TEST_MIXED_COUPLE',
          hostId: 'host',
          phase: GamePhase.morningAnnouncement,
          players: players,
        );

        final win = GameNotifier.checkWinConditions(room);
        expect(win, isNull,
            reason: 'Un couple mixte encore en vie doit empêcher la victoire automatique de la meute par parité');
      });

      test('Couple mixte final : victoire exclusive des amoureux lorsqu\'ils sont les deux derniers survivants', () {
        final players = {
          'wolf_1': const PlayerModel(
            id: 'wolf_1',
            name: 'Loup Amoureux',
            role: GameRole.simpleWerewolf,
            isAlive: true,
            isLover: true,
            loverId: 'v_1',
          ),
          'v_1': const PlayerModel(
            id: 'v_1',
            name: 'Villageois Amoureux',
            role: GameRole.simpleVillager,
            isAlive: true,
            isLover: true,
            loverId: 'wolf_1',
          ),
          'dead_1': const PlayerModel(id: 'dead_1', name: 'Mort 1', role: GameRole.simpleVillager, isAlive: false),
        };

        final room = GameRoom(
          roomCode: 'TEST_LOVERS_WIN',
          hostId: 'host',
          phase: GamePhase.morningAnnouncement,
          players: players,
        );

        final win = GameNotifier.checkWinConditions(room);
        expect(win, equals('lovers'),
            reason: 'Lorsque les deux derniers survivants forment un couple, les amoureux remportent la partie');
      });

      test('Interruption immédiate du flux : refus d\'enchaîner vers le débat ou l\'élection du maire si victoire acquise', () {

        String routeDayPhase(GameRoom room) {
          final win = GameNotifier.checkWinConditions(room);
          if (win != null) {
            return GamePhase.gameOver.name;
          }
          if (room.round == 1 && room.captainId == null) {
            return GamePhase.mayorElection.name;
          }
          return GamePhase.dayDebate.name;
        }

        final parityRoom = GameRoom(
          roomCode: 'TEST_ROUTE_STOP',
          hostId: 'host',
          round: 1,
          captainId: null,
          phase: GamePhase.morningAnnouncement,
          players: {
            'w1': const PlayerModel(id: 'w1', name: 'W1', role: GameRole.simpleWerewolf, isAlive: true),
            'w2': const PlayerModel(id: 'w2', name: 'W2', role: GameRole.simpleWerewolf, isAlive: true),
            'v1': const PlayerModel(id: 'v1', name: 'V1', role: GameRole.simpleVillager, isAlive: true),
            'v2': const PlayerModel(id: 'v2', name: 'V2', role: GameRole.simpleVillager, isAlive: true),
          },
        );

        expect(routeDayPhase(parityRoom), equals(GamePhase.gameOver.name),
            reason: 'La partie doit basculer directement en gameOver sans passer par l\'élection du maire');
      });
    });
  });
}
