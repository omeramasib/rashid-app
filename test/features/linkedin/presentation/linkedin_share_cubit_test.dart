import 'dart:async';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/core/usecases/usecase.dart';
import 'package:rashed_app/features/linkedin/data/linkedin_authorization_launcher.dart';
import 'package:rashed_app/features/linkedin/data/linkedin_pending_share_store.dart';
import 'package:rashed_app/features/linkedin/domain/entities/linkedin_connection_status.dart';
import 'package:rashed_app/features/linkedin/domain/entities/linkedin_oauth_start.dart';
import 'package:rashed_app/features/linkedin/domain/entities/linkedin_publish_result.dart';
import 'package:rashed_app/features/linkedin/domain/entities/linkedin_share_preview.dart';
import 'package:rashed_app/features/linkedin/domain/linkedin_app_return_url.dart';
import 'package:rashed_app/features/linkedin/domain/linkedin_oauth_return_link.dart';
import 'package:rashed_app/features/linkedin/domain/usecases/disconnect_linkedin_usecase.dart';
import 'package:rashed_app/features/linkedin/domain/usecases/get_linkedin_status_usecase.dart';
import 'package:rashed_app/features/linkedin/domain/usecases/preview_linkedin_share_usecase.dart';
import 'package:rashed_app/features/linkedin/domain/usecases/publish_linkedin_share_usecase.dart';
import 'package:rashed_app/features/linkedin/domain/usecases/start_linkedin_oauth_usecase.dart';
import 'package:rashed_app/features/linkedin/presentation/cubit/linkedin_share_cubit.dart';
import 'package:rashed_app/features/linkedin/presentation/cubit/linkedin_share_state.dart';

class MockStatus extends Mock implements GetLinkedInStatusUseCase {}

class MockStart extends Mock implements StartLinkedInOAuthUseCase {}

class MockPreview extends Mock implements PreviewLinkedInShareUseCase {}

class MockPublish extends Mock implements PublishLinkedInShareUseCase {}

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

class FakeLauncher implements LinkedInAuthorizationLauncher {
  Uri? opened;
  var opens = true;

  @override
  Future<bool> open(Uri url) async {
    opened = url;
    return opens;
  }
}

