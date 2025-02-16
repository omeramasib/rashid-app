import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rashed_app/Data/Repositories/Auth/login_repository.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final LoginRepository loginRepository;

  bool isPasswordVisible = false;

  LoginCubit
  (
    this.loginRepository
  ) : super(LoginInitial());
  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(LoginOnProgress());
    try {
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
      );
      final result = await loginRepository.login(
        email: email,
        password: password,
      );
      if (result['status'] == "success") {
        emit(LoginSuccess(message: result['message'], token: result['token']));
        await storage.write(key: 'token', value: result['token']);
        await storage.write(key: 'email', value: email);
        await storage.write(key: 'password', value: password);

      } else {
        emit(LoginFailure(errorMessage: 'Invalid Credentials'));
      }
    } catch (e) {
      emit(LoginFailure(errorMessage: e.toString()));
    }
  }

  // Future<void> biometricLogin() async {
  //   const storage = FlutterSecureStorage(
  //     aOptions: AndroidOptions(
  //       encryptedSharedPreferences: true,
  //     ),
  //   );
  //   bool isBiometricEnabled = await biometricAuth.isBiometricAuthEnabled();
  //   log('isBiometricEnabled: $isBiometricEnabled');
  //   if (isBiometricEnabled) {
  //     bool isAuth = await biometricAuth.isAuth('Enable Biometric Login');
  //     if (isAuth) {
  //       emit(LoginOnProgress());
  //       String employeeFileNo = await storage.read(key: 'employeeFileNo') ?? '';
  //       String password = await storage.read(key: 'password') ?? '';
  //       if (employeeFileNo.isNotEmpty && password.isNotEmpty) {
  //         try {
  //           final result = await loginRepository.login(
  //             employeeFileNo: employeeFileNo,
  //             password: password,
  //           );
  //           if (kDebugMode) {
  //             log('LoginCubit result: $result');
  //           }
  //           if (result['status'] == true) {
  //             emit(LoginSuccess(
  //                 message: result['message'], token: result['token']));
  //             await storage.write(key: 'token', value: result['token']);
  //             await storage.write(key: 'employeeFileNo', value: employeeFileNo);
  //             await storage.write(key: 'password', value: password);
  //           } else {
  //             emit(LoginFailure(errorMessage: 'Invalid Credentials'));
  //           }
  //         } catch (e) {
  //           emit(LoginFailure(errorMessage: e.toString()));
  //           log('Error during login: $e');
  //         }
  //       } else {
  //         emit(LoginFailure(
  //             errorMessage:
  //                 'Please login with the employee credentials first'));
  //       }
  //     }
  //   } else {}
  // }

  void viewPassword() {
    isPasswordVisible = !isPasswordVisible;
    emit(ViewPasswordState(enabled: isPasswordVisible));
  }
}
