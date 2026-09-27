import '../models/game_role.dart';

class FogOfWarService {
  const FogOfWarService();

  static bool canSeeLoverBadge({
    required bool targetIsLover,
    required GameRole observerRole,
    required bool observerIsLover,
    bool isDevMode = false,
  }) {
    if (!targetIsLover) return false;
    if (isDevMode) return true;
    if (observerRole == GameRole.cupid) return true;
    if (observerIsLover) return true;
    return false;
  }

  static bool canSeeCharmedBadge({
    required bool targetIsCharmed,
    required GameRole observerRole,
    required bool observerIsCharmed,
    bool isDevMode = false,
  }) {
    if (!targetIsCharmed) return false;
    if (isDevMode) return true;
    if (observerRole == GameRole.piedPiper) return true;
    if (observerIsCharmed) return true;
    return false;
  }

  static bool canSeeInfectedBadge({
    required bool targetIsInfected,
    required bool isTargetMe,
    required bool observerIsEvil,
    bool isDevMode = false,
  }) {
    if (!targetIsInfected) return false;
    if (isDevMode) return true;
    if (isTargetMe) return true;
    if (observerIsEvil) return true;
    return false;
  }

  static bool canSeeCrowTarget({
    required bool targetIsCrowTarget,
    required bool isDayTime,
    required GameRole observerRole,
    bool isDevMode = false,
  }) {
    if (!targetIsCrowTarget) return false;
    if (isDevMode) return true;
    if (isDayTime) return true;
    if (observerRole == GameRole.raven) return true;
    return false;
  }

  static bool canSeeFoxSniff({
    required GameRole observerRole,
    bool isDevMode = false,
  }) {
    if (isDevMode) return true;
    if (observerRole == GameRole.fox) return true;
    return false;
  }

  static bool canSeeDefenderShield({
    required bool targetIsProtected,
    required GameRole observerRole,
    bool isDevMode = false,
  }) {
    if (!targetIsProtected) return false;
    if (isDevMode) return true;
    if (observerRole == GameRole.defender) return true;
    return false;
  }

  static bool canSeeWitchWolfVictim({
    required bool targetIsVictim,
    required GameRole observerRole,
    required bool isNightWitch,
    bool isDevMode = false,
  }) {
    if (!targetIsVictim) return false;
    if (isDevMode) return true;
    if (observerRole == GameRole.witch && isNightWitch) return true;
    return false;
  }

  static bool canSeeWitchHealed({
    required bool targetIsHealed,
    required GameRole observerRole,
    bool isDevMode = false,
  }) {
    if (!targetIsHealed) return false;
    if (isDevMode) return true;
    if (observerRole == GameRole.witch) return true;
    return false;
  }

  static bool canSeeWitchPoisoned({
    required bool targetIsPoisoned,
    required GameRole observerRole,
    bool isDevMode = false,
  }) {
    if (!targetIsPoisoned) return false;
    if (isDevMode) return true;
    if (observerRole == GameRole.witch) return true;
    return false;
  }

  static bool canSeeWildChildModel({
    required bool targetIsModel,
    required GameRole observerRole,
    bool isDevMode = false,
  }) {
    if (!targetIsModel) return false;
    if (isDevMode) return true;
    if (observerRole == GameRole.wildChild) return true;
    return false;
  }

  static bool canSeeBearGrowl({
    required bool targetIsBearTamer,
    required bool bearGrowledThisMorning,
    required bool isDayTime,
    bool isDevMode = false,
  }) {
    if (!targetIsBearTamer) return false;
    if (!bearGrowledThisMorning) return false;
    if (isDevMode) return true;
    return isDayTime;
  }

  static bool canSeeRustyKnightContamination({
    required bool targetIsContaminated,
    required bool isObserverWolf,
    required bool isObserverContaminated,
    bool isDevMode = false,
  }) {
    if (!targetIsContaminated) return false;
    if (isDevMode) return true;
    if (isObserverContaminated) return true;
    if (isObserverWolf) return true;
    return false;
  }

  static bool canSeeSeerInspection({
    required GameRole observerRole,
    bool isDevMode = false,
  }) {
    if (isDevMode) return true;
    if (observerRole == GameRole.seer) return true;
    return false;
  }
}
