import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/performance_summary.dart';
import '../../domain/usecases/get_performance_summary_usecase.dart';

part 'performance_state.dart';

class PerformanceCubit extends Cubit<PerformanceState> {
  final GetPerformanceSummaryUseCase getPerformanceSummaryUseCase;

  Future<void>? _inFlight;

  PerformanceCubit({required this.getPerformanceSummaryUseCase})
      : super(const PerformanceInitial());

  /// Loads the summary. A call made while one is already running waits for
  /// that request instead of sending another.
  Future<void> load() {
    final current = _inFlight;
    if (current != null) return current;
    late final Future<void> future;
    future = _fetch().whenComplete(() {
      if (identical(_inFlight, future)) _inFlight = null;
    });
    _inFlight = future;
    return future;
  }

  Future<void> _fetch() async {
    final showLoading = state is! PerformanceSuccess;
    if (showLoading && !isClosed) emit(const PerformanceLoading());
    try {
      final result = await getPerformanceSummaryUseCase(NoParams());
      if (isClosed) return;
      result.fold(
        (failure) => emit(PerformanceFailure(failure)),
        (summary) => emit(PerformanceSuccess(summary)),
      );
    } catch (error) {
      if (isClosed) return;
      emit(PerformanceFailure(ServerFailure(error.toString())));
    }
  }
}
