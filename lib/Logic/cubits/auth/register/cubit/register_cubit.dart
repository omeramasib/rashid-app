import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  // final LoginRepository loginRepository;

  bool isPasswordVisible = false;

  RegisterCubit
  (
    // this.loginRepository
  ) : super(RegisterInitial());
  // Future<void> login({
  //   required String employeeFileNo,
  //   required String password,
  // }) async {
  //   emit(LoginOnProgress());
  //   try {
  //     const storage = FlutterSecureStorage(
  //       aOptions: AndroidOptions(
  //         encryptedSharedPreferences: true,
  //       ),
  //     );
  //     final result = await loginRepository.login(
  //       employeeFileNo: employeeFileNo,
  //       password: password,
  //     );
  //     if (result['status'] == true) {
  //       emit(LoginSuccess(message: result['message'], token: result['token']));
  //       await storage.write(key: 'token', value: result['token']);
  //       await storage.write(key: 'employeeFileNo', value: employeeFileNo);
  //       await storage.write(key: 'password', value: password);

  //     } else {
  //       emit(LoginFailure(errorMessage: 'Invalid Credentials'));
  //     }
  //   } catch (e) {
  //     emit(LoginFailure(errorMessage: e.toString()));
  //   }
  // }

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
