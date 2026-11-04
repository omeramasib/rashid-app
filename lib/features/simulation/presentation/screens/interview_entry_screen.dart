import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../app/routes_name.dart';
import '../../../../app_localizations.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/localization/app_text_direction.dart';
import '../../../../core/theme/theme.dart';
import '../../../cv/domain/entities/cv_profile.dart';
import '../../domain/interview_options.dart';
import '../cubit/interview_cubit.dart';
import '../cubit/interview_entry_cubit.dart';
import '../interview_error_text.dart';
import '../widgets/interview_widgets.dart';
import 'interview_setup_screen.dart';

typedef InterviewSetupFactory = InterviewCubit Function(CvProfile profile);

class InterviewEntryScreen extends HookWidget {
  const InterviewEntryScreen({
    super.key,
    required this.mode,
    this.entryCubit,
    this.createSetupCubit,
  });

  final InterviewStartMode mode;
  final InterviewEntryCubit? entryCubit;
  final InterviewSetupFactory? createSetupCubit;

  @override
  Widget build(BuildContext context) {
    final ownsCubit = entryCubit == null;
    final cubit = useMemoized(
      () => entryCubit ?? di.sl<InterviewEntryCubit>(),
      [entryCubit],
    );
    useEffect(() {
      cubit.check();
      if (!ownsCubit) return null;
      return () {
        cubit.close();
      };
    }, [cubit]);

    return BlocProvider.value(
      value: cubit,
      child: _InterviewEntryView(
        mode: mode,
        createSetupCubit: createSetupCubit,
      ),
    );
  }
}

class _InterviewEntryView extends StatelessWidget {
  const _InterviewEntryView({
    required this.mode,
    required this.createSetupCubit,
  });

  final InterviewStartMode mode;
  final InterviewSetupFactory? createSetupCubit;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InterviewEntryCubit, InterviewEntryState>(
      listenWhen: (previous, current) => previous.phase != current.phase,
      listener: (context, state) {
        if (!context.mounted) return;
        final route = ModalRoute.of(context);
        if (route != null && !route.isCurrent) return;
        if (state.phase == InterviewEntryPhase.needsProfile) {
          Navigator.pushReplacementNamed(
            context,
            RoutesName.completeProfile,
            arguments: mode,
          );
        } else if (state.phase == InterviewEntryPhase.unauthorized) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            RoutesName.login,
            (route) => false,
          );
        }
      },
      builder: (context, state) {
        if (state.phase == InterviewEntryPhase.ready && state.profile != null) {
          final profile = state.profile!;
          return BlocProvider(
            key: ValueKey(profile.cvId),
            create: (_) => (createSetupCubit ?? _setupCubit)(profile),
            child: InterviewSetupScreen(initialMode: mode),
          );
        }
        if (state.phase == InterviewEntryPhase.failed &&
            state.failure != null) {
          return _EntryScaffold(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: InterviewErrorBanner(
                messageKey: const Key('interview_entry_error'),
                actionKey: const Key('interview_entry_retry'),
                message: interviewErrorText(context, state.failure!),
                actionLabel: AppLocalizations.tr(context, 'interview_retry'),
                onAction: () => context.read<InterviewEntryCubit>().retry(),
              ),
            ),
          );
        }
        return const _EntryScaffold(child: _EntryLoading());
      },
    );
  }

  static InterviewCubit _setupCubit(CvProfile profile) {
    final cubit = di.sl<InterviewCubit>();
    cubit.adoptProcessedProfile(profile);
    return cubit;
  }
}

class _EntryScaffold extends StatelessWidget {
  const _EntryScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppTextDirection.of(context),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              InterviewTopBar(
                title: AppLocalizations.tr(context, 'interview_setup_title'),
                onBack: () => Navigator.maybePop(context),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryLoading extends StatelessWidget {
  const _EntryLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            key: Key('interview_entry_loading'),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.tr(context, 'interview_cv_checking'),
            style: AppTypography.regular(
              fontSize: 13,
              color: AppColors.hintColor,
            ),
          ),
        ],
      ),
    );
  }
}
