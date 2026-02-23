import 'package:bloc/bloc.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../domain/usecases/change_password_usecase.dart';
import '../../../domain/usecases/get_current_user_usecase.dart';
import '../../../domain/usecases/logout_usecase.dart';
import 'auth_profile_state.dart';

class AuthProfileCubit extends Cubit<AuthProfileState> {
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final ChangePasswordUseCase changePasswordUseCase;
  final LogoutUseCase logoutUseCase;

  AuthProfileCubit({
    required this.getCurrentUserUseCase,
    required this.changePasswordUseCase,
    required this.logoutUseCase,
  }) : super(AuthProfileInitial());

  Future<void> getCurrentUser() async {
    emit(AuthProfileLoading());
    final result = await getCurrentUserUseCase(NoParams());
    result.fold(
      (failure) => emit(AuthProfileError(failure.message)),
      (user) => emit(AuthProfileLoaded(user)),
    );
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    emit(AuthProfileLoading());
    final result = await changePasswordUseCase(
      ChangePasswordParams(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );
    result.fold(
      (failure) => emit(AuthProfileError(failure.message)),
      (_) => emit(PasswordChangeSuccess()),
    );
  }

  Future<void> logout() async {
    emit(AuthProfileLoading());
    final result = await logoutUseCase(NoParams());
    result.fold(
      (failure) => emit(AuthProfileError(failure.message)),
      (_) => emit(AuthProfileLoggedOut()),
    );
  }
}
