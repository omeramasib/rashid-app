import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../cv/domain/entities/cv_profile.dart';
import '../../../cv/domain/usecases/get_my_cv_profile_usecase.dart';
import '../../domain/interview_cv_gate.dart';

part 'interview_entry_state.dart';

class InterviewEntryCubit extends Cubit<InterviewEntryState> {
  InterviewEntryCubit({required this.getMyCvProfileUseCase})
      : super(const InterviewEntryState.checking());

  final GetMyCvProfileUseCase getMyCvProfileUseCase;
  Future<void>? _check;

  Future<void> check() {
    return _check ??= _load();
  }

  /// Starts another check after a transport failure.
  ///
  /// A check that is already running is left as the only request.
  Future<void> retry() {
    if (state.phase != InterviewEntryPhase.failed) {
      return _check ?? Future<void>.value();
    }
    _check = null;
    emit(const InterviewEntryState.checking());
    return check();
  }

  Future<void> _load() async {
    final result = await getMyCvProfileUseCase(NoParams());
    if (isClosed) return;
    result.fold(_fail, _apply);
  }

  void _apply(CvProfile? profile) {
    if (interviewCvGateDestination(profile) ==
        InterviewCvGateDestination.setup) {
      emit(InterviewEntryState.ready(profile!));
      return;
    }
    emit(const InterviewEntryState.needsProfile());
  }

  void _fail(Failure failure) {
    if (failure is UnauthorizedFailure) {
      emit(InterviewEntryState.unauthorized(failure));
      return;
    }
    emit(InterviewEntryState.failed(failure));
  }
}
