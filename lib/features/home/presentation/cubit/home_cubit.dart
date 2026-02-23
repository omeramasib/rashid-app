import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/usecases/share_interview_result_usecase.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final ShareInterviewResultUseCase shareInterviewResultUseCase;

  HomeCubit({required this.shareInterviewResultUseCase}) : super(HomeInitial());

  Future<void> shareLastInterviewResult([String? caption]) async {
    emit(HomeSharing());
    final result = await shareInterviewResultUseCase(
      ShareInterviewResultParams(caption: caption),
    );
    result.fold(
      (failure) => emit(HomeError(failure.message)),
      (shareResult) => emit(HomeShared(shareResult.postUrl)),
    );
  }
}
