import '../../models/game_role.dart';
import '../../models/game_state.dart';
import 'role_action_handler.dart';

class IdiotHandler extends RoleActionHandler {
  @override
  GameRole get role => GameRole.idiot;

  @override
  bool canAct(GameState state, String playerId) {
    return state.isAlive(playerId) && state.pendingExecutedPlayerId == playerId;
  }

  @override
  GameState executeAction(
    GameState state, {
    required String actorId,
    required Map<String, dynamic> actionPayload,
  }) {

    if (state.expandedRolesState.idiotPardoned) {
      return state;
    }

    final permanentlyBanned = Set<String>.from(state.expandedRolesState.permanentlyBannedVoters)..add(actorId);
    final updated = state.expandedRolesState.copyWith(
      idiotPardoned: true,
      permanentlyBannedVoters: permanentlyBanned,
    );

    return state.copyWith(
      clearPendingExecutedPlayerId: true,
      expandedRolesState: updated,
    );
  }

  @override
  RoleUIControls getUIControls(GameState state, String playerId) {
    return const RoleUIControls(
      title: 'L\'Idiot du Village',
      instruction: 'Si le village vous condamne, vous êtes immédiatement gracié (une seule fois) mais perdez définitivement votre droit de vote.',
      inputType: RoleActionInputType.none,
    );
  }
}
