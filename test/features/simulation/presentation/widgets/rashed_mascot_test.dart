import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rashed_app/features/simulation/presentation/cubit/interview_cubit.dart';
import 'package:rashed_app/features/simulation/presentation/widgets/rashed_mascot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const welcome = InterviewMascotAppearance(
    pose: RashedPose.welcome,
    motion: RashedMotion.entrance,
    messageKey: 'mascot_welcome',
  );
  const thinking = InterviewMascotAppearance(
    pose: RashedPose.thinking,
    motion: RashedMotion.idle,
    messageKey: 'mascot_thinking',
  );
  const coaching = InterviewMascotAppearance(
    pose: RashedPose.coaching,
    motion: RashedMotion.busy,
    messageKey: 'mascot_submitting',
  );

  group('interviewMascotAppearance', () {
    InterviewMascotAppearance look({
      InterviewPhase phase = InterviewPhase.inProgress,
      bool hasError = false,
      bool recording = false,
      bool answering = false,
    }) {
      return interviewMascotAppearance(
        phase: phase,
        hasError: hasError,
        recording: recording,
        answering: answering,
      );
    }

    test('error wins over submitting, recording, and a typed answer', () {
      expect(
        look(
          phase: InterviewPhase.submitting,
          hasError: true,
          recording: true,
          answering: true,
        ),
        const InterviewMascotAppearance(
          pose: RashedPose.support,
          motion: RashedMotion.none,
          messageKey: 'mascot_error',
        ),
      );
    });

    test('submitting and finishing beat an answer in progress', () {
      expect(look(phase: InterviewPhase.submitting, answering: true), coaching);
      expect(
        look(phase: InterviewPhase.finishing, answering: true, recording: true),
        const InterviewMascotAppearance(
          pose: RashedPose.coaching,
          motion: RashedMotion.busy,
          messageKey: 'mascot_finishing',
        ),
      );
    });

    test('starting is coaching even if other presentation flags are set', () {
      expect(
        look(
          phase: InterviewPhase.starting,
          recording: true,
          answering: true,
        ),
        const InterviewMascotAppearance(
          pose: RashedPose.coaching,
          motion: RashedMotion.busy,
          messageKey: 'mascot_starting',
        ),
      );
    });

    test('recording beats a focused or non-empty answer', () {
      expect(
        look(recording: true, answering: true),
        const InterviewMascotAppearance(
          pose: RashedPose.encouraging,
          motion: RashedMotion.none,
          messageKey: 'mascot_listening',
        ),
      );
    });

    test('answering is encouraging and waiting is thinking', () {
      expect(
        look(answering: true),
        const InterviewMascotAppearance(
          pose: RashedPose.encouraging,
          motion: RashedMotion.none,
          messageKey: 'mascot_answering',
        ),
      );
      expect(look(), thinking);
    });

    test('setup and a failed start without an error welcome the user', () {
      expect(look(phase: InterviewPhase.setup), welcome);
      expect(look(phase: InterviewPhase.startFailed), welcome);
    });
  });

  group('interviewResultMascot', () {
    test('uses the existing bands and a neutral fallback', () {
      expect(
        interviewResultMascot('excellent').pose,
        RashedPose.success,
      );
      expect(
        interviewResultMascot('excellent').messageKey,
        'mascot_result_excellent',
      );
      expect(interviewResultMascot('average').pose, RashedPose.encouraging);
      expect(
        interviewResultMascot('average').messageKey,
        'mascot_result_average',
      );
      expect(interviewResultMascot('poor').pose, RashedPose.support);
      expect(interviewResultMascot('poor').messageKey, 'mascot_result_poor');
      expect(interviewResultMascot(null).pose, RashedPose.support);
      expect(
        interviewResultMascot('unexpected').messageKey,
        'mascot_result_default',
      );
      for (final status in ['excellent', 'average', 'poor', null, 'other']) {
        expect(interviewResultMascot(status).motion, RashedMotion.none);
      }
    });
  });

  test('cache width stays positive and never exceeds the source asset', () {
    expect(mascotCacheWidth(88, 1), 88);
    expect(mascotCacheWidth(0.2, 1), 1);
    expect(mascotCacheWidth(200, 3), rashedPoseSourcePixels);
  });

  testWidgets('bounded idle motion settles', (tester) async {
    await tester.pumpWidget(host(const RashedMascot(
      pose: RashedPose.thinking,
      motion: RashedMotion.idle,
    )));
    await tester.pump(const Duration(milliseconds: 200));
    expect(motionDy(tester), isNot(0));
    await tester.pumpAndSettle();
    expect(motionDy(tester), closeTo(0, 0.01));
    expect(poseAsset(tester), RashedPose.thinking.asset);
  });

  testWidgets('busy motion repeats, then stops when the motion changes',
      (tester) async {
    await tester.pumpWidget(host(const RashedMascot(
      pose: RashedPose.coaching,
      motion: RashedMotion.busy,
    )));
    await tester.pump(const Duration(milliseconds: 400));
    expect(halo(tester), greaterThan(0));

    await tester.pumpWidget(host(const RashedMascot(
      pose: RashedPose.coaching,
      motion: RashedMotion.none,
    )));
    await tester.pump();
    expect(halo(tester), 0);
    await tester.pump(const Duration(milliseconds: 800));
    expect(halo(tester), 0);
  });

  testWidgets('busy motion stops when the mascot is removed', (tester) async {
    await tester.pumpWidget(host(const RashedMascot(
      pose: RashedPose.coaching,
      motion: RashedMotion.busy,
    )));
    await tester.pump(const Duration(milliseconds: 400));
    expect(halo(tester), greaterThan(0));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion disables repeating and decorative motion',
      (tester) async {
    await tester.pumpWidget(host(
      const RashedMascot(
        pose: RashedPose.coaching,
        motion: RashedMotion.busy,
        message: 'Reviewing',
      ),
      reduceMotion: true,
    ));
    await tester.pump(const Duration(milliseconds: 700));
    expect(halo(tester), 0);
    expect(motionDy(tester), 0);

    await tester.pumpWidget(host(
      const InterviewResultMascot(
        appearance: InterviewMascotAppearance(
          pose: RashedPose.encouraging,
          motion: RashedMotion.none,
          messageKey: 'mascot_result_average',
        ),
        message: 'Solid work',
      ),
      reduceMotion: true,
    ));
    await tester.pump();
    expect(poseAsset(tester), RashedPose.encouraging.asset);
    await tester.pump(rashedCelebrateDuration);
    expect(poseAsset(tester), RashedPose.encouraging.asset);
  });

  testWidgets('a hidden route does not run the busy motion', (tester) async {
    await tester.pumpWidget(host(
      const RashedMascot(
        pose: RashedPose.coaching,
        motion: RashedMotion.busy,
      ),
      ticking: false,
    ));
    await tester.pump(const Duration(milliseconds: 700));
    expect(halo(tester), 0);
  });

  testWidgets('celebration plays once per visit and then settles',
      (tester) async {
    const average = InterviewMascotAppearance(
      pose: RashedPose.encouraging,
      motion: RashedMotion.none,
      messageKey: 'mascot_result_average',
    );
    const mascot = InterviewResultMascot(
      appearance: average,
      message: 'Solid work',
    );
    final navigator = GlobalKey<NavigatorState>();
    final rebuild = GlobalKey<_RebuildState>();
    Widget result() {
      return MaterialApp(
        navigatorKey: navigator,
        home: _Rebuild(key: rebuild, child: mascot),
      );
    }

    await tester.pumpWidget(result());
    await tester.pump();
    expect(poseAsset(tester), RashedPose.success.asset);

    await tester.pump(const Duration(milliseconds: 1000));
    expect(poseAsset(tester), RashedPose.success.asset);
    rebuild.currentState!.rebuild();
    await tester.pump(const Duration(milliseconds: 500));
    expect(poseAsset(tester), RashedPose.encouraging.asset);

    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Text('away')),
    );
    await tester.pumpAndSettle();
    expect(find.text('away'), findsOneWidget);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(poseAsset(tester), RashedPose.encouraging.asset);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(result());
    await tester.pump();
    expect(poseAsset(tester), RashedPose.success.asset);
  });

  testWidgets('question mascot follows focus and text without overriding',
      (tester) async {
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);

    Future<void> pumpMascot({
      InterviewPhase phase = InterviewPhase.inProgress,
      bool hasError = false,
      bool recording = false,
    }) {
      return tester.pumpWidget(host(Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InterviewQuestionMascot(
            controller: controller,
            focusNode: focus,
            phase: phase,
            hasError: hasError,
            recording: recording,
            compact: false,
          ),
          TextField(focusNode: focus, controller: controller),
        ],
      )));
    }

    await pumpMascot();
    await tester.pumpAndSettle();
    expect(poseAsset(tester), RashedPose.thinking.asset);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(focus.hasFocus, isTrue);
    expect(poseAsset(tester), RashedPose.encouraging.asset);

    controller.text = 'a';
    await tester.pump();
    expect(poseAsset(tester), RashedPose.encouraging.asset);
    controller.text = 'ab';
    await tester.pump();
    expect(poseAsset(tester), RashedPose.encouraging.asset);

    await pumpMascot(phase: InterviewPhase.submitting);
    await tester.pump(const Duration(milliseconds: 300));
    expect(poseAsset(tester), RashedPose.coaching.asset);

    await pumpMascot(phase: InterviewPhase.submitting, hasError: true);
    await tester.pump(const Duration(milliseconds: 300));
    expect(poseAsset(tester), RashedPose.support.asset);
  });

  testWidgets('decoded pose width matches the cache width', (tester) async {
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(host(const RashedMascot(
      pose: RashedPose.welcome,
      motion: RashedMotion.none,
      size: 200,
    )));
    final image = tester.widget<Image>(find.byType(Image));
    final resize = image.image as ResizeImage;
    expect(resize.width, rashedPoseSourcePixels);
    expect(resize.width, lessThanOrEqualTo(rashedPoseSourcePixels));
    expect(resize.width, greaterThan(0));
  });

  testWidgets('small screens in Arabic and English do not overflow',
      (tester) async {
    const welcomeText = 'مرحبًا، أنا راشد. سأساعدك في التدرب على هذه المقابلة.';
    for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
      await pumpNarrow(
        tester,
        direction: direction,
        keyboard: 0,
        child: const RashedMascot(
          pose: RashedPose.welcome,
          motion: RashedMotion.none,
          size: 88,
          message: welcomeText,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text(welcomeText), findsOneWidget);

      await pumpNarrow(
        tester,
        direction: direction,
        keyboard: 280,
        child: InterviewQuestionMascot(
          controller: TextEditingController(),
          focusNode: FocusNode(),
          phase: InterviewPhase.inProgress,
          hasError: false,
          recording: false,
          compact: true,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('rashed_mascot_message')), findsNothing);
    }
  });
}

