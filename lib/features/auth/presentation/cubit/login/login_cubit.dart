import 'package:flutter/widgets.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/auth/clerk_auth_service.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/storage/secure_storage_service.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/login_usecase.dart';
import '../../../domain/usecases/register_usecase.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final LoginWithEmailUseCase loginWithEmailUseCase;
  final LoginWithLinkedInUseCase loginWithLinkedInUseCase;
  final RegisterWithLinkedInUseCase registerWithLinkedInUseCase;
  final ClerkAuthService clerkAuthService;
  final SecureStorageService secureStorageService;
  bool isPasswordVisible = false;

  LoginCubit({
    required this.loginWithEmailUseCase,
    required this.loginWithLinkedInUseCase,
    required this.registerWithLinkedInUseCase,
    required this.clerkAuthService,
    required this.secureStorageService,
  }) : super(LoginInitial());

  /// Login with email and password
  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    emit(LoginLoading());

    final result = await loginWithEmailUseCase(
      LoginWithEmailParams(email: email, password: password),
    );

    result.fold(
      (failure) => emit(LoginFailure(failure.message)),
      (user) async {
        await _storeUserCredentials(user, email: email);
        emit(LoginSuccess(user));
      },
    );
  }

  /// Login with LinkedIn via Clerk OAuth.
  /// If the user is not found (404), automatically registers them.
  Future<void> loginWithLinkedIn(BuildContext context) async {
    print('DEBUG: LoginCubit - loginWithLinkedIn called');
    emit(LoginLinkedInLoading());

    // Step 1: Get Clerk session JWT
    print('DEBUG: LoginCubit - Calling clerkAuthService.signInWithLinkedIn');
    final clerkResult = await clerkAuthService.signInWithLinkedIn(context);
    print(
        'DEBUG: LoginCubit - clerkResult: isSuccess=${clerkResult.isSuccess}, error=${clerkResult.error}');

    if (!clerkResult.isSuccess) {
      emit(LoginFailure(clerkResult.error ?? 'LinkedIn authentication failed'));
      return;
    }

    final jwt = clerkResult.accessToken!;

    // Step 2: Try login
    print('DEBUG: LoginCubit - Attempting LinkedIn login');
    final loginResult = await loginWithLinkedInUseCase(
      LoginWithLinkedInParams(clerkSessionJwt: jwt),
    );

    await loginResult.fold(
      (failure) async {
        if (failure is UserNotFoundFailure) {
          // Step 3: User not found → auto-register
          print('DEBUG: LoginCubit - User not found, auto-registering');
          final registerResult = await registerWithLinkedInUseCase(
            RegisterWithLinkedInParams(clerkSessionJwt: jwt),
          );

          registerResult.fold(
            (regFailure) => emit(LoginFailure(regFailure.message)),
            (user) async {
              print('DEBUG: LoginCubit - Auto-registration successful');
              await _storeUserCredentials(user);
              emit(LoginSuccess(user));
            },
          );
        } else {
          emit(LoginFailure(failure.message));
        }
      },
      (user) async {
        print('DEBUG: LoginCubit - LinkedIn login successful');
        await _storeUserCredentials(user);
        emit(LoginSuccess(user));
      },
    );
  }

  /// Store user credentials in secure storage
  Future<void> _storeUserCredentials(User user, {String? email}) async {
    if (user.token != null) {
      await secureStorageService.write(key: 'token', value: user.token!);
    }
    if (user.id != null) {
      await secureStorageService.write(key: 'user_id', value: user.id!);
    }
    if (email != null) {
      await secureStorageService.write(key: 'email', value: email);
    } else if (user.email != null) {
      await secureStorageService.write(key: 'email', value: user.email!);
    }
  }

  void viewPassword() {
    isPasswordVisible = !isPasswordVisible;
    emit(ViewPasswordState(enabled: isPasswordVisible));
  }
}
