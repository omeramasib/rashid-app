import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/usecases/forgot_password_usecase.dart';
import '../../../domain/usecases/reset_password_usecase.dart';

part 'password_state.dart';

class PasswordCubit extends Cubit<PasswordState> {
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;

  PasswordCubit({
    required this.forgotPasswordUseCase,
    required this.resetPasswordUseCase,
  }) : super(PasswordInitial());

  Future<void> forgotPassword(String email) async {
    emit(PasswordLoading());
    final result = await forgotPasswordUseCase(
      ForgotPasswordParams(email: email),
    );
    result.fold(
      (failure) => emit(PasswordError(failure.message)),
      (_) => emit(ForgotPasswordSuccess()),
    );
  }

  Future<void> resetPassword(String token, String newPassword) async {
    emit(PasswordLoading());
    final result = await resetPasswordUseCase(
      ResetPasswordParams(token: token, newPassword: newPassword),
    );
    result.fold(
      (failure) => emit(PasswordError(failure.message)),
      (_) => emit(ResetPasswordSuccess()),
    );
  }
}
