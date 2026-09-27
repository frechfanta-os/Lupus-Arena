import 'dart:math' as math;

class AppUpdateInfo {
  final String version;
  final String rawTag;
  final String releaseNotes;
  final String downloadUrl;
  final String fileName;
  final int fileSize;
  final String currentVersion;
  final String matchedAbi;
  final bool hasUpdate;

  String get tagName => rawTag;
  String get changelog => releaseNotes;
  String get apkUrl => downloadUrl;

  const AppUpdateInfo({
    required this.version,
    required this.rawTag,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.fileName,
    required this.fileSize,
    required this.currentVersion,
    this.matchedAbi = 'universal',
    this.hasUpdate = true,
  });
}

typedef UpdateInfo = AppUpdateInfo;

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  static const String defaultOwner = 'Anisghd-lab';
  static const String defaultRepo = 'LUPUS-ARENA';

  static bool isRemoteVersionGreater(String remote, String local) {
    final cleanRemote = remote.trim().replaceFirst(RegExp(r'^[vV]'), '');
    final cleanLocal = local.trim().replaceFirst(RegExp(r'^[vV]'), '');

    if (cleanRemote.isEmpty || cleanLocal.isEmpty) return false;
    if (cleanRemote == cleanLocal) return false;

    final remoteParts = cleanRemote.split('+');
    final localParts = cleanLocal.split('+');

    final remoteSemver = remoteParts[0]
        .split('.')
        .map((e) => int.tryParse(RegExp(r'\d+').firstMatch(e)?.group(0) ?? '') ?? 0)
        .toList();
    final localSemver = localParts[0]
        .split('.')
        .map((e) => int.tryParse(RegExp(r'\d+').firstMatch(e)?.group(0) ?? '') ?? 0)
        .toList();

    final maxLen = math.max(remoteSemver.length, localSemver.length);
    for (int i = 0; i < maxLen; i++) {
      final r = i < remoteSemver.length ? remoteSemver[i] : 0;
      final l = i < localSemver.length ? localSemver[i] : 0;
      if (r > l) return true;
      if (r < l) return false;
    }

    if (remoteParts.length > 1 && localParts.length > 1) {
      final rBuild = int.tryParse(RegExp(r'\d+').firstMatch(remoteParts[1])?.group(0) ?? '') ?? 0;
      final lBuild = int.tryParse(RegExp(r'\d+').firstMatch(localParts[1])?.group(0) ?? '') ?? 0;
      return rBuild > lBuild;
    } else if (remoteParts.length > 1) {
      return true;
    }

    return false;
  }

  Future<AppUpdateInfo?> checkForUpdate({
    String owner = defaultOwner,
    String repo = defaultRepo,
  }) async {
    return null;
  }
}
