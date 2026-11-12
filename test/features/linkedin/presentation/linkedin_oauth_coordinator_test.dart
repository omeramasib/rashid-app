import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/usecases/usecase.dart';
import 'package:rashed_app/features/linkedin/data/linkedin_authorization_launcher.dart';
import 'package:rashed_app/features/linkedin/data/linkedin_link_source.dart';
import 'package:rashed_app/features/linkedin/data/linkedin_pending_share_store.dart';
import 'package:rashed_app/features/linkedin/domain/entities/linkedin_connection_status.dart';
import 'package:rashed_app/features/linkedin/domain/entities/linkedin_share_preview.dart';
import 'package:rashed_app/features/linkedin/domain/linkedin_app_return_url.dart';
import 'package:rashed_app/features/linkedin/domain/usecases/disconnect_linkedin_usecase.dart';
import 'package:rashed_app/features/linkedin/domain/usecases/get_linkedin_status_usecase.dart';
import 'package:rashed_app/features/linkedin/domain/usecases/mark_linkedin_share_deleted_usecase.dart';
import 'package:rashed_app/features/linkedin/domain/usecases/preview_linkedin_share_usecase.dart';
import 'package:rashed_app/features/linkedin/domain/usecases/publish_linkedin_share_usecase.dart';
import 'package:rashed_app/features/linkedin/domain/usecases/start_linkedin_oauth_usecase.dart';
import 'package:rashed_app/features/linkedin/presentation/cubit/linkedin_share_cubit.dart';
import 'package:rashed_app/features/linkedin/presentation/cubit/linkedin_share_state.dart';
import 'package:rashed_app/features/linkedin/presentation/linkedin_oauth_coordinator.dart';

class MockStatus extends Mock implements GetLinkedInStatusUseCase {}

class MockStart extends Mock implements StartLinkedInOAuthUseCase {}

class MockPreview extends Mock implements PreviewLinkedInShareUseCase {}

class MockPublish extends Mock implements PublishLinkedInShareUseCase {}

class MockMarkDeleted extends Mock implements MarkLinkedInShareDeletedUseCase {}

class MockDisconnect extends Mock implements DisconnectLinkedInUseCase {}

class MemoryPendingShare implements LinkedInPendingShareStore {
  String? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> save(String simulationId) async => value = simulationId;
}

class FakeLinks implements LinkedInLinkSource {
  Uri? initial;
  final controller = StreamController<Uri>.broadcast();

  @override
  Future<Uri?> getInitialLink() async => initial;

  @override
  Stream<Uri> get uriLinkStream => controller.stream;
}

void main() {
  const active = LinkedInConnectionStatus(
    connected: true,
    publishingEnabled: true,
    reauthorizationRequired: false,
    connectionStatus: LinkedInConnectionState.active,
  );
  const preview = LinkedInSharePreview(
    previewId: 'preview-1',
    simulationId: 'sim-owned',
    text: 'Server-generated post',
    contentSha256: 'hash-1',
  );

  late FakeLinks links;
  late MemoryPendingShare pending;
  late MockPreview previewShare;
  late MockPublish publish;
  late LinkedInShareCubit cubit;
  late LinkedInOAuthCoordinator coordinator;

  setUpAll(() {
    registerFallbackValue(NoParams());
    registerFallbackValue(
      const LinkedInSimulationParams(simulationId: 'sim'),
    );
    registerFallbackValue(const PublishLinkedInParams(
      previewId: 'preview',
      simulationId: 'sim',
      contentSha256: 'hash',
    ));
  });

  setUp(() {
    links = FakeLinks();
    pending = MemoryPendingShare()..value = 'sim-owned';
    previewShare = MockPreview();
    publish = MockPublish();
    final status = MockStatus();
    when(() => status(any())).thenAnswer((_) async => const Right(active));
    when(() => previewShare(any()))
        .thenAnswer((_) async => const Right(preview));
    cubit = LinkedInShareCubit(
      getStatus: status,
      startOAuth: MockStart(),
      previewShare: previewShare,
      publishShare: publish,
      markDeleted: MockMarkDeleted(),
      disconnectLinkedIn: MockDisconnect(),
      pendingShare: pending,
      launcher: _ClosedLauncher(),
      returnGate: LinkedInReturnGate(),
    );
    coordinator = LinkedInOAuthCoordinator(
      links: links,
      cubit: cubit,
      gate: cubit.returnGate,
    );
  });

  tearDown(() async {
    await coordinator.dispose();
    await cubit.close();
    await links.controller.close();
  });

  test('a cold start handles one return and ignores a duplicate', () async {
    links.initial = Uri.parse(
      '${LinkedInAppReturnUrl.value}?result=connected&simulation_id=other&code=secret',
    );

    await coordinator.start();
    await _until(cubit, LinkedInSharePhase.previewReady);

    links.controller.add(links.initial!);
    await Future<void>.delayed(Duration.zero);

    verify(
      () => previewShare(
        const LinkedInSimulationParams(simulationId: 'sim-owned'),
      ),
    ).called(1);
    verifyNever(() => publish(any()));
    expect(cubit.state.simulationId, 'sim-owned');
  });

  test('a clerk redirect does not start publishing', () async {
    links.initial = Uri.parse('rashedapp://oauth-callback?result=connected');

    await coordinator.start();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.phase, LinkedInSharePhase.initial);
    verifyNever(() => previewShare(any()));
    verifyNever(() => publish(any()));
  });
}

Future<void> _until(LinkedInShareCubit cubit, LinkedInSharePhase phase) async {
  if (cubit.state.phase == phase) return;
  await cubit.stream.firstWhere((state) => state.phase == phase);
}

class _ClosedLauncher implements LinkedInAuthorizationLauncher {
  @override
  Future<bool> open(Uri url) async => false;
}
