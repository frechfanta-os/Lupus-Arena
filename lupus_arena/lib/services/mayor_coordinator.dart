import 'dart:math';
import '../models/game_phase.dart';
import '../models/player_model.dart';

class MayorElectionResult {
  final String mayorId;
  final String mayorName;
  final int votesReceived;
  final String logMessage;

  const MayorElectionResult({
    required this.mayorId,
    required this.mayorName,
    required this.votesReceived,
    required this.logMessage,
  });
}

class MayorDeathResult {
  final bool isSuccessionTriggered;
  final String? deceasedMayorId;
  final GamePhase nextPhase;
  final int timerSeconds;
  final String logMessage;

  const MayorDeathResult({
    required this.isSuccessionTriggered,
    this.deceasedMayorId,
    this.nextPhase = GamePhase.mayorSuccession,
    this.timerSeconds = 15,
    this.logMessage = '',
  });
}

class MayorCoordinator {
  const MayorCoordinator();

  MayorElectionResult electMayor({
    required Map<String, PlayerModel> players,
    required Map<String, String> electionVotes,
    String? fallbackId,
  }) {
    final livingPlayers = players.values.where((p) => p.isAlive).toList();
    if (livingPlayers.isEmpty) {
      return const MayorElectionResult(
        mayorId: '',
        mayorName: 'Inconnu',
        votesReceived: 0,
        logMessage: 'Aucun survivant pour assumer la charge du Maire.',
      );
    }

    final tally = <String, int>{};
    for (final entry in electionVotes.entries) {
      final voterId = entry.key;
      final candidateId = entry.value;

      final voter = players[voterId];
      final candidate = players[candidateId];

      if (voter != null && voter.isAlive && candidate != null && candidate.isAlive) {
        tally[candidateId] = (tally[candidateId] ?? 0) + 1;
      }
    }

    if (tally.isNotEmpty) {

      final maxVotes = tally.values.reduce(max);
      final topCandidates = tally.entries
          .where((e) => e.value == maxVotes)
          .map((e) => e.key)
          .toList();

      final winnerId = topCandidates.first;
      final winner = players[winnerId] ?? livingPlayers.first;

      return MayorElectionResult(
        mayorId: winner.id,
        mayorName: winner.name,
        votesReceived: maxVotes,
        logMessage:
            '🎖️ ${winner.name} est élu Maire du Village avec $maxVotes voix ! Sa voix comptera désormais double.',
      );
    }

    final fallbackWinner = (fallbackId != null && players[fallbackId]?.isAlive == true)
        ? players[fallbackId]!
        : livingPlayers.first;

    return MayorElectionResult(
      mayorId: fallbackWinner.id,
      mayorName: fallbackWinner.name,
      votesReceived: 0,
      logMessage:
          '🎖️ Faute de suffrages, ${fallbackWinner.name} est désigné Maire d\'office par le village.',
    );
  }

  MayorDeathResult handleMayorDeath({
    required String deadPlayerId,
    required String? currentMayorId,
    required Map<String, PlayerModel> players,
  }) {
    final isMayor = currentMayorId == deadPlayerId ||
        (players[deadPlayerId]?.isCaptain == true);

    if (!isMayor) {
      return const MayorDeathResult(
        isSuccessionTriggered: false,
      );
    }

    final otherLiving = players.values
        .where((p) => p.isAlive && p.id != deadPlayerId)
        .toList();

    if (otherLiving.isEmpty) {
      return const MayorDeathResult(
        isSuccessionTriggered: false,
        logMessage: 'Le Maire est tombé, mais aucun survivant ne reste pour lui succéder.',
      );
    }

    final deceasedName = players[deadPlayerId]?.name ?? 'Le Maire';

    return MayorDeathResult(
      isSuccessionTriggered: true,
      deceasedMayorId: deadPlayerId,
      nextPhase: GamePhase.mayorSuccession,
      timerSeconds: 15,
      logMessage:
          '📜 $deceasedName a péri ! Il dispose de 15 secondes pour rédiger son testament et transmettre son écharpe de Maire.',
    );
  }

  String? passMayorTitle({
    required String mayorId,
    required String successorId,
    required Map<String, PlayerModel> players,
  }) {
    if (mayorId == successorId) return null;
    final successor = players[successorId];
    if (successor == null || !successor.isAlive) return null;
    return successor.id;
  }

  String autoPassOnTimeout({
    required Map<String, PlayerModel> players,
    required String deceasedMayorId,
    List<String>? seatingOrder,
  }) {
    final candidates = players.values
        .where((p) => p.isAlive && p.id != deceasedMayorId)
        .toList();

    if (candidates.isEmpty) return deceasedMayorId;

    if (seatingOrder != null && seatingOrder.isNotEmpty) {
      for (final id in seatingOrder) {
        if (id != deceasedMayorId && players[id]?.isAlive == true) {
          return id;
        }
      }
    }

    final random = Random();
    return candidates[random.nextInt(candidates.length)].id;
  }

  int calculateVoteWeight({
    required String voterId,
    required String? mayorPlayerId,
    int livingCount = 0,
  }) {
    if (mayorPlayerId != null && voterId == mayorPlayerId) {
      if (livingCount > 0 && livingCount <= 3) {
        return 1;
      }
      return 2;
    }
    return 1;
  }

  GamePhase getNextDayPhase({
    required GamePhase current,
    required int round,
    required String? mayorId,
    required Map<String, PlayerModel> players,
    required bool mayorOpeningDone,
    required bool mayorClosingDone,
  }) {
    final isMayorAlive = mayorId != null && (players[mayorId]?.isAlive ?? false);

    switch (current) {
      case GamePhase.morningAnnouncement:

        if (round == 1 && mayorId == null) {
          return GamePhase.mayorElection;
        }

        if (isMayorAlive && !mayorOpeningDone) {
          return GamePhase.mayorSpeechOpening;
        }
        return GamePhase.dayDebate;

      case GamePhase.mayorElection:
      case GamePhase.captainElection:

        return GamePhase.mayorSpeechOpening;

      case GamePhase.mayorSpeechOpening:

        return GamePhase.dayDebate;

      case GamePhase.dayDebate:

        if (isMayorAlive && !mayorClosingDone) {
          return GamePhase.mayorSpeechClosing;
        }
        return GamePhase.dayVoting;

      case GamePhase.mayorSpeechClosing:

        return GamePhase.dayVoting;

      case GamePhase.dayVoting:
        return GamePhase.dayResolution;

      case GamePhase.dayDefense:
        return GamePhase.dayTieBreakVote;

      case GamePhase.dayTieBreakVote:
        return GamePhase.dayResolution;

      case GamePhase.mayorSuccession:
      case GamePhase.captainSuccession:

        if (round == 1 && mayorId == null) {
          return GamePhase.mayorElection;
        }
        return GamePhase.dayDebate;

      default:
        return GamePhase.dayDebate;
    }
  }

  bool isProceduralActionAllowed({
    required String playerId,
    required String? mayorId,
    required bool isMuted,
  }) {

    return true;
  }
}
