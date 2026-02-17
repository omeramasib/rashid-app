import 'package:flutter/widgets.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/auth/clerk_auth_service.dart';
import '../../../../../core/storage/secure_storage_service.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/login_usecase.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final LoginWithEmailUseCase loginWithEmailUseCase;
  final LoginWithLinkedInUseCase loginWithLinkedInUseCase;
  final ClerkAuthService clerkAuthService;
  final SecureStorageService secureStorageService;
  bool isPasswordVisible = false;

  LoginCubit({
    required this.loginWithEmailUseCase,
    required this.loginWithLinkedInUseCase,
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

  /// Login with LinkedIn via Clerk OAuth
  Future<void> loginWithLinkedIn(BuildContext context) async {
    print('DEBUG: LoginCubit - loginWithLinkedIn called');
    emit(LoginLinkedInLoading());

    // Step 1: Get LinkedIn token from Clerk OAuth
    print('DEBUG: LoginCubit - Calling clerkAuthService.signInWithLinkedIn');
    final clerkResult = await clerkAuthService.signInWithLinkedIn(context);
    print(
        'DEBUG: LoginCubit - clerkResult: isSuccess=${clerkResult.isSuccess}, error=${clerkResult.error}, token=${clerkResult.accessToken}');

    if (!clerkResult.isSuccess) {
      emit(LoginFailure(clerkResult.error ?? 'LinkedIn authentication failed'));
      return;
    }

    // Step 2: Send LinkedIn token to backend
    final result = await loginWithLinkedInUseCase(
      LoginWithLinkedInParams(linkedinToken: clerkResult.accessToken!),
    );

    result.fold(
      (failure) async {
        // If LinkedIn connection expired, sign out from Clerk and retry once
        if (failure.message.toLowerCase().contains('expired') ||
            failure.message.toLowerCase().contains('reconnect')) {
          print(
              'DEBUG: LoginCubit - LinkedIn connection expired, signing out and retrying');
          await clerkAuthService.signOut(context);

          // Retry the entire flow
          final retryClerkResult =
              await clerkAuthService.signInWithLinkedIn(context);
          if (!retryClerkResult.isSuccess) {
            emit(LoginFailure(
                retryClerkResult.error ?? 'LinkedIn re-authentication failed'));
            return;
          }

          final retryResult = await loginWithLinkedInUseCase(
            LoginWithLinkedInParams(
                linkedinToken: retryClerkResult.accessToken!),
          );

          retryResult.fold(
            (retryFailure) => emit(LoginFailure(retryFailure.message)),
            (user) async {
              await _storeUserCredentials(user);
              emit(LoginSuccess(user));
            },
          );
        } else {
          emit(LoginFailure(failure.message));
        }
      },
      (user) async {
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
