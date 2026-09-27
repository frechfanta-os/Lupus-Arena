import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'game_engine_models.dart';
import '../services/death_registry_service.dart';

class GameController extends ChangeNotifier {

  GamePhase _currentPhase = GamePhase.initialization;
  int _currentTurn = 0;
  final List<Player> _players = [];
  final Queue<GameStep> _stepQueue = Queue<GameStep>();
  GameStep? _activeStep;

  final NightActionBuffer _nightBuffer = NightActionBuffer();
  List<String> _pendingDeathsAnnouncement = [];
  final Map<String, String> _votes = {};

  String? _lastBodyguardProtectedId;
  bool _foxPowerActive = true;
  String? _crowTargetId;
  bool _fatherOfWolvesInfectionUsed = false;
  bool _witchLifePotionUsed = false;
  bool _witchDeathPotionUsed = false;
  bool _stutteringJudgeSignUsed = false;
  bool _stutteringJudgeTriggeredThisDay = false;
  int _wolvesCasualtiesCount = 0;

  Timer? _turnTimer;
  int _secondsRemaining = 0;

  GamePhase get currentPhase => _currentPhase;
  int get currentTurn => _currentTurn;
  List<Player> get players => List.unmodifiable(_players);
  GameStep? get activeStep => _activeStep;
  int get secondsRemaining => _secondsRemaining;
  List<String> get pendingDeathsAnnouncement => List.unmodifiable(_pendingDeathsAnnouncement);
  String? get crowTargetId => _crowTargetId;

