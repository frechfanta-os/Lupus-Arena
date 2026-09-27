import '../../models/game_role.dart';
import '../../models/game_state.dart';

enum RoleActionInputType {
  none,
  singleTarget,
  multipleTargets,
  confirmation,
  roleChoice,
}

class RoleUIControls {
  final String title;
  final String instruction;
  final RoleActionInputType inputType;
  final List<String> availableTargetIds;
  final List<GameRole> availableRoles;
  final String confirmButtonLabel;
  final String? skipButtonLabel;
  final bool canSkip;

  const RoleUIControls({
    required this.title,
    required this.instruction,
    this.inputType = RoleActionInputType.none,
    this.availableTargetIds = const [],
    this.availableRoles = const [],
    this.confirmButtonLabel = 'Valider',
    this.skipButtonLabel,
    this.canSkip = false,
  });

  static const empty = RoleUIControls(
    title: '',
    instruction: '',
    inputType: RoleActionInputType.none,
  );
}

abstract class RoleActionHandler {
  GameRole get role;

  bool canAct(GameState state, String playerId);

  GameState executeAction(
    GameState state, {
    required String actorId,
    required Map<String, dynamic> actionPayload,
  });

  GameState onPhaseExpired(GameState state, String actorId) => state;

  RoleUIControls getUIControls(GameState state, String playerId);
}