class _Rebuild extends StatefulWidget {
  const _Rebuild({super.key, required this.child});

  final Widget child;

  @override
  State<_Rebuild> createState() => _RebuildState();
}

class _RebuildState extends State<_Rebuild> {
  void rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) => widget.child;
}

Widget host(
  Widget child, {
  bool reduceMotion = false,
  bool ticking = true,
}) {
  return MaterialApp(
    home: Builder(
      builder: (context) {
        return TickerMode(
          enabled: ticking,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: reduceMotion,
            ),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(12),
                child: child,
              ),
            ),
          ),
        );
      },
    ),
  );
}

Future<void> pumpNarrow(
  WidgetTester tester, {
  required TextDirection direction,
  required double keyboard,
  required Widget child,
}) async {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  await tester.pumpWidget(MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            child,
            const TextField(maxLines: 7),
          ],
        ),
      ),
    ),
  ));
  await tester.pump();
}

String poseAsset(WidgetTester tester) {
  final image = tester.widgetList<Image>(find.byType(Image)).last;
  final provider = image.image;
  final resize = provider is ResizeImage ? provider.imageProvider : provider;
  return (resize as AssetImage).assetName;
}

double halo(WidgetTester tester) {
  return tester
      .widget<Opacity>(find.byKey(const Key('rashed_mascot_halo')))
      .opacity;
}

double motionDy(WidgetTester tester) {
  return tester
      .widget<Transform>(find.byKey(const Key('rashed_mascot_motion')))
      .transform
      .getTranslation()
      .y;
}
