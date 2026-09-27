import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class ServerTimeService {
  static final ServerTimeService _instance = ServerTimeService._internal();
  factory ServerTimeService() => _instance;
  ServerTimeService._internal();

  int _serverTimeOffsetMs = 0;
  bool _isInitialized = false;
  StreamSubscription<DatabaseEvent>? _offsetSubscription;
  final ValueNotifier<int> offsetNotifier = ValueNotifier<int>(0);

  int get offsetMs => _serverTimeOffsetMs;

  int get currentServerEstimatedTime =>
      DateTime.now().millisecondsSinceEpoch + _serverTimeOffsetMs;

  void initialize(FirebaseDatabase database) {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      _offsetSubscription =
          database.ref('.info/serverTimeOffset').onValue.listen((event) {
        final val = event.snapshot.value;
        if (val is num) {
          _serverTimeOffsetMs = val.toInt();
          offsetNotifier.value = _serverTimeOffsetMs;
          debugPrint(
            '[ServerTimeService] Dérive d\'horloge Firebase RTDB synchronisée : ${_serverTimeOffsetMs}ms',
          );
        }
      }, onError: (err) {
        debugPrint('[ServerTimeService] Erreur d\'écoute offset : $err');
      });
    } catch (e) {
      debugPrint('[ServerTimeService] Exception initialisation : $e');
    }
  }

  int calculateRemainingMs(int? phaseEndsAt, {int fallbackDurationMs = 30000}) {
    if (phaseEndsAt == null) {
      return fallbackDurationMs;
    }
    final remaining = phaseEndsAt - currentServerEstimatedTime;
    return max(0, remaining);
  }

  int calculateRemainingSeconds(int? phaseEndsAt, {int fallbackSeconds = 30}) {
    final remMs = calculateRemainingMs(
      phaseEndsAt,
      fallbackDurationMs: fallbackSeconds * 1000,
    );
    return (remMs / 1000.0).ceil();
  }

  Stream<int> streamRemainingSeconds(int? phaseEndsAt, {int fallbackSeconds = 30}) async* {
    final startServerTime = currentServerEstimatedTime;
    final effectiveTargetMs = phaseEndsAt ?? (startServerTime + fallbackSeconds * 1000);

    int lastValue = calculateRemainingSeconds(phaseEndsAt, fallbackSeconds: fallbackSeconds);
    yield lastValue;

    while (true) {
      await Future.delayed(const Duration(milliseconds: 500));
      final now = currentServerEstimatedTime;
      final target = phaseEndsAt ?? effectiveTargetMs;
      final remainingMs = max(0, target - now);
      final current = (remainingMs / 1000.0).ceil();

      if (current != lastValue) {
        lastValue = current;
        yield current;
      }
      if (current <= 0) {
        yield 0;
        break;
      }
    }
  }

  void dispose() {
    _offsetSubscription?.cancel();
    _offsetSubscription = null;
    _isInitialized = false;
  }
}
