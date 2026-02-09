import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/storage/secure_storage_service.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/login_usecase.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final LoginUseCase loginUseCase;
  final SecureStorageService secureStorageService;
  bool isPasswordVisible = false;

  LoginCubit({
    required this.loginUseCase,
    required this.secureStorageService,
  }) : super(LoginInitial());

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(LoginLoading());

    final result =
        await loginUseCase(LoginParams(email: email, password: password));

    result.fold(
      (failure) => emit(LoginFailure(failure.message)),
      (user) async {
        await secureStorageService.write(key: 'token', value: user.token);
        await secureStorageService.write(key: 'email', value: email);
        await secureStorageService.write(key: 'password', value: password);

        emit(LoginSuccess(user));
      },
    );
  }

  void viewPassword() {
    isPasswordVisible = !isPasswordVisible;
    emit(ViewPasswordState(enabled: isPasswordVisible));
  }
}
