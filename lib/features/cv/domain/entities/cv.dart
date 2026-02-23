import 'package:equatable/equatable.dart';

class Cv extends Equatable {
  final String cvId;
  final String fileUrl;

  const Cv({
    required this.cvId,
    required this.fileUrl,
  });

  @override
  List<Object> get props => [cvId, fileUrl];
}
