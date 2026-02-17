import 'package:flutter/widgets.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/auth/clerk_auth_service.dart';
import '../../../../../core/storage/secure_storage_service.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/register_usecase.dart';

part 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final RegisterWithEmailUseCase registerWithEmailUseCase;
  final RegisterWithLinkedInUseCase registerWithLinkedInUseCase;
  final ClerkAuthService clerkAuthService;
  final SecureStorageService secureStorageService;
  bool isPasswordVisible = false;

  RegisterCubit({
    required this.registerWithEmailUseCase,
    required this.registerWithLinkedInUseCase,
    required this.clerkAuthService,
    required this.secureStorageService,
  }) : super(RegisterInitial());

  /// Register with email and password
  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(RegisterLoading());

    final result = await registerWithEmailUseCase(
      RegisterWithEmailParams(
        name: name,
        email: email,
        password: password,
      ),
    );

    result.fold(
      (failure) => emit(RegisterFailure(failure.message)),
      (user) async {
        await _storeUserCredentials(user, email: email);
        emit(RegisterSuccess(user));
      },
    );
  }

  /// Register with LinkedIn via Clerk OAuth
  Future<void> registerWithLinkedIn(BuildContext context) async {
    emit(RegisterLinkedInLoading());

    // Step 1: Get LinkedIn token from Clerk OAuth
    final clerkResult = await clerkAuthService.signInWithLinkedIn(context);

    if (!clerkResult.isSuccess) {
      emit(RegisterFailure(
        clerkResult.error ?? 'LinkedIn authentication failed',
      ));
      return;
    }

    // Step 2: Send LinkedIn token to backend for registration
    final result = await registerWithLinkedInUseCase(
      RegisterWithLinkedInParams(linkedinToken: clerkResult.accessToken!),
    );

    result.fold(
      (failure) => emit(RegisterFailure(failure.message)),
      (user) async {
        await _storeUserCredentials(user);
        emit(RegisterSuccess(user));
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
