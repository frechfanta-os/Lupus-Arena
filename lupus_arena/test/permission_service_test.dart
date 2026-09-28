import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lupus_arena/services/lupus_permission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('LupusPermissionService hasRequestedPermissions returns false initially', () async {
    final service = LupusPermissionService();
    final requested = await service.hasRequestedPermissions();
    expect(requested, isFalse);
  });

  test('LupusPermissionService persists permissions choice in SharedPreferences', () async {
    final service = LupusPermissionService();

    SharedPreferences.setMockInitialValues({
      'lupus_permissions_requested_once': true,
      'lupus_permission_mic_granted': true,
      'lupus_permission_notification_granted': true,
      'lupus_permission_bluetooth_granted': true,
    });

    expect(await service.hasRequestedPermissions(), isTrue);

    await service.resetPermissionsChoice();
    expect(await service.hasRequestedPermissions(), isFalse);
  });

  test('LupusPermissionService persists terms acceptance correctly', () async {
    final service = LupusPermissionService();

    expect(await service.hasAcceptedTerms(), isFalse);

    await service.setTermsAccepted(true);
    expect(await service.hasAcceptedTerms(), isTrue);
    expect(service.isTermsAcceptedNotifier.value, isTrue);

    await service.resetPermissionsChoice();
    expect(await service.hasAcceptedTerms(), isFalse);
    expect(service.isTermsAcceptedNotifier.value, isFalse);
  });
}
