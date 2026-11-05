import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../simulation/domain/usecases/get_simulation_history_count_usecase.dart';

part 'simulation_history_count_state.dart';

class SimulationHistoryCountCubit extends Cubit<SimulationHistoryCountState> {
  final GetSimulationHistoryCountUseCase _getSimulationHistoryCount;
  final SecureStorageService _secureStorage;

  int _generation = 0;
  String? _sessionUserId;

  SimulationHistoryCountCubit({
    required GetSimulationHistoryCountUseCase getSimulationHistoryCount,
    required SecureStorageService secureStorage,
  })  : _getSimulationHistoryCount = getSimulationHistoryCount,
        _secureStorage = secureStorage,
        super(const SimulationHistoryCountInitial());

  /// Loads the count once for the current user. Repeated calls while a
  /// request is already running, or after a count is already visible, do
  /// not send another request.
  Future<void> load() => _fetch(allowDuplicate: false);

  /// Loads again after the user returns from an interview, or after a failure.
  Future<void> refresh() => _fetch(allowDuplicate: true);

  /// Drops the visible count and ignores any response still in flight.
  void clearSession() {
    _generation++;
    _sessionUserId = null;
    if (!isClosed) emit(const SimulationHistoryCountInitial());
  }

  Future<void> _fetch({required bool allowDuplicate}) async {
    final userId = await _secureStorage.read(key: 'user_id');
    if (isClosed) return;
    if (userId == null || userId.isEmpty) {
      clearSession();
      return;
    }

    final switchedUser = _sessionUserId != userId;
    if (!switchedUser &&
        !allowDuplicate &&
        (state is SimulationHistoryCountLoading ||
            state is SimulationHistoryCountSuccess)) {
      return;
    }

    if (switchedUser) {
      _generation++;
      _sessionUserId = userId;
    }

    final generation = ++_generation;
    final owner = userId;
    _sessionUserId = owner;
    if (switchedUser || state is! SimulationHistoryCountSuccess) {
      emit(const SimulationHistoryCountLoading());
    }

    final result = await _getSimulationHistoryCount(NoParams());
    if (!_isCurrent(generation, owner)) return;
    final currentUser = await _secureStorage.read(key: 'user_id');
    if (!_isCurrent(generation, owner) || currentUser != owner) return;

    result.fold(
      (_) => emit(const SimulationHistoryCountFailure()),
      (count) => emit(SimulationHistoryCountSuccess(count.totalSimulations)),
    );
  }

  bool _isCurrent(int generation, String owner) {
    return !isClosed && generation == _generation && owner == _sessionUserId;
  }
}
