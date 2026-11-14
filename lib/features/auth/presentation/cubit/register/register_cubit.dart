import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/auth/clerk_auth_service.dart';
import '../../../../../core/auth/rashed_session.dart';
import '../../../../../core/error/failures.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/linkedin_auth_conflicts.dart';
import '../../../domain/usecases/register_usecase.dart';

part 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final RegisterWithEmailUseCase registerWithEmailUseCase;
  final RegisterWithLinkedInUseCase registerWithLinkedInUseCase;
  final ClerkAuthService clerkAuthService;
  final RashedSession session;
  bool isPasswordVisible = false;
  var _linkedinBusy = false;
  var _generation = 0;
  late final StreamSubscription<void> _sessionSub;

  RegisterCubit({
    required this.registerWithEmailUseCase,
    required this.registerWithLinkedInUseCase,
    required this.clerkAuthService,
    required this.session,
  }) : super(RegisterInitial()) {
    _sessionSub = session.onCleared.listen((_) {
      _generation++;
      _linkedinBusy = false;
      if (!isClosed) emit(RegisterInitial());
    });
  }

  /// Register with email and password.
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

    await result.fold<Future<void>>(
      (failure) async => emit(RegisterFailure(failure.message)),
      (user) async {
        await _persist(user, email: email);
        if (!isClosed) emit(RegisterSuccess(user));
      },
    );
  }

  /// Register with LinkedIn via Clerk OAuth.
  /// This path does not treat a 404 as another registration.
  Future<void> registerWithLinkedIn(BuildContext context) async {
    if (_linkedinBusy) return;
    _linkedinBusy = true;
    final generation = ++_generation;
    emit(RegisterLinkedInLoading());
    try {
      final clerkResult = await clerkAuthService.signInWithLinkedIn(context);
      if (!_current(generation)) return;
      if (!clerkResult.isSuccess) {
        emit(RegisterFailure(
          clerkResult.error ?? 'LinkedIn authentication failed',
        ));
        return;
      }

      final result = await registerWithLinkedInUseCase(
        RegisterWithLinkedInParams(clerkSessionJwt: clerkResult.accessToken!),
      );
      if (!_current(generation)) return;
      await result.fold<Future<void>>(
        (failure) async => emit(_linkedInFailure(failure)),
        (user) async {
          if (!user.hasToken) {
            emit(const RegisterFailure('LinkedIn authentication failed'));
            return;
          }
          await _persist(user);
          if (!isClosed) emit(RegisterSuccess(user));
        },
      );
    } catch (_) {
      if (_current(generation)) {
        emit(const RegisterFailure('LinkedIn authentication failed'));
      }
    } finally {
      if (generation == _generation) _linkedinBusy = false;
    }
  }

  bool _current(int generation) => !isClosed && generation == _generation;

  RegisterFailure _linkedInFailure(Failure failure) {
    return RegisterFailure(
      failure.message,
      offerEmailSignIn:
          LinkedInAuthConflicts.offersEmailSignIn(failure.message) &&
              failure is ConflictFailure,
    );
  }

  Future<void> _persist(User user, {String? email}) {
    return session.persist(
      token: user.token,
      userId: user.id,
      email: email ?? user.email,
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