void main() {
  const disconnected = LinkedInConnectionStatus(
    connected: false,
    publishingEnabled: false,
    reauthorizationRequired: false,
    connectionStatus: LinkedInConnectionState.notConnected,
  );
  const signedInWithoutPublishing = LinkedInConnectionStatus(
    connected: true,
    publishingEnabled: false,
    reauthorizationRequired: false,
    connectionStatus: LinkedInConnectionState.active,
  );
  const active = LinkedInConnectionStatus(
    connected: true,
    publishingEnabled: true,
    reauthorizationRequired: false,
    connectionStatus: LinkedInConnectionState.active,
    name: 'Rashed User',
  );
  const expired = LinkedInConnectionStatus(
    connected: true,
    publishingEnabled: false,
    reauthorizationRequired: true,
    connectionStatus: LinkedInConnectionState.expired,
  );
  const revoked = LinkedInConnectionStatus(
    connected: false,
    publishingEnabled: false,
    reauthorizationRequired: true,
    connectionStatus: LinkedInConnectionState.revoked,
  );
  const preview = LinkedInSharePreview(
    previewId: 'preview-1',
    simulationId: 'sim-1',
    text: 'Server-generated post',
    contentSha256: 'hash-1',
  );
  const oauth = LinkedInOAuthStart(
    authorizationUrl:
        'https://www.linkedin.com/oauth/v2/authorization?client_id=app',
  );
  final connectedReturn = LinkedInOAuthReturnLink.tryParse(Uri.parse(
    '${LinkedInAppReturnUrl.value}?result=connected&simulation_id=other&access_token=secret',
  ))!;

  late MockStatus status;
  late MockStart start;
  late MockPreview previewShare;
  late MockPublish publish;
  late MockDisconnect disconnect;
  late MemoryPendingShare pending;
  late FakeLauncher launcher;
  late LinkedInReturnGate gate;

  setUpAll(() {
    registerFallbackValue(NoParams());
    registerFallbackValue(const LinkedInSimulationParams(simulationId: 'sim'));
    registerFallbackValue(const PublishLinkedInParams(
      previewId: 'preview',
      simulationId: 'sim',
      contentSha256: 'hash',
    ));
  });

  setUp(() {
    status = MockStatus();
    start = MockStart();
    previewShare = MockPreview();
    publish = MockPublish();
    disconnect = MockDisconnect();
    pending = MemoryPendingShare();
    launcher = FakeLauncher();
    gate = LinkedInReturnGate();
  });

  LinkedInShareCubit build() {
    return LinkedInShareCubit(
      getStatus: status,
      startOAuth: start,
      previewShare: previewShare,
      publishShare: publish,
      disconnectLinkedIn: disconnect,
      pendingShare: pending,
      launcher: launcher,
      returnGate: gate,
    );
  }

  void stubStatus(LinkedInConnectionStatus connection) {
    when(() => status(any())).thenAnswer((_) async => Right(connection));
  }

  blocTest<LinkedInShareCubit, LinkedInShareState>(
    'an email user with no LinkedIn connection is asked to connect',
    build: build,
    setUp: () => stubStatus(disconnected),
    act: (cubit) => cubit.begin(simulationId: 'sim-1', resultLabel: '82'),
    expect: () => const [
      LinkedInShareState(
        phase: LinkedInSharePhase.checkingConnection,
        simulationId: 'sim-1',
        resultLabel: '82',
      ),
      LinkedInShareState(
        phase: LinkedInSharePhase.connectionRequired,
        simulationId: 'sim-1',
        resultLabel: '82',
        connection: disconnected,
      ),
    ],
    verify: (_) {
      verifyNever(() => previewShare(any()));
      verifyNever(() => publish(any()));
    },
  );

  blocTest<LinkedInShareCubit, LinkedInShareState>(
    'a LinkedIn sign-in without publishing permission cannot preview',
    build: build,
    setUp: () => stubStatus(signedInWithoutPublishing),
    act: (cubit) => cubit.begin(simulationId: 'sim-1'),
    expect: () => const [
      LinkedInShareState(
        phase: LinkedInSharePhase.checkingConnection,
        simulationId: 'sim-1',
      ),
      LinkedInShareState(
        phase: LinkedInSharePhase.connectionRequired,
        simulationId: 'sim-1',
        connection: signedInWithoutPublishing,
      ),
    ],
    verify: (_) => verifyNever(() => previewShare(any())),
  );

  blocTest<LinkedInShareCubit, LinkedInShareState>(
    'expired authorization asks for reconnection and does not disconnect',
    build: build,
    setUp: () => stubStatus(expired),
    act: (cubit) => cubit.begin(simulationId: 'sim-1'),
    verify: (_) {
      verifyNever(() => disconnect(any()));
      verifyNever(() => previewShare(any()));
    },
    expect: () => const [
      LinkedInShareState(
        phase: LinkedInSharePhase.checkingConnection,
        simulationId: 'sim-1',
      ),
      LinkedInShareState(
        phase: LinkedInSharePhase.connectionRequired,
        simulationId: 'sim-1',
        connection: expired,
      ),
    ],
  );

  blocTest<LinkedInShareCubit, LinkedInShareState>(
    'revoked authorization asks for reconnection',
    build: build,
    setUp: () => stubStatus(revoked),
    act: (cubit) => cubit.begin(simulationId: 'sim-1'),
    expect: () => const [
      LinkedInShareState(
        phase: LinkedInSharePhase.checkingConnection,
        simulationId: 'sim-1',
      ),
      LinkedInShareState(
        phase: LinkedInSharePhase.connectionRequired,
        simulationId: 'sim-1',
        connection: revoked,
      ),
    ],
  );

  blocTest<LinkedInShareCubit, LinkedInShareState>(
    'a connected publisher loads the server preview and does not publish',
    build: build,
    setUp: () {
      stubStatus(active);
      when(() => previewShare(any()))
          .thenAnswer((_) async => const Right(preview));
    },
    act: (cubit) => cubit.begin(simulationId: 'sim-1'),
    expect: () => const [
      LinkedInShareState(
        phase: LinkedInSharePhase.checkingConnection,
        simulationId: 'sim-1',
      ),
      LinkedInShareState(
        phase: LinkedInSharePhase.loadingPreview,
        simulationId: 'sim-1',
        connection: active,
      ),
      LinkedInShareState(
        phase: LinkedInSharePhase.previewReady,
        simulationId: 'sim-1',
        connection: active,
        preview: preview,
      ),
    ],
    verify: (_) {
      verify(
        () =>
            previewShare(const LinkedInSimulationParams(simulationId: 'sim-1')),
      ).called(1);
      verifyNever(() => publish(any()));
    },
  );

  blocTest<LinkedInShareCubit, LinkedInShareState>(
    'publish sends the preview once and keeps a verified post url',
    build: build,
    setUp: () {
      stubStatus(active);
      when(() => previewShare(any()))
          .thenAnswer((_) async => const Right(preview));
      when(() => publish(any())).thenAnswer(
        (_) async => const Right(LinkedInPublishResult(
          postUrl: 'https://www.linkedin.com/feed/update/1',
        )),
      );
    },
    act: (cubit) async {
      await cubit.begin(simulationId: 'sim-1');
      await cubit.publish();
      await cubit.publish();
    },
    verify: (_) {
      verify(
        () => publish(const PublishLinkedInParams(
          previewId: 'preview-1',
          simulationId: 'sim-1',
          contentSha256: 'hash-1',
        )),
      ).called(1);
    },
    expect: () => const [
      LinkedInShareState(
        phase: LinkedInSharePhase.checkingConnection,
        simulationId: 'sim-1',
      ),
      LinkedInShareState(
        phase: LinkedInSharePhase.loadingPreview,
        simulationId: 'sim-1',
        connection: active,
      ),
      LinkedInShareState(
        phase: LinkedInSharePhase.previewReady,
        simulationId: 'sim-1',
        connection: active,
        preview: preview,
      ),
      LinkedInShareState(
        phase: LinkedInSharePhase.publishing,
        simulationId: 'sim-1',
        connection: active,
        preview: preview,
      ),
      LinkedInShareState(
        phase: LinkedInSharePhase.published,
        simulationId: 'sim-1',
        connection: active,
        preview: preview,
        postUrl: 'https://www.linkedin.com/feed/update/1',
      ),
    ],
  );

  blocTest<LinkedInShareCubit, LinkedInShareState>(
    'a missing post url is not replaced with a constructed one',
    build: build,
    setUp: () {
      stubStatus(active);
      when(() => previewShare(any()))
          .thenAnswer((_) async => const Right(preview));
      when(() => publish(any())).thenAnswer(
        (_) async => const Right(LinkedInPublishResult(postUrl: 'not a url')),
      );
    },
    act: (cubit) async {
      await cubit.begin(simulationId: 'sim-1');
      await cubit.publish();
    },
    expect: () => const [
      LinkedInShareState(
        phase: LinkedInSharePhase.checkingConnection,
        simulationId: 'sim-1',
      ),
      LinkedInShareState(
        phase: LinkedInSharePhase.loadingPreview,
        simulationId: 'sim-1',
        connection: active,
      ),
      LinkedInShareState(
        phase: LinkedInSharePhase.previewReady,
        simulationId: 'sim-1',
        connection: active,
        preview: preview,
      ),
      LinkedInShareState(
        phase: LinkedInSharePhase.publishing,
        simulationId: 'sim-1',
        connection: active,
        preview: preview,
      ),
      LinkedInShareState(
        phase: LinkedInSharePhase.published,
        simulationId: 'sim-1',
        connection: active,
        preview: preview,
      ),
    ],
  );

  blocTest<LinkedInShareCubit, LinkedInShareState>(
    'publish 403 offers reconnection and does not publish again',
    build: build,
    setUp: () {
      stubStatus(active);
      when(() => previewShare(any()))
          .thenAnswer((_) async => const Right(preview));
      when(() => publish(any())).thenAnswer(
        (_) async => const Left(ForbiddenFailure('denied')),
      );
    },
    act: (cubit) async {
      await cubit.begin(simulationId: 'sim-1');
      await cubit.publish();
      await cubit.publish();
    },
    verify: (_) => verify(() => publish(any())).called(1),
    expect: () => [
      const LinkedInShareState(
        phase: LinkedInSharePhase.checkingConnection,
        simulationId: 'sim-1',
      ),
      const LinkedInShareState(
        phase: LinkedInSharePhase.loadingPreview,
        simulationId: 'sim-1',
        connection: active,
      ),
      const LinkedInShareState(
        phase: LinkedInSharePhase.previewReady,
        simulationId: 'sim-1',
        connection: active,
        preview: preview,
      ),
      const LinkedInShareState(
        phase: LinkedInSharePhase.publishing,
        simulationId: 'sim-1',
        connection: active,
        preview: preview,
      ),
      const LinkedInShareState(
        phase: LinkedInSharePhase.error,
        simulationId: 'sim-1',
        connection: active,
        notice: LinkedInShareNotice.reconnect,
      ),
    ],
  );

  blocTest<LinkedInShareCubit, LinkedInShareState>(
    'publish 409 offers a fresh preview and does not publish again',
    build: build,
    setUp: () {
      stubStatus(active);
      when(() => previewShare(any()))
          .thenAnswer((_) async => const Right(preview));
      when(() => publish(any())).thenAnswer(
        (_) async => const Left(ConflictFailure('expired')),
      );
    },
    act: (cubit) async {
      await cubit.begin(simulationId: 'sim-1');
      await cubit.publish();
      await cubit.refreshPreview();
    },
    verify: (_) {
      verify(() => publish(any())).called(1);
      verify(() => previewShare(any())).called(2);
    },
  );

  blocTest<LinkedInShareCubit, LinkedInShareState>(
    'publish 502 does not submit another publish',
    build: build,
    setUp: () {
      stubStatus(active);
      when(() => previewShare(any()))
          .thenAnswer((_) async => const Right(preview));
      when(() => publish(any())).thenAnswer(
        (_) async => const Left(UpstreamFailure('unconfirmed')),
      );
    },
    act: (cubit) async {
      await cubit.begin(simulationId: 'sim-1');
      await cubit.publish();
      await cubit.publish();
      await cubit.refreshPreview();
    },
    verify: (_) => verify(() => publish(any())).called(1),
    skip: 4,
    expect: () => const [
      LinkedInShareState(
        phase: LinkedInSharePhase.error,
        simulationId: 'sim-1',
        connection: active,
        notice: LinkedInShareNotice.publishUnconfirmed,
      ),
    ],
  );

  blocTest<LinkedInShareCubit, LinkedInShareState>(
    'publish 503 stays unavailable without another publish',
    build: build,
    setUp: () {
      stubStatus(active);
      when(() => previewShare(any()))
          .thenAnswer((_) async => const Right(preview));
      when(() => publish(any())).thenAnswer(
        (_) async => const Left(ServiceUnavailableFailure('down')),
      );
    },
    act: (cubit) async {
      await cubit.begin(simulationId: 'sim-1');
      await cubit.publish();
      await cubit.publish();
    },
    verify: (_) => verify(() => publish(any())).called(1),
    skip: 4,
    expect: () => const [
      LinkedInShareState(
        phase: LinkedInSharePhase.error,
        simulationId: 'sim-1',
        connection: active,
        notice: LinkedInShareNotice.unavailable,
      ),
    ],
  );

  blocTest<LinkedInShareCubit, LinkedInShareState>(
    'a cold start uses the stored simulation and does not publish',
    build: build,
    setUp: () {
      stubStatus(active);
      when(() => previewShare(any()))
          .thenAnswer((_) async => const Right(preview));
      pending.value = 'sim-1';
    },
    act: (cubit) => cubit.onOAuthReturn(connectedReturn),
    verify: (_) {
      verify(
        () =>
            previewShare(const LinkedInSimulationParams(simulationId: 'sim-1')),
      ).called(1);
      verifyNever(() => publish(any()));
      expect(pending.value, isNull);
    },
    expect: () => const [
      LinkedInShareState(
        phase: LinkedInSharePhase.checkingConnection,
        simulationId: 'sim-1',
        returnGeneration: 1,
      ),
      LinkedInShareState(
        phase: LinkedInSharePhase.loadingPreview,
        simulationId: 'sim-1',
        connection: active,
        returnGeneration: 1,
      ),
      LinkedInShareState(
        phase: LinkedInSharePhase.previewReady,
        simulationId: 'sim-1',
        connection: active,
        preview: preview,
        returnGeneration: 1,
      ),
    ],
  );

  blocTest<LinkedInShareCubit, LinkedInShareState>(
    'a duplicate return does not request another preview',
    build: build,
    setUp: () {
      stubStatus(active);
      when(() => previewShare(any()))
          .thenAnswer((_) async => const Right(preview));
      pending.value = 'sim-1';
    },
    act: (cubit) async {
      await cubit.onOAuthReturn(connectedReturn);
      await cubit.onOAuthReturn(connectedReturn);
    },
    verify: (_) => verify(() => previewShare(any())).called(1),
  );

  blocTest<LinkedInShareCubit, LinkedInShareState>(
    'oauth cancellation does not preview or publish',
    build: build,
    setUp: () => pending.value = 'sim-1',
    act: (cubit) => cubit.onOAuthReturn(
      LinkedInOAuthReturnLink.tryParse(
        Uri.parse('${LinkedInAppReturnUrl.value}?result=cancelled'),
      )!,
    ),
    verify: (_) {
      verifyNever(() => previewShare(any()));
      verifyNever(() => publish(any()));
      verifyNever(() => status(any()));
    },
    expect: () => const [
      LinkedInShareState(
        phase: LinkedInSharePhase.error,
        simulationId: 'sim-1',
        notice: LinkedInShareNotice.cancelled,
        returnGeneration: 1,
      ),
    ],
  );

  blocTest<LinkedInShareCubit, LinkedInShareState>(
    'an invalid oauth state does not publish',
    build: build,
    setUp: () => pending.value = 'sim-1',
    act: (cubit) => cubit.onOAuthReturn(
      LinkedInOAuthReturnLink.tryParse(
        Uri.parse('${LinkedInAppReturnUrl.value}?result=invalid_state'),
      )!,
    ),
    verify: (_) => verifyNever(() => publish(any())),
    expect: () => const [
      LinkedInShareState(
        phase: LinkedInSharePhase.error,
        simulationId: 'sim-1',
        notice: LinkedInShareNotice.invalidState,
        returnGeneration: 1,
      ),
    ],
  );

  blocTest<LinkedInShareCubit, LinkedInShareState>(
    'an account conflict does not publish',
    build: build,
    setUp: () => pending.value = 'sim-1',
    act: (cubit) => cubit.onOAuthReturn(
      LinkedInOAuthReturnLink.tryParse(
        Uri.parse('${LinkedInAppReturnUrl.value}?result=account_conflict'),
      )!,
    ),
    verify: (_) => verifyNever(() => publish(any())),
    expect: () => const [
      LinkedInShareState(
        phase: LinkedInSharePhase.error,
        simulationId: 'sim-1',
        notice: LinkedInShareNotice.accountConflict,
        returnGeneration: 1,
      ),
    ],
  );

  blocTest<LinkedInShareCubit, LinkedInShareState>(
    'a return without a pending share is ignored',
    build: build,
    act: (cubit) => cubit.onOAuthReturn(connectedReturn),
    verify: (_) {
      verifyNever(() => status(any()));
      verifyNever(() => publish(any()));
    },
    expect: () => const <LinkedInShareState>[],
  );

  blocTest<LinkedInShareCubit, LinkedInShareState>(
    'connect opens the server authorization url and waits',
    build: build,
    setUp: () {
      stubStatus(disconnected);
      when(() => start(any())).thenAnswer((_) async => const Right(oauth));
    },
    act: (cubit) async {
      await cubit.begin(simulationId: 'sim-1');
      await cubit.connect();
    },
    verify: (_) {
      expect(
        launcher.opened.toString(),
        'https://www.linkedin.com/oauth/v2/authorization?client_id=app',
      );
      expect(pending.value, 'sim-1');
      verifyNever(() => publish(any()));
    },
    expect: () => const [
      LinkedInShareState(
        phase: LinkedInSharePhase.checkingConnection,
        simulationId: 'sim-1',
      ),
      LinkedInShareState(
        phase: LinkedInSharePhase.connectionRequired,
        simulationId: 'sim-1',
        connection: disconnected,
      ),
      LinkedInShareState(
        phase: LinkedInSharePhase.startingOAuth,
        simulationId: 'sim-1',
        connection: disconnected,
      ),
      LinkedInShareState(
        phase: LinkedInSharePhase.waitingForOAuthReturn,
        simulationId: 'sim-1',
        connection: disconnected,
      ),
    ],
  );

  test('duplicate publish taps while the request is open call publish once',
      () async {
    stubStatus(active);
    when(() => previewShare(any()))
        .thenAnswer((_) async => const Right(preview));
    final gate = Completer<Either<Failure, LinkedInPublishResult>>();
    when(() => publish(any())).thenAnswer((_) => gate.future);
    final cubit = build();
    await cubit.begin(simulationId: 'sim-1');
    final first = cubit.publish();
    final second = cubit.publish();
    gate.complete(const Right(LinkedInPublishResult()));
    await Future.wait([first, second]);
    verify(() => publish(any())).called(1);
    await cubit.close();
  });

  test('removed LinkedIn endpoints are not referenced', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in files) {
      final source = file.readAsStringSync();
      expect(source.contains('/api/v1/linkedin/connect'), isFalse,
          reason: file.path);
      expect(
        source.contains('share-last-interview-result'),
        isFalse,
        reason: file.path,
      );
      expect(
        source.contains('/api/v1/linkedin/oauth/callback'),
        isFalse,
        reason: file.path,
      );
    }
  });
}