  void _startTimer(int seconds, VoidCallback onTimeout) {
    _turnTimer?.cancel();
    _secondsRemaining = seconds;
    notifyListeners();

    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        _turnTimer?.cancel();
        _secondsRemaining = 0;
        notifyListeners();
        onTimeout();
      }
    });
  }

  void _stopTimer() {
    _turnTimer?.cancel();
    _turnTimer = null;
  }

  bool _isRolePresentAndAlive(RoleType role) {
    return _players.any((p) =>
        p.role == role &&
        p.isAlive &&
        !DeathRegistryService.instance.isDead(p.id));
  }

  bool _areWerewolvesPresentAndAlive() {
    return _players.any((p) =>
        (p.role == RoleType.werewolf ||
         p.role == RoleType.fatherOfWolves ||
         p.role == RoleType.bigBadWolf ||
         p.faction == Faction.werewolves) &&
        p.isAlive &&
        !DeathRegistryService.instance.isDead(p.id));
  }

  void _buildNightStepQueue() {
    _stepQueue.clear();

    if (_currentTurn == 0) {

      if (_isRolePresentAndAlive(RoleType.stealer)) {
        _stepQueue.add(GameStep.preStealer);
      }
      if (_isRolePresentAndAlive(RoleType.cupid)) {
        _stepQueue.add(GameStep.preCupid);
      }
      return;
    }

    if (_isRolePresentAndAlive(RoleType.actor)) {
      _stepQueue.add(GameStep.roleActor);
    }
    if (_isRolePresentAndAlive(RoleType.seer)) {
      _stepQueue.add(GameStep.roleSeer);
    }
    if (_isRolePresentAndAlive(RoleType.fox) && _foxPowerActive) {
      _stepQueue.add(GameStep.roleFox);
    }
    if (_isRolePresentAndAlive(RoleType.crow)) {
      _stepQueue.add(GameStep.roleCrow);
    }
    if (_isRolePresentAndAlive(RoleType.pyromaniac)) {
      _stepQueue.add(GameStep.rolePyromaniac);
    }
    if (_isRolePresentAndAlive(RoleType.bodyguard)) {
      _stepQueue.add(GameStep.roleBodyguard);
    }
    if (_areWerewolvesPresentAndAlive()) {
      _stepQueue.add(GameStep.roleWerewolves);
    }

    if (_isRolePresentAndAlive(RoleType.bigBadWolf) && _wolvesCasualtiesCount == 0) {
      _stepQueue.add(GameStep.roleBigBadWolf);
    }

    if (_isRolePresentAndAlive(RoleType.whiteWolf) && (_currentTurn % 2 == 0)) {
      _stepQueue.add(GameStep.roleWhiteWolf);
    }
    if (_isRolePresentAndAlive(RoleType.witch)) {
      _stepQueue.add(GameStep.roleWitch);
    }
  }

  void startGame(List<Player> initialPlayers) {
    _players.clear();
    _players.addAll(initialPlayers);
    _currentTurn = 0;
    _wolvesCasualtiesCount = 0;
    _foxPowerActive = true;
    _lastBodyguardProtectedId = null;
    _crowTargetId = null;
    _fatherOfWolvesInfectionUsed = false;
    _witchLifePotionUsed = false;
    _witchDeathPotionUsed = false;
    _stutteringJudgeSignUsed = false;
    _stutteringJudgeTriggeredThisDay = false;
    _startPreliminaryNight();
  }

  void _startPreliminaryNight() {
    _currentPhase = GamePhase.preliminaryNight;
    _buildNightStepQueue();
    _executeNextNightStep();
  }

  void _startRegularNight() {
    _currentTurn++;
    _currentPhase = GamePhase.night;
    _nightBuffer.clear();
    _buildNightStepQueue();
    _executeNextNightStep();
  }

  void _executeNextNightStep() {
    if (_stepQueue.isNotEmpty) {
      _activeStep = _stepQueue.removeFirst();

      _startTimer(20, () => actionPass());
      notifyListeners();
    } else {
      _stopTimer();
      _activeStep = null;
      if (_currentPhase == GamePhase.preliminaryNight) {
        _startRegularNight();
      } else {
        _resolveNightActionsAndWakeUp();
      }
    }
  }

  void actionPass() {
    _stopTimer();
    _executeNextNightStep();
  }

  void actionStealerStealRole(String stealerId, String targetPlayerId) {
    if (_activeStep != GameStep.preStealer) return;
    final stealerIndex = _players.indexWhere((p) => p.id == stealerId);
    final targetIndex = _players.indexWhere((p) => p.id == targetPlayerId);

    if (stealerIndex != -1 && targetIndex != -1) {
      final stolenRole = _players[targetIndex].role;
      final stolenFaction = _players[targetIndex].faction;

      _players[targetIndex].role = RoleType.villager;
      _players[targetIndex].faction = Faction.village;

      _players[stealerIndex].role = stolenRole;
      _players[stealerIndex].faction = stolenFaction;
    }

    _stopTimer();
    _executeNextNightStep();
  }

  void actionCupidLinkLovers(String player1Id, String player2Id) {
    if (_activeStep != GameStep.preCupid) return;
    for (var p in _players) {
      if (p.id == player1Id || p.id == player2Id) {
        p.loversIds.add(player1Id);
        p.loversIds.add(player2Id);
      }
    }
    _executeNextNightStep();
  }

  void actionFoxSmell(String centerPlayerId) {
    if (_activeStep != GameStep.roleFox) return;

    final aliveList = _players.where((p) => p.isAlive).toList();
    final index = aliveList.indexWhere((p) => p.id == centerPlayerId);

    if (index != -1) {
      final leftNeighbor = aliveList[(index - 1 + aliveList.length) % aliveList.length];
      final rightNeighbor = aliveList[(index + 1) % aliveList.length];
      final target = aliveList[index];

      final trio = [target, leftNeighbor, rightNeighbor];
      final wolfFound = trio.any((p) =>
          p.faction == Faction.werewolves ||
          p.role == RoleType.werewolf ||
          p.role == RoleType.bigBadWolf ||
          p.role == RoleType.fatherOfWolves ||
          p.role == RoleType.whiteWolf);

      if (!wolfFound) {
        _foxPowerActive = false;
      }
    }
    _executeNextNightStep();
  }

  void actionCrowTarget(String targetId) {
    if (_activeStep != GameStep.roleCrow) return;
    _crowTargetId = targetId;
    _executeNextNightStep();
  }

  void actionBodyguardProtect(String targetId) {
    if (_activeStep != GameStep.roleBodyguard) return;
    if (targetId == _lastBodyguardProtectedId) {
      return;
    }
    _nightBuffer.protectedPlayerId = targetId;
    _lastBodyguardProtectedId = targetId;
    _executeNextNightStep();
  }

  void actionPyromaniac({List<String>? douseTargets, bool ignite = false}) {
    if (_activeStep != GameStep.rolePyromaniac) return;
    if (ignite) {
      for (var p in _players.where((p) => p.isAlive && p.isDousedWithGas)) {
        _nightBuffer.killIntents.add(
          KillIntent(targetPlayerId: p.id, source: KillSource.pyromaniacFire),
        );
      }
    } else if (douseTargets != null) {
      for (var id in douseTargets.take(2)) {
        final p = _players.where((pl) => pl.id == id).firstOrNull;
        if (p != null) {
          p.isDousedWithGas = true;
        }
      }
    }
    _executeNextNightStep();
  }

  void actionWerewolvesVote(String targetId, {bool infect = false}) {
    if (_activeStep != GameStep.roleWerewolves) return;
    if (infect && !_fatherOfWolvesInfectionUsed && _isRolePresentAndAlive(RoleType.fatherOfWolves)) {
      _nightBuffer.isInfected = true;
      _fatherOfWolvesInfectionUsed = true;
    }
    _nightBuffer.killIntents.add(
      KillIntent(targetPlayerId: targetId, source: KillSource.werewolves),
    );
    _executeNextNightStep();
  }

  void actionBigBadWolfKill(String targetId) {
    if (_activeStep != GameStep.roleBigBadWolf) return;
    _nightBuffer.killIntents.add(
      KillIntent(targetPlayerId: targetId, source: KillSource.bigBadWolf),
    );
    _executeNextNightStep();
  }

  void actionWhiteWolfKill(String targetId) {
    if (_activeStep != GameStep.roleWhiteWolf) return;
    _nightBuffer.killIntents.add(
      KillIntent(targetPlayerId: targetId, source: KillSource.whiteWolf),
    );
    _executeNextNightStep();
  }

  void actionWitchDecide({bool useLifePotion = false, String? killTargetId}) {
    if (_activeStep != GameStep.roleWitch) return;

    if (useLifePotion && !_witchLifePotionUsed) {

      final wolfVictim = _nightBuffer.killIntents
          .where((k) => k.source == KillSource.werewolves)
          .map((k) => k.targetPlayerId)
          .firstOrNull;

      if (wolfVictim != null) {
        _nightBuffer.healedPlayerId = wolfVictim;
        _witchLifePotionUsed = true;
      }
    }

    if (killTargetId != null && !_witchDeathPotionUsed) {
      _nightBuffer.killIntents.add(
        KillIntent(targetPlayerId: killTargetId, source: KillSource.witchPoison),
      );
      _witchDeathPotionUsed = true;
    }
    _executeNextNightStep();
  }

  void _resolveNightActionsAndWakeUp() {
    final Set<String> resolvedDeaths = {};

    String? infectedVictimId;
    if (_nightBuffer.isInfected) {
      final wolfAttack = _nightBuffer.killIntents.firstWhere(
        (k) => k.source == KillSource.werewolves,
        orElse: () => const KillIntent(targetPlayerId: '', source: KillSource.werewolves),
      );
      if (wolfAttack.targetPlayerId.isNotEmpty) {
        infectedVictimId = wolfAttack.targetPlayerId;
        final target = _players.where((p) => p.id == infectedVictimId).firstOrNull;
        if (target != null) {
          target.faction = Faction.werewolves;
        }
      }
    }

    for (final intent in _nightBuffer.killIntents) {
      final targetId = intent.targetPlayerId;
      if (targetId.isEmpty) continue;

      if (intent.source == KillSource.werewolves && targetId == infectedVictimId) {
        continue;
      }

      if (_nightBuffer.healedPlayerId == targetId) {
        continue;
      }

      if (_nightBuffer.protectedPlayerId == targetId &&
          (intent.source == KillSource.werewolves ||
           intent.source == KillSource.bigBadWolf ||
           intent.source == KillSource.whiteWolf)) {
        continue;
      }

      resolvedDeaths.add(targetId);
    }

    final loversDying = <String>{};
    for (final victimId in resolvedDeaths) {
      final victim = _players.where((p) => p.id == victimId).firstOrNull;
      if (victim != null && victim.loversIds.isNotEmpty) {
        loversDying.addAll(victim.loversIds);
      }
    }
    resolvedDeaths.addAll(loversDying);

    for (final p in _players) {
      if (resolvedDeaths.contains(p.id) && p.isAlive) {
        p.isAlive = false;
        DeathRegistryService.instance.markDead(p.id);
        if (p.role == RoleType.werewolf ||
            p.role == RoleType.bigBadWolf ||
            p.role == RoleType.fatherOfWolves ||
            p.role == RoleType.whiteWolf) {
          _wolvesCasualtiesCount++;
        }
      }
    }

    _pendingDeathsAnnouncement = resolvedDeaths.toList();
    _startDayAnnouncements();
  }

  void _startDayAnnouncements() {
    _currentPhase = GamePhase.dayAnnounceDeaths;
    notifyListeners();

    if (_isRolePresentAndAlive(RoleType.dedicatedMaid) && _pendingDeathsAnnouncement.isNotEmpty) {
      _activeStep = GameStep.hookDedicatedMaid;
      _startTimer(10, () => _endAnnouncementsAndDiscuss());
    } else {
      _startTimer(5, () => _endAnnouncementsAndDiscuss());
    }
  }

  void actionDedicatedMaidTakeRole(String targetDeadId) {
    if (_activeStep != GameStep.hookDedicatedMaid) return;
    final deadPlayer = _players.where((p) => p.id == targetDeadId).firstOrNull;
    final maid = _players.where((p) => p.role == RoleType.dedicatedMaid && p.isAlive).firstOrNull;

    if (deadPlayer != null && maid != null) {
      maid.role = deadPlayer.role;
    }
    _stopTimer();
    _endAnnouncementsAndDiscuss();
  }

  void _endAnnouncementsAndDiscuss() {
    _activeStep = null;
    _currentPhase = GamePhase.dayDiscussion;

    _startTimer(120, () => startDayVoting());
    notifyListeners();
  }

  void startDayVoting() {
    _stopTimer();
    _currentPhase = GamePhase.dayVoting;
    _votes.clear();

    _startTimer(30, () => resolveVotesAndExecute());
    notifyListeners();
  }

  void castVote(String voterId, String targetId) {
    if (_currentPhase != GamePhase.dayVoting) return;

    if (DeathRegistryService.instance.isDead(voterId)) return;
    final voter = _players.where((p) => p.id == voterId).firstOrNull;
    if (voter == null || !voter.isAlive) return;

    if (DeathRegistryService.instance.isDead(targetId)) return;
    final target = _players.where((p) => p.id == targetId).firstOrNull;
    if (target == null || !target.isAlive) return;

    _votes[voterId] = targetId;

    final aliveCount = _players.where((p) => p.isAlive).length;
    if (_votes.length >= aliveCount) {
      resolveVotesAndExecute();
    }
  }

  void resolveVotesAndExecute() {
    _stopTimer();
    _currentPhase = GamePhase.dayExecution;

    final Map<String, int> scores = {};
    for (var p in _players.where((p) => p.isAlive)) {
      scores[p.id] = 0;
    }

    if (_crowTargetId != null && scores.containsKey(_crowTargetId)) {
      scores[_crowTargetId!] = scores[_crowTargetId!]! + 2;
    }

    _votes.forEach((voterId, targetId) {
      if (scores.containsKey(targetId)) {
        final voter = _players.where((p) => p.id == voterId).firstOrNull;
        if (voter != null) {
          scores[targetId] = scores[targetId]! + (voter.isCaptain ? 2 : 1);
        }
      }
    });

    int highestScore = -1;
    List<String> highestVotedIds = [];

    scores.forEach((playerId, score) {
      if (score > highestScore) {
        highestScore = score;
        highestVotedIds = [playerId];
      } else if (score == highestScore) {
        highestVotedIds.add(playerId);
      }
    });

    String? executedPlayerId;
    if (highestVotedIds.length == 1 && highestScore > 0) {
      executedPlayerId = highestVotedIds.first;
    } else if (highestVotedIds.length > 1) {

      final captain = _players.where((p) => p.isCaptain && p.isAlive).firstOrNull;
      if (captain != null) {
        final captainVote = _votes[captain.id];
        if (captainVote != null && highestVotedIds.contains(captainVote)) {
          executedPlayerId = captainVote;
        }
      }
    }

    if (executedPlayerId != null) {
      final executed = _players.where((p) => p.id == executedPlayerId).firstOrNull;
      if (executed != null) {
        executed.isAlive = false;
        DeathRegistryService.instance.markDead(executed.id);

        if (executed.loversIds.isNotEmpty) {
          for (var loverId in executed.loversIds) {
            final lover = _players.where((p) => p.id == loverId).firstOrNull;
            if (lover != null) {
              lover.isAlive = false;
              DeathRegistryService.instance.markDead(lover.id);
            }
          }
        }
      }
    }

    _crowTargetId = null;

    if (_stutteringJudgeTriggeredThisDay) {
      _stutteringJudgeTriggeredThisDay = false;
      startDayVoting();
      return;
    }

    _checkWinConditionsOrContinue();
  }

  void triggerStutteringJudgeSign() {
    if (_stutteringJudgeSignUsed) return;
    if (_isRolePresentAndAlive(RoleType.stutteringJudge)) {
      _stutteringJudgeSignUsed = true;
      _stutteringJudgeTriggeredThisDay = true;
    }
  }

  void _checkWinConditionsOrContinue() {
    _currentPhase = GamePhase.checkWinConditions;
    notifyListeners();

    final alivePlayers = _players.where((p) => p.isAlive).toList();

    if (alivePlayers.length == 1 && alivePlayers.first.role == RoleType.whiteWolf) {
      _endGame(Faction.whiteWolf);
      return;
    }

    if (alivePlayers.length == 2 &&
        alivePlayers.first.loversIds.contains(alivePlayers.last.id)) {
      _endGame(Faction.lovers);
      return;
    }

    final aliveWolves = alivePlayers.where((p) =>
        p.faction == Faction.werewolves ||
        p.role == RoleType.werewolf ||
        p.role == RoleType.bigBadWolf ||
        p.role == RoleType.fatherOfWolves ||
        p.role == RoleType.whiteWolf).length;

    final aliveVillagers = alivePlayers.length - aliveWolves;

    if (aliveWolves >= aliveVillagers && aliveWolves > 0) {
      _endGame(Faction.werewolves);
      return;
    }

    if (aliveWolves == 0) {
      _endGame(Faction.village);
      return;
    }

    _startRegularNight();
  }

  void _endGame(Faction winningFaction) {
    _stopTimer();
    _currentPhase = GamePhase.gameOver;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
