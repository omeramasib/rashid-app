import '../../cv/domain/entities/cv_profile.dart';

/// Where interview simulation may go after GET /cv/me succeeds.
enum InterviewCvGateDestination { setup, completeProfile }

/// Processed profiles open setup. A missing CV and pending, in-progress, or
/// failed analysis continue in the CV flow. Transport failures are not a
/// destination.
InterviewCvGateDestination interviewCvGateDestination(CvProfile? profile) {
  if (profile != null && profile.status == CvAnalysisStatus.processed) {
    return InterviewCvGateDestination.setup;
  }
  return InterviewCvGateDestination.completeProfile;
}
