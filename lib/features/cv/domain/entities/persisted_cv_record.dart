import 'package:equatable/equatable.dart';

/// Per-user CV identifiers. Bytes, signed URLs, and analysis text are never stored.
class PersistedCvRecord extends Equatable {
  final String uploadedCvId;
  final String? analyzedCvId;

  const PersistedCvRecord({
    required this.uploadedCvId,
    this.analyzedCvId,
  });

  bool get analysisCompleted =>
      analyzedCvId != null && analyzedCvId == uploadedCvId;

  Map<String, dynamic> toJson() => {
        'uploadedCvId': uploadedCvId,
        'analyzedCvId': analyzedCvId,
      };

  factory PersistedCvRecord.fromJson(Map<String, dynamic> json) {
    final uploaded = json['uploadedCvId'];
    if (uploaded is! String || uploaded.isEmpty) {
      throw const FormatException('uploadedCvId');
    }
    final analyzed = json['analyzedCvId'];
    return PersistedCvRecord(
      uploadedCvId: uploaded,
      analyzedCvId: analyzed is String && analyzed.isNotEmpty ? analyzed : null,
    );
  }

  @override
  List<Object?> get props => [uploadedCvId, analyzedCvId];
}
