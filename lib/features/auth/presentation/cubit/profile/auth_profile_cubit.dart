import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import '../../../../../core/auth/clerk_auth_service.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../domain/usecases/change_password_usecase.dart';
import '../../../domain/usecases/get_current_user_usecase.dart';
import '../../../domain/usecases/link_linkedin_usecase.dart';
import '../../../domain/usecases/logout_usecase.dart';
import 'auth_profile_state.dart';

class AuthProfileCubit extends Cubit<AuthProfileState> {
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final ChangePasswordUseCase changePasswordUseCase;
  final LogoutUseCase logoutUseCase;
  final LinkLinkedInUseCase linkLinkedInUseCase;
  final ClerkAuthService clerkAuthService;
  var _linking = false;

  AuthProfileCubit({
    required this.getCurrentUserUseCase,
    required this.changePasswordUseCase,
    required this.logoutUseCase,
    required this.linkLinkedInUseCase,
    required this.clerkAuthService,
  }) : super(AuthProfileInitial());

  Future<void> getCurrentUser() async {
    emit(AuthProfileLoading());
    final result = await getCurrentUserUseCase(NoParams());
    result.fold(
      (failure) => emit(AuthProfileError(failure.message)),
      (user) => emit(AuthProfileLoaded(user)),
    );
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    emit(AuthProfileLoading());
    final result = await changePasswordUseCase(
      ChangePasswordParams(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );
    result.fold(
      (failure) => emit(AuthProfileError(failure.message)),
      (_) => emit(PasswordChangeSuccess()),
    );
  }

  /// Attaches the Clerk LinkedIn subject after a fresh Clerk sign-in.
  /// A blank password never reaches the API.
  Future<void> connectLinkedIn(
    BuildContext context,
    String currentPassword,
  ) async {
    if (currentPassword.trim().isEmpty) {
      emit(const AuthProfileError('Current password is required'));
      return;
    }
    if (_linking) return;
    _linking = true;
    emit(AuthProfileLoading());
    try {
      final clerkResult = await clerkAuthService.signInWithLinkedIn(context);
      if (isClosed) return;
      if (!clerkResult.isSuccess) {
        emit(AuthProfileError(
          clerkResult.error ?? 'LinkedIn authentication failed',
        ));
        return;
      }
      final result = await linkLinkedInUseCase(
        LinkLinkedInParams(
          clerkSessionJwt: clerkResult.accessToken!,
          currentPassword: currentPassword,
        ),
      );
      if (isClosed) return;
      await result.fold<Future<void>>(
        (failure) async => emit(AuthProfileError(failure.message)),
        (_) async {
          final me = await getCurrentUserUseCase(NoParams());
          if (isClosed) return;
          me.fold(
            (failure) => emit(AuthProfileError(failure.message)),
            (user) => emit(AuthProfileLoaded(user)),
          );
        },
      );
    } catch (_) {
      if (!isClosed) {
        emit(const AuthProfileError('LinkedIn authentication failed'));
      }
    } finally {
      _linking = false;
    }
  }

  /// Attaches a Clerk session that the caller already obtained.
  /// A blank password never reaches the API, and a matching email is not used.
  Future<void> linkLinkedIn({
    required String clerkSessionJwt,
    required String currentPassword,
  }) async {
    if (currentPassword.trim().isEmpty) {
      emit(const AuthProfileError('Current password is required'));
      return;
    }
    emit(AuthProfileLoading());
    final result = await linkLinkedInUseCase(
      LinkLinkedInParams(
        clerkSessionJwt: clerkSessionJwt,
        currentPassword: currentPassword,
      ),
    );
    result.fold(
      (failure) => emit(AuthProfileError(failure.message)),
      (_) => emit(LinkedInAccountLinked()),
    );
  }

  Future<void> logout() async {
    emit(AuthProfileLoading());
    final result = await logoutUseCase(NoParams());
    result.fold(
      (failure) => emit(AuthProfileError(failure.message)),
      (_) => emit(AuthProfileLoggedOut()),
    );
  }
}
