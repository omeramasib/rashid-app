import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/share_result.dart';
import '../repositories/home_repository.dart';

class ShareInterviewResultUseCase
    implements UseCase<ShareResult, ShareInterviewResultParams> {
  final HomeRepository repository;

  ShareInterviewResultUseCase(this.repository);

  @override
  Future<Either<Failure, ShareResult>> call(
      ShareInterviewResultParams params) async {
    return await repository.shareLastInterviewResult(params.caption);
  }
}

class ShareInterviewResultParams extends Equatable {
  final String? caption;

  const ShareInterviewResultParams({this.caption});

  @override
  List<Object?> get props => [caption];
}
