import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/linkedin_account.dart';
import '../../domain/usecases/connect_linkedin_usecase.dart';
import '../../domain/usecases/disconnect_linkedin_usecase.dart';

part 'linkedin_state.dart';

class LinkedInCubit extends Cubit<LinkedInState> {
  final ConnectLinkedInUseCase connectLinkedInUseCase;
  final DisconnectLinkedInUseCase disconnectLinkedInUseCase;

  LinkedInCubit({
    required this.connectLinkedInUseCase,
    required this.disconnectLinkedInUseCase,
  }) : super(LinkedInInitial());

  Future<void> connect(String linkedinAccessToken) async {
    emit(LinkedInLoading());
    final result = await connectLinkedInUseCase(
      ConnectLinkedInParams(linkedinAccessToken: linkedinAccessToken),
    );
    result.fold(
      (failure) => emit(LinkedInError(failure.message)),
      (account) => emit(LinkedInConnected(account)),
    );
  }

  Future<void> disconnect() async {
    emit(LinkedInLoading());
    final result = await disconnectLinkedInUseCase(NoParams());
    result.fold(
      (failure) => emit(LinkedInError(failure.message)),
      (_) => emit(LinkedInDisconnected()),
    );
  }
}
