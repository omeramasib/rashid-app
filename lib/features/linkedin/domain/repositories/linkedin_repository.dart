import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/linkedin_connection_status.dart';
import '../entities/linkedin_mark_deleted_result.dart';
import '../entities/linkedin_oauth_start.dart';
import '../entities/linkedin_publish_result.dart';
import '../entities/linkedin_share_preview.dart';

abstract class LinkedInRepository {
  Future<Either<Failure, LinkedInConnectionStatus>> getStatus();

  Future<Either<Failure, LinkedInOAuthStart>> startOAuth(String simulationId);

  Future<Either<Failure, LinkedInSharePreview>> previewShare(
    String simulationId,
  );

  Future<Either<Failure, LinkedInPublishResult>> publish({
    required String previewId,
    required String simulationId,
    required String contentSha256,
  });

  Future<Either<Failure, LinkedInMarkDeletedResult>> markDeleted({
    required String shareId,
  });

  Future<Either<Failure, void>> disconnect();
}
