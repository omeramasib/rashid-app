import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rashed_app/Data/repositories/Auth/register_repository.dart';

part 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final RegisterRepository registerRepository;

  bool isPasswordVisible = false;

  RegisterCubit
  (
    this.registerRepository
  ) : super(RegisterInitial());
  Future<void> singup({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(RegisterOnProgress());
    try {
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
      );
      final result = await registerRepository.register(
        name: name,
        email: email,
        password: password,
      );
      if (result['status'] == "sucsses") {
        emit(RegisterSuccess(message: result['message'], token: result['token']));
        await storage.write(key: 'token', value: result['token']);
        await storage.write(key: 'email', value: email);

      } else {
        emit(RegisterFailure(errorMessage: 'User Already Exist'));
      }
    } catch (e) {
      emit(RegisterFailure(errorMessage: e.toString()));
    }
  }


  void viewPassword() {
    isPasswordVisible = !isPasswordVisible;
    emit(ViewPasswordState(enabled: isPasswordVisible));
  }
}
