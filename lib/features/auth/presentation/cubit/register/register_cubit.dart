import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/storage/secure_storage_service.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/register_usecase.dart';

part 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final RegisterUseCase registerUseCase;
  final SecureStorageService secureStorageService;
  bool isPasswordVisible = false;

  RegisterCubit({
    required this.registerUseCase,
    required this.secureStorageService,
  }) : super(RegisterInitial());

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    emit(RegisterLoading());

    final result = await registerUseCase(RegisterParams(
      email: email,
      password: password,
      name: name,
      phone: phone,
    ));

    result.fold(
      (failure) => emit(RegisterFailure(failure.message)),
      (user) async {
        await secureStorageService.write(key: 'token', value: user.token);

        emit(RegisterSuccess(user));
      },
    );
  }

  void viewPassword() {
    isPasswordVisible = !isPasswordVisible;
    emit(ViewPasswordState(enabled: isPasswordVisible));
  }
}
