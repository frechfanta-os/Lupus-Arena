import 'dart:math';

import '../models/expanded_roles_state.dart';
import '../models/player_model.dart';
import 'expanded_roles_coordinator.dart';

class VoteTallyResult {
  final Map<String, int> voteCounts;
  final List<String> topCandidates;
  final int maxVotes;
  final String? condemnedPlayerId;
  final bool isTie;
  final bool isScapegoatTriggered;
  final String? scapegoatId;

  const VoteTallyResult({
    required this.voteCounts,
    required this.topCandidates,
    required this.maxVotes,
    this.condemnedPlayerId,
    this.isTie = false,
    this.isScapegoatTriggered = false,
    this.scapegoatId,
  });
}

class VoteCoordinator {
  const VoteCoordinator();

  String? tallyWerewolfVotes({
    required List<PlayerModel> alivePlayers,
    String? currentUserId,
    bool isAdmin = false,
  }) {
    final votes = <String, int>{};
    for (final p in alivePlayers) {
      if ((p.role.isEvil || (p.id == currentUserId && isAdmin)) &&
          p.targetVoteId != null) {
        votes[p.targetVoteId!] = (votes[p.targetVoteId!] ?? 0) + 1;
      }
    }
    if (votes.isEmpty) return null;
    return votes.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  VoteTallyResult tallyDayVotes({
    required Map<String, PlayerModel> players,
    required ExpandedRolesState expandedRolesState,
    String? captainId,
    Map<String, GameRole>? realRoles,
  }) {
    final voteCounts = <String, int>{};

    final livingCount = players.values.where((p) => p.isAlive).length;
    for (final voter in players.values.where((p) => p.isAlive)) {

      if (expandedRolesState.bannedVotersForToday.contains(voter.id) ||
          expandedRolesState.permanentlyBannedVoters.contains(voter.id)) {
        continue;
      }

      final target = voter.targetVoteId;
      if (target != null && players[target]?.isAlive == true) {

        final isMayor = voter.isCaptain || voter.id == captainId || voter.id == expandedRolesState.mayorPlayerId;
        final weight = (isMayor && livingCount > 3) ? 2 : 1;
        voteCounts[target] = (voteCounts[target] ?? 0) + weight;
      }
    }

    final countsWithCrow = ExpandedRolesCoordinator.applyCrowBonusVotes(
      baseVoteCounts: voteCounts,
      crowTargetId: expandedRolesState.crowTargetId,
    );

    if (countsWithCrow.isEmpty) {
      return const VoteTallyResult(
        voteCounts: {},
        topCandidates: [],
        maxVotes: 0,
      );
    }

    final maxVotes = countsWithCrow.values.reduce(max);
    final topCandidates = countsWithCrow.entries
        .where((e) => e.value == maxVotes)
        .map((e) => e.key)
        .toList();

    if (topCandidates.length > 1) {

      final scapegoatResolution = ExpandedRolesCoordinator.resolveScapegoatTie(
        alivePlayers: players.values.where((p) => p.isAlive).toList(),
        realRoles: realRoles,
        tiedCandidates: topCandidates,
      );

      if (scapegoatResolution != null) {
        return VoteTallyResult(
          voteCounts: countsWithCrow,
          topCandidates: topCandidates,
          maxVotes: maxVotes,
          condemnedPlayerId: scapegoatResolution,
          isTie: true,
          isScapegoatTriggered: true,
          scapegoatId: scapegoatResolution,
        );
      }

      final captain = players.values.cast<PlayerModel?>().firstWhere(
            (p) => p != null && p.isAlive && (p.isCaptain || p.id == captainId),
            orElse: () => null,
          );

      if (captain != null &&
          captain.targetVoteId != null &&
          topCandidates.contains(captain.targetVoteId)) {
        return VoteTallyResult(
          voteCounts: countsWithCrow,
          topCandidates: topCandidates,
          maxVotes: maxVotes,
          condemnedPlayerId: captain.targetVoteId,
          isTie: false,
        );
      }

      return VoteTallyResult(
        voteCounts: countsWithCrow,
        topCandidates: topCandidates,
        maxVotes: maxVotes,
        isTie: true,
      );
    }

    return VoteTallyResult(
      voteCounts: countsWithCrow,
      topCandidates: topCandidates,
      maxVotes: maxVotes,
      condemnedPlayerId: topCandidates.first,
    );
  }
}
