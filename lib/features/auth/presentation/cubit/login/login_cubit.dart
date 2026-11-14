import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/auth/clerk_auth_service.dart';
import '../../../../../core/auth/rashed_session.dart';
import '../../../../../core/error/failures.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/linkedin_auth_conflicts.dart';
import '../../../domain/usecases/login_usecase.dart';
import '../../../domain/usecases/register_usecase.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final LoginWithEmailUseCase loginWithEmailUseCase;
  final LoginWithLinkedInUseCase loginWithLinkedInUseCase;
  final RegisterWithLinkedInUseCase registerWithLinkedInUseCase;
  final ClerkAuthService clerkAuthService;
  final RashedSession session;
  bool isPasswordVisible = false;
  var _linkedinBusy = false;
  var _generation = 0;
  late final StreamSubscription<void> _sessionSub;

  LoginCubit({
    required this.loginWithEmailUseCase,
    required this.loginWithLinkedInUseCase,
    required this.registerWithLinkedInUseCase,
    required this.clerkAuthService,
    required this.session,
  }) : super(LoginInitial()) {
    _sessionSub = session.onCleared.listen((_) {
      _generation++;
      _linkedinBusy = false;
      if (!isClosed) emit(LoginInitial());
    });
  }

  /// Login with email and password.
  /// A missing Rashed user is not registered through LinkedIn.
  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    emit(LoginLoading());

    final result = await loginWithEmailUseCase(
      LoginWithEmailParams(email: email, password: password),
    );

    await result.fold<Future<void>>(
      (failure) async => emit(LoginFailure(failure.message)),
      (user) => _completeLogin(
        user,
        email: email,
        missingTokenMessage: 'Login failed',
      ),
    );
  }

  /// Login with LinkedIn via Clerk OAuth.
  ///
  /// A 404 from this call is the only registration trigger. Clerk success
  /// alone does not create a Rashed session.
  Future<void> loginWithLinkedIn(BuildContext context) async {
    if (_linkedinBusy) return;
    _linkedinBusy = true;
    final generation = ++_generation;
    emit(LoginLinkedInLoading());
    try {
      final clerkResult = await clerkAuthService.signInWithLinkedIn(context);
      if (!_current(generation)) return;
      if (!clerkResult.isSuccess) {
        emit(LoginFailure(
          clerkResult.error ?? 'LinkedIn authentication failed',
        ));
        return;
      }

      final jwt = clerkResult.accessToken!;
      final loginResult = await loginWithLinkedInUseCase(
        LoginWithLinkedInParams(clerkSessionJwt: jwt),
      );
      if (!_current(generation)) return;

      await loginResult.fold<Future<void>>(
        (failure) async {
          if (failure is! NotFoundFailure && failure is! UserNotFoundFailure) {
            emit(_linkedInFailure(failure));
            return;
          }
          final registerResult = await registerWithLinkedInUseCase(
            RegisterWithLinkedInParams(clerkSessionJwt: jwt),
          );
          if (!_current(generation)) return;
          await registerResult.fold<Future<void>>(
            (regFailure) async => emit(_linkedInFailure(regFailure)),
            (user) => _completeLogin(user),
          );
        },
        (user) => _completeLogin(user),
      );
    } catch (_) {
      if (_current(generation)) {
        emit(const LoginFailure('LinkedIn authentication failed'));
      }
    } finally {
      if (generation == _generation) _linkedinBusy = false;
    }
  }

  bool _current(int generation) => !isClosed && generation == _generation;

  Future<void> _completeLogin(
    User user, {
    String? email,
    String missingTokenMessage = 'LinkedIn authentication failed',
  }) async {
    if (!user.hasToken) {
      emit(LoginFailure(missingTokenMessage));
      return;
    }
    await session.persist(
      token: user.token,
      userId: user.id,
      email: email ?? user.email,
    );
    if (!isClosed) emit(LoginSuccess(user));
  }

  LoginFailure _linkedInFailure(Failure failure) {
    return LoginFailure(
      failure.message,
      offerEmailSignIn:
          LinkedInAuthConflicts.offersEmailSignIn(failure.message) &&
              failure is ConflictFailure,
    );
  }

  void viewPassword() {
    isPasswordVisible = !isPasswordVisible;
    emit(ViewPasswordState(enabled: isPasswordVisible));
  }

  @override
  Future<void> close() async {
    await _sessionSub.cancel();
    return super.close();
  }
}
