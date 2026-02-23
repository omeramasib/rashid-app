import 'package:equatable/equatable.dart';

class ShareResult extends Equatable {
  final String postUrl;
  final String postUrn;

  const ShareResult({required this.postUrl, required this.postUrn});

  @override
  List<Object> get props => [postUrl, postUrn];
}
