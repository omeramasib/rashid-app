import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/cv.dart';
import '../../domain/entities/cv_analysis_result.dart';
import '../../domain/usecases/analyze_cv_usecase.dart';
import '../../domain/usecases/delete_skill_usecase.dart';
import '../../domain/usecases/update_skills_usecase.dart';
import '../../domain/usecases/upload_cv_usecase.dart';

part 'cv_state.dart';

class CvCubit extends Cubit<CvState> {
  final UploadCvUseCase uploadCvUseCase;
  final AnalyzeCvUseCase analyzeCvUseCase;
  final UpdateSkillsUseCase updateSkillsUseCase;
  final DeleteSkillUseCase deleteSkillUseCase;

  CvCubit({
    required this.uploadCvUseCase,
    required this.analyzeCvUseCase,
    required this.updateSkillsUseCase,
    required this.deleteSkillUseCase,
  }) : super(CvInitial());

  Future<void> uploadCv(String filePath, String fileName) async {
    emit(CvUploading());
    final result = await uploadCvUseCase(
      UploadCvParams(filePath: filePath, fileName: fileName),
    );
    result.fold(
      (failure) => emit(CvError(failure.message)),
      (cv) => emit(CvUploaded(cv)),
    );
  }

  Future<void> analyzeCv(String cvId) async {
    emit(CvAnalyzing());
    final result = await analyzeCvUseCase(AnalyzeCvParams(cvId: cvId));
    result.fold(
      (failure) => emit(CvError(failure.message)),
      (analysis) => emit(CvAnalyzed(analysis)),
    );
  }

  Future<void> updateSkills(List<String> skills) async {
    emit(SkillsUpdating());
    final result = await updateSkillsUseCase(
      UpdateSkillsParams(skills: skills),
    );
    result.fold(
      (failure) => emit(CvError(failure.message)),
      (_) => emit(SkillsUpdated()),
    );
  }

  Future<void> deleteSkill(String skill) async {
    emit(SkillDeleting());
    final result = await deleteSkillUseCase(DeleteSkillParams(skill: skill));
    result.fold(
      (failure) => emit(CvError(failure.message)),
      (_) => emit(SkillDeleted()),
    );
  }
}
