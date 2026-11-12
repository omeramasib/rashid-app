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
import 'package:rashed_app/features/linkedin/domain/entities/linkedin_mark_deleted_result.dart';
import 'package:rashed_app/features/linkedin/domain/usecases/mark_linkedin_share_deleted_usecase.dart';
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

class MockMarkDeleted extends Mock implements MarkLinkedInShareDeletedUseCase {}

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
    registerFallbackValue(
      const MarkLinkedInShareDeletedParams(shareId: 'share'),
    );
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
      markDeleted: MockMarkDeleted(),
      disconnectLinkedIn: MockDisconnect(),
      pendingShare: _Pending(),
      launcher: _Launcher(),
      returnGate: LinkedInReturnGate(),
    );
  });

  tearDown(() => cubit.close());

  Future<void> pump(
    WidgetTester tester,
    Locale locale, {
    Future<bool> Function(String? url)? openPost,
  }) async {
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
          builder: (_) => LinkedInShareScreen(
            cubit: cubit,
            openPost: openPost,
          ),
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
    verifyNever(() => publish(any()));

    await tester.tap(find.byKey(const Key('linkedin_publish_button')));
    await tester.pump();

    expect(find.byKey(const Key('linkedin_publish_button')), findsNothing);
    verify(() => publish(any())).called(1);
    expect(find.text('Publishing'), findsOneWidget);

    gate.complete(const Right(LinkedInPublishResult(
      postUrl: 'https://www.linkedin.com/feed/update/urn:li:ugcPost:44/',
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

  testWidgets('same content is already shared and is not a new success',
      (tester) async {
    final status = MockStatus();
    final previewShare = MockPreview();
    final localPublish = MockPublish();
    await cubit.close();
    when(() => status(any())).thenAnswer((_) async => const Right(active));
    when(() => previewShare(any())).thenAnswer(
      (_) async => const Right(LinkedInSharePreview(
        previewId: 'preview-1',
        simulationId: 'sim-1',
        text: 'Exact server post',
        contentSha256: 'hash-1',
        existingContentMatches: true,
        existingPostUrl: 'https://www.linkedin.com/feed/update/urn:li:share:9/',
      )),
    );
    cubit = LinkedInShareCubit(
      getStatus: status,
      startOAuth: MockStart(),
      previewShare: previewShare,
      publishShare: localPublish,
      markDeleted: MockMarkDeleted(),
      disconnectLinkedIn: MockDisconnect(),
      pendingShare: _Pending(),
      launcher: _Launcher(),
      returnGate: LinkedInReturnGate(),
    );
    await pump(tester, const Locale('en'));

    expect(find.text('Already shared on LinkedIn'), findsOneWidget);
    expect(find.text('Exact server post'), findsOneWidget);
    expect(find.text('Published successfully'), findsNothing);
    expect(find.byKey(const Key('linkedin_publish_button')), findsNothing);
    expect(
        find.byKey(const Key('linkedin_view_published_post')), findsOneWidget);
    expect(find.byKey(const Key('linkedin_mark_deleted')), findsNothing);
    verifyNever(() => localPublish(any()));
  });

  testWidgets('different content explains the preview and opens the old post',
      (tester) async {
    final status = MockStatus();
    final previewShare = MockPreview();
    final localPublish = MockPublish();
    await cubit.close();
    when(() => status(any())).thenAnswer((_) async => const Right(active));
    when(() => previewShare(any())).thenAnswer(
      (_) async => const Right(LinkedInSharePreview(
        previewId: 'preview-1',
        simulationId: 'sim-1',
        text: 'Exact server post',
        contentSha256: 'hash-2',
        existingContentMatches: false,
        existingPostUrl: 'https://www.linkedin.com/feed/update/urn:li:share:9/',
      )),
    );
    cubit = LinkedInShareCubit(
      getStatus: status,
      startOAuth: MockStart(),
      previewShare: previewShare,
      publishShare: localPublish,
      markDeleted: MockMarkDeleted(),
      disconnectLinkedIn: MockDisconnect(),
      pendingShare: _Pending(),
      launcher: _Launcher(),
      returnGate: LinkedInReturnGate(),
    );
    await pump(tester, const Locale('en'));

    expect(find.text('Exact server post'), findsOneWidget);
    expect(
        find.textContaining('not the text that was published'), findsOneWidget);
    expect(find.text('Published successfully'), findsNothing);
    expect(find.text('Already shared on LinkedIn'), findsNothing);
    expect(find.byKey(const Key('linkedin_publish_button')), findsNothing);
    expect(
        find.byKey(const Key('linkedin_view_published_post')), findsOneWidget);
    verifyNever(() => localPublish(any()));
  });

  testWidgets('view published post opens that permalink', (tester) async {
    final status = MockStatus();
    final previewShare = MockPreview();
    final localPublish = MockPublish();
    final opened = <String?>[];
    await cubit.close();
    when(() => status(any())).thenAnswer((_) async => const Right(active));
    when(() => previewShare(any())).thenAnswer(
      (_) async => const Right(LinkedInSharePreview(
        previewId: 'preview-1',
        simulationId: 'sim-1',
        text: 'Exact server post',
        contentSha256: 'hash-2',
        existingContentMatches: false,
        existingPostUrl: 'https://www.linkedin.com/feed/update/urn:li:share:9/',
      )),
    );
    cubit = LinkedInShareCubit(
      getStatus: status,
      startOAuth: MockStart(),
      previewShare: previewShare,
      publishShare: localPublish,
      markDeleted: MockMarkDeleted(),
      disconnectLinkedIn: MockDisconnect(),
      pendingShare: _Pending(),
      launcher: _Launcher(),
      returnGate: LinkedInReturnGate(),
    );
    await pump(
      tester,
      const Locale('en'),
      openPost: (url) async {
        opened.add(url);
        return true;
      },
    );

    await tester.tap(find.byKey(const Key('linkedin_view_published_post')));
    await tester.pump();

    expect(opened, [
      'https://www.linkedin.com/feed/update/urn:li:share:9/',
    ]);
    verifyNever(() => localPublish(any()));
  });

  testWidgets('an unavailable post url is not offered as viewable',
      (tester) async {
    final status = MockStatus();
    final previewShare = MockPreview();
    final localPublish = MockPublish();
    await cubit.close();
    when(() => status(any())).thenAnswer((_) async => const Right(active));
    when(() => previewShare(any())).thenAnswer(
      (_) async => const Right(LinkedInSharePreview(
        previewId: 'preview-1',
        simulationId: 'sim-1',
        text: 'Exact server post',
        contentSha256: 'hash-2',
        existingContentMatches: false,
        existingPostUrl:
            'https://www.linkedin.com/feed/update/urn:li:activity:9/',
      )),
    );
    cubit = LinkedInShareCubit(
      getStatus: status,
      startOAuth: MockStart(),
      previewShare: previewShare,
      publishShare: localPublish,
      markDeleted: MockMarkDeleted(),
      disconnectLinkedIn: MockDisconnect(),
      pendingShare: _Pending(),
      launcher: _Launcher(),
      returnGate: LinkedInReturnGate(),
    );
    await pump(tester, const Locale('en'));

    expect(
        find.textContaining('not the text that was published'), findsOneWidget);
    expect(find.byKey(const Key('linkedin_view_published_post')), findsNothing);
    expect(find.byKey(const Key('linkedin_publish_button')), findsNothing);
    verifyNever(() => localPublish(any()));
  });

  testWidgets('a fresh preview after an already-shared response can publish',
      (tester) async {
    final status = MockStatus();
    final previewShare = MockPreview();
    final localPublish = MockPublish();
    final gate = Completer<Either<Failure, LinkedInPublishResult>>();
    var previews = 0;
    await cubit.close();
    when(() => status(any())).thenAnswer((_) async => const Right(active));
    when(() => previewShare(any())).thenAnswer((_) async {
      previews += 1;
      if (previews == 1) {
        return const Right(LinkedInSharePreview(
          previewId: 'preview-old',
          simulationId: 'sim-1',
          text: 'Previously published post',
          contentSha256: 'hash-old',
          existingContentMatches: true,
          existingPostUrl:
              'https://www.linkedin.com/feed/update/urn:li:share:9/',
        ));
      }
      return const Right(LinkedInSharePreview(
        previewId: 'preview-new',
        simulationId: 'sim-1',
        text: 'Fresh promotional post',
        contentSha256: 'hash-new',
      ));
    });
    when(() => localPublish(any())).thenAnswer((_) => gate.future);
    cubit = LinkedInShareCubit(
      getStatus: status,
      startOAuth: MockStart(),
      previewShare: previewShare,
      publishShare: localPublish,
      markDeleted: MockMarkDeleted(),
      disconnectLinkedIn: MockDisconnect(),
      pendingShare: _Pending(),
      launcher: _Launcher(),
      returnGate: LinkedInReturnGate(),
    );
    await pump(tester, const Locale('en'));

    expect(find.text('Already shared on LinkedIn'), findsOneWidget);
    expect(find.byKey(const Key('linkedin_publish_button')), findsNothing);
    expect(
        find.byKey(const Key('linkedin_view_published_post')), findsOneWidget);

    await cubit.begin(simulationId: 'sim-1', resultLabel: '82');
    await tester.pumpAndSettle();

    expect(find.text('Fresh promotional post'), findsOneWidget);
    expect(find.text('Already shared on LinkedIn'), findsNothing);
    expect(find.byKey(const Key('linkedin_view_published_post')), findsNothing);
    expect(find.byKey(const Key('linkedin_publish_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('linkedin_publish_button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('linkedin_publishing_label')));
    await tester.pump();

    verify(
      () => localPublish(const PublishLinkedInParams(
        previewId: 'preview-new',
        simulationId: 'sim-1',
        contentSha256: 'hash-new',
      )),
    ).called(1);
    expect(find.text('Publishing'), findsOneWidget);

    gate.complete(const Right(LinkedInPublishResult(
      postUrl: 'https://www.linkedin.com/feed/update/urn:li:share:10/',
    )));
    await tester.pumpAndSettle();

    expect(find.text('Published successfully'), findsOneWidget);
    expect(find.text('Already shared on LinkedIn'), findsNothing);
    expect(find.byKey(const Key('linkedin_open_post')), findsOneWidget);
  });

  LinkedInShareCubit shareCubit({
    required PreviewLinkedInShareUseCase previewShare,
    required MarkLinkedInShareDeletedUseCase markDeleted,
    required PublishLinkedInShareUseCase localPublish,
  }) {
    final status = MockStatus();
    when(() => status(any())).thenAnswer((_) async => const Right(active));
    return LinkedInShareCubit(
      getStatus: status,
      startOAuth: MockStart(),
      previewShare: previewShare,
      publishShare: localPublish,
      markDeleted: markDeleted,
      disconnectLinkedIn: MockDisconnect(),
      pendingShare: _Pending(),
      launcher: _Launcher(),
      returnGate: LinkedInReturnGate(),
    );
  }

  testWidgets('cancel closes the deletion dialog without calling the api',
      (tester) async {
    final previewShare = MockPreview();
    final localPublish = MockPublish();
    final deleted = MockMarkDeleted();
    await cubit.close();
    when(() => previewShare(any())).thenAnswer(
      (_) async => const Right(LinkedInSharePreview(
        previewId: 'preview-old',
        simulationId: 'sim-1',
        text: 'Previously published post',
        contentSha256: 'hash-old',
        existingContentMatches: true,
        existingPostUrl: 'https://www.linkedin.com/feed/update/urn:li:share:9/',
        existingShareId: 'share-old',
      )),
    );
    cubit = shareCubit(
      previewShare: previewShare,
      markDeleted: deleted,
      localPublish: localPublish,
    );
    await pump(tester, const Locale('en'));

    expect(find.text('Already shared on LinkedIn'), findsOneWidget);
    expect(find.text('I deleted this post on LinkedIn'), findsOneWidget);
    expect(
        find.byKey(const Key('linkedin_view_published_post')), findsOneWidget);
    expect(find.byKey(const Key('linkedin_publish_button')), findsNothing);

    await tester.tap(find.byKey(const Key('linkedin_mark_deleted')));
    await tester.pumpAndSettle();
    expect(
      find.text('Have you already deleted this post from LinkedIn?'),
      findsOneWidget,
    );
    expect(
      find.text(
        'This action will only update your sharing history in Rashed. It will not delete the post from LinkedIn.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('linkedin_delete_cancel')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('linkedin_delete_confirm_title')), findsNothing);
    verifyNever(() => deleted(any()));
    verifyNever(() => localPublish(any()));
  });

  testWidgets('arabic copy explains an existing post and the deletion dialog',
      (tester) async {
    final previewShare = MockPreview();
    final deleted = MockMarkDeleted();
    await cubit.close();
    when(() => previewShare(any())).thenAnswer(
      (_) async => const Right(LinkedInSharePreview(
        previewId: 'preview-old',
        simulationId: 'sim-1',
        text: 'منشور سابق',
        contentSha256: 'hash-old',
        existingContentMatches: true,
        existingPostUrl: 'https://www.linkedin.com/feed/update/urn:li:share:9/',
        existingShareId: 'share-old',
      )),
    );
    cubit = shareCubit(
      previewShare: previewShare,
      markDeleted: deleted,
      localPublish: MockPublish(),
    );
    await pump(tester, const Locale('ar'));

    expect(find.text('تمت مشاركة النتيجة على لينكدإن مسبقًا'), findsOneWidget);
    expect(find.text('حذفت هذا المنشور من لينكدإن'), findsOneWidget);
    await tester.tap(find.byKey(const Key('linkedin_mark_deleted')));
    await tester.pumpAndSettle();
    expect(
      find.text('هل حذفت هذا المنشور من لينكدإن بالفعل؟'),
      findsOneWidget,
    );
    expect(find.text('تأكيد'), findsOneWidget);
    expect(find.text('إلغاء'), findsOneWidget);
    await tester.tap(find.byKey(const Key('linkedin_delete_cancel')));
    await tester.pumpAndSettle();
    verifyNever(() => deleted(any()));
  });

  testWidgets(
      'confirm marks the active share deleted once and shows a fresh preview',
      (tester) async {
    final previewShare = MockPreview();
    final localPublish = MockPublish();
    final deleted = MockMarkDeleted();
    final gate = Completer<Either<Failure, LinkedInMarkDeletedResult>>();
    var previews = 0;
    await cubit.close();
    when(() => previewShare(any())).thenAnswer((_) async {
      previews += 1;
      if (previews == 1) {
        return const Right(LinkedInSharePreview(
          previewId: 'preview-old',
          simulationId: 'sim-1',
          text: 'Previously published post',
          contentSha256: 'hash-old',
          existingContentMatches: true,
          existingPostUrl:
              'https://www.linkedin.com/feed/update/urn:li:share:9/',
          existingShareId: 'share-old',
        ));
      }
      return const Right(LinkedInSharePreview(
        previewId: 'preview-new',
        simulationId: 'sim-1',
        text: 'Fresh promotional post',
        contentSha256: 'hash-new',
      ));
    });
    when(() => deleted(any())).thenAnswer((_) => gate.future);
    cubit = shareCubit(
      previewShare: previewShare,
      markDeleted: deleted,
      localPublish: localPublish,
    );
    await pump(tester, const Locale('en'));

    await tester.tap(find.byKey(const Key('linkedin_mark_deleted')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('linkedin_delete_confirm')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('linkedin_share_loading')));
    await tester.pump();

    expect(find.text('Updating your sharing history'), findsOneWidget);
    expect(find.byKey(const Key('linkedin_mark_deleted')), findsNothing);
    expect(find.byKey(const Key('linkedin_publish_button')), findsNothing);
    verify(
      () => deleted(const MarkLinkedInShareDeletedParams(shareId: 'share-old')),
    ).called(1);
    verifyNever(() => localPublish(any()));

    gate.complete(const Right(LinkedInMarkDeletedResult(
      shareId: 'share-old',
      status: 'externally_deleted',
      canRepublish: true,
      remainingActivePosts: 0,
    )));
    await tester.pumpAndSettle();

    expect(find.text('You can now publish this result again'), findsOneWidget);
    expect(find.text('Fresh promotional post'), findsOneWidget);
    expect(find.byKey(const Key('linkedin_publish_button')), findsOneWidget);
    expect(find.byKey(const Key('linkedin_view_published_post')), findsNothing);
    verifyNever(() => localPublish(any()));
  });

  testWidgets('other active posts keep publish disabled after deletion',
      (tester) async {
    final previewShare = MockPreview();
    final localPublish = MockPublish();
    final deleted = MockMarkDeleted();
    var previews = 0;
    await cubit.close();
    when(() => previewShare(any())).thenAnswer((_) async {
      previews += 1;
      if (previews == 1) {
        return const Right(LinkedInSharePreview(
          previewId: 'preview-old',
          simulationId: 'sim-1',
          text: 'Previously published post',
          contentSha256: 'hash-old',
          existingContentMatches: true,
          existingPostUrl:
              'https://www.linkedin.com/feed/update/urn:li:share:9/',
          existingShareId: 'share-old',
        ));
      }
      return const Right(LinkedInSharePreview(
        previewId: 'preview-empty',
        simulationId: 'sim-1',
        text: 'Would look publishable',
        contentSha256: 'hash-empty',
      ));
    });
    when(() => deleted(any())).thenAnswer(
      (_) async => const Right(LinkedInMarkDeletedResult(
        shareId: 'share-old',
        status: 'externally_deleted',
        canRepublish: false,
        remainingActivePosts: 1,
      )),
    );
    cubit = shareCubit(
      previewShare: previewShare,
      markDeleted: deleted,
      localPublish: localPublish,
    );
    await pump(tester, const Locale('en'));
    await tester.tap(find.byKey(const Key('linkedin_mark_deleted')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('linkedin_delete_confirm')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Other active LinkedIn posts still prevent publishing this result again.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('linkedin_publish_button')), findsNothing);
    expect(find.text('Would look publishable'), findsNothing);
    verifyNever(() => localPublish(any()));
  });
}
