import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class RoomPresenceService {
  final FirebaseDatabase _database;

  const RoomPresenceService(this._database);

  Future<void> updatePresence({
    required String roomCode,
    required String userId,
    bool? isOnline,
    bool? isMuted,
    int? micVolume,
    bool? isSpeaking,
  }) async {
    if (roomCode.isEmpty || userId.isEmpty) return;
    final updates = <String, dynamic>{
      'lastSeen': ServerValue.timestamp,
    };
    if (isOnline != null) updates['isOnline'] = isOnline;
    if (isMuted != null) updates['isMuted'] = isMuted;
    if (micVolume != null) updates['micVolume'] = micVolume;
    if (isSpeaking != null) updates['isSpeaking'] = isSpeaking;
    try {
      await _database.ref('rooms/$roomCode/presence/$userId').update(updates);
    } catch (e) {
      debugPrint('[RoomPresenceService Error] updatePresence: $e');
    }
  }

  Future<void> setupOnDisconnectHooks({
    required String roomCode,
    required String userId,
  }) async {
    try {
      final playerRef = _database.ref('rooms/$roomCode/players/$userId');
      await playerRef.child('isOnline').onDisconnect().set(false);
      await playerRef.child('lastSeen').onDisconnect().set(ServerValue.timestamp);

      final presenceRef = _database.ref('rooms/$roomCode/presence/$userId');
      await presenceRef.child('isOnline').onDisconnect().set(false);
      await presenceRef.child('lastSeen').onDisconnect().set(ServerValue.timestamp);
    } catch (e) {
      debugPrint('[RoomPresenceService Error] setupOnDisconnectHooks: $e');
    }
  }

  Future<void> cancelOnDisconnectHooks({
    required String roomCode,
    required String userId,
  }) async {
    try {
      final playerRef = _database.ref('rooms/$roomCode/players/$userId');
      await playerRef.child('isOnline').onDisconnect().cancel();
      await playerRef.child('lastSeen').onDisconnect().cancel();

      final presenceRef = _database.ref('rooms/$roomCode/presence/$userId');
      await presenceRef.child('isOnline').onDisconnect().cancel();
      await presenceRef.child('lastSeen').onDisconnect().cancel();
    } catch (_) {}
  }
}
