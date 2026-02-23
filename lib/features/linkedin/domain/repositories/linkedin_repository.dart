import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/linkedin_account.dart';

abstract class LinkedInRepository {
  Future<Either<Failure, LinkedInAccount>> connectLinkedIn(
      String linkedinAccessToken);
  Future<Either<Failure, void>> disconnectLinkedIn();
}
