import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:rashed_app/core/speech/microphone_permission_service.dart';

class FakePermissionPlatform extends PermissionHandlerPlatform
    with MockPlatformInterfaceMixin {
  final statuses = <Permission, PermissionStatus>{};
  final afterRequest = <Permission, PermissionStatus>{};
  final requested = <Permission>[];

  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async =>
      statuses[permission] ?? PermissionStatus.denied;

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async {
    requested.addAll(permissions);
    return {
      for (final permission in permissions)
        permission: afterRequest[permission] ?? PermissionStatus.granted,
    };
  }

  @override
  Future<bool> openAppSettings() async => true;
}

void main() {
  late FakePermissionPlatform platform;

  setUp(() {
    platform = FakePermissionPlatform();
    PermissionHandlerPlatform.instance = platform;
  });

  test('does not prompt when microphone is already granted', () async {
    platform.statuses[Permission.microphone] = PermissionStatus.granted;
    final service =
        PermissionHandlerMicrophoneService(needsSpeechPermission: false);

    expect(await service.request(), MicrophonePermissionResult.granted);
    expect(platform.requested, isEmpty);
  });

  test('android asks for the microphone only', () async {
    final service =
        PermissionHandlerMicrophoneService(needsSpeechPermission: false);

    expect(await service.request(), MicrophonePermissionResult.granted);
    expect(platform.requested, [Permission.microphone]);
  });

  test('ios asks for microphone then speech, once each', () async {
    final service =
        PermissionHandlerMicrophoneService(needsSpeechPermission: true);

    expect(await service.request(), MicrophonePermissionResult.granted);
    expect(platform.requested, [Permission.microphone, Permission.speech]);
  });

  test('a denied request reports denied and stops asking', () async {
    platform.afterRequest[Permission.microphone] = PermissionStatus.denied;
    final service =
        PermissionHandlerMicrophoneService(needsSpeechPermission: true);

    expect(await service.request(), MicrophonePermissionResult.denied);
    expect(platform.requested, [Permission.microphone]);
  });

  test('permanently denied or restricted never shows a prompt', () async {
    for (final status in [
      PermissionStatus.permanentlyDenied,
      PermissionStatus.restricted,
    ]) {
      platform.requested.clear();
      platform.statuses[Permission.microphone] = status;
      final service =
          PermissionHandlerMicrophoneService(needsSpeechPermission: false);

      expect(
        await service.request(),
        MicrophonePermissionResult.permanentlyDenied,
      );
      expect(platform.requested, isEmpty);
    }
  });

  test('a request that becomes permanently denied reports it', () async {
    platform.afterRequest[Permission.microphone] =
        PermissionStatus.permanentlyDenied;
    final service =
        PermissionHandlerMicrophoneService(needsSpeechPermission: false);

    expect(
      await service.request(),
      MicrophonePermissionResult.permanentlyDenied,
    );
  });
}
