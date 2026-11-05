import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/app_localizations.dart';
import 'package:rashed_app/core/error/failures.dart';
import 'package:rashed_app/core/usecases/usecase.dart';
import 'package:rashed_app/features/linkedin/data/linkedin_authorization_launcher.dart';
import 'package:rashed_app/features/linkedin/data/linkedin_pending_share_store.dart';
import 'package:rashed_app/features/linkedin/domain/entities/linkedin_connection_status.dart';
import 'package:rashed_app/features/linkedin/domain/entities/linkedin_publish_result.dart';
import 'package:rashed_app/features/linkedin/domain/entities/linkedin_share_preview.dart';
import 'package:rashed_app/features/linkedin/domain/usecases/disconnect_linkedin_usecase.dart';
import 'package:rashed_app/features/linkedin/domain/usecases/get_linkedin_status_usecase.dart';
import 'package:rashed_app/features/linkedin/domain/usecases/preview_linkedin_share_usecase.dart';
import 'package:rashed_app/features/linkedin/domain/usecases/publish_linkedin_share_usecase.dart';
import 'package:rashed_app/features/linkedin/domain/usecases/start_linkedin_oauth_usecase.dart';
import 'package:rashed_app/features/linkedin/presentation/cubit/linkedin_share_cubit.dart';
import 'package:rashed_app/features/linkedin/presentation/linkedin_share_request.dart';
import 'package:rashed_app/features/linkedin/presentation/screens/linkedin_share_screen.dart';

class MockStatus extends Mock implements GetLinkedInStatusUseCase {}

class MockStart extends Mock implements StartLinkedInOAuthUseCase {}

class MockPreview extends Mock implements PreviewLinkedInShareUseCase {}

class MockPublish extends Mock implements PublishLinkedInShareUseCase {}

class MockDisconnect extends Mock implements DisconnectLinkedInUseCase {}

class _Pending implements LinkedInPendingShareStore {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> read() async => null;

  @override
  Future<void> save(String simulationId) async {}
}

class _Launcher implements LinkedInAuthorizationLauncher {
  @override
  Future<bool> open(Uri url) async => false;
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
    simulationId: 'sim-1',
    text: 'Exact server post',
    contentSha256: 'hash-1',
  );

  late MockPublish publish;
  late LinkedInShareCubit cubit;

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
    final status = MockStatus();
    final previewShare = MockPreview();
    publish = MockPublish();
    when(() => status(any())).thenAnswer((_) async => const Right(active));
    when(() => previewShare(any()))
        .thenAnswer((_) async => const Right(preview));
    cubit = LinkedInShareCubit(
      getStatus: status,
      startOAuth: MockStart(),
      previewShare: previewShare,
      publishShare: publish,
      disconnectLinkedIn: MockDisconnect(),
      pendingShare: _Pending(),
      launcher: _Launcher(),
      returnGate: LinkedInReturnGate(),
    );
  });

  tearDown(() => cubit.close());

  Future<void> pump(WidgetTester tester, Locale locale) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          settings: const RouteSettings(
            arguments: LinkedInShareRequest(
              simulationId: 'sim-1',
              resultLabel: '82',
            ),
          ),
          builder: (_) => LinkedInShareScreen(cubit: cubit),
        );
      },
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the server preview in English and publishes once',
      (tester) async {
    final gate = Completer<Either<Failure, LinkedInPublishResult>>();
    when(() => publish(any())).thenAnswer((_) => gate.future);
    await pump(tester, const Locale('en'));

    expect(find.text('Exact server post'), findsOneWidget);
    expect(find.text('Share on LinkedIn'), findsOneWidget);
    expect(find.text('82'), findsOneWidget);
    expect(
      find.text('This text will be published to your LinkedIn profile.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('linkedin_publish_button')));
    await tester.pump();

    verify(() => publish(any())).called(1);
    expect(find.text('Publishing'), findsOneWidget);

    gate.complete(const Right(LinkedInPublishResult(
      postUrl: 'https://www.linkedin.com/feed/update/1',
    )));
    await tester.pumpAndSettle();
    expect(find.text('Published successfully'), findsOneWidget);
    expect(find.byKey(const Key('linkedin_open_post')), findsOneWidget);
  });

  testWidgets('Arabic copy is used and a missing post url stays hidden',
      (tester) async {
    when(() => publish(any())).thenAnswer(
      (_) async => const Right(LinkedInPublishResult()),
    );
    await pump(tester, const Locale('ar'));

    expect(find.text('المشاركة على LinkedIn'), findsOneWidget);
    expect(find.text('نشر'), findsOneWidget);
    await tester.tap(find.byKey(const Key('linkedin_publish_button')));
    await tester.pumpAndSettle();
    expect(find.text('تم النشر بنجاح'), findsOneWidget);
    expect(find.byKey(const Key('linkedin_open_post')), findsNothing);
  });
}
