import 'package:equatable/equatable.dart';

class LinkedInPublishResult extends Equatable {
  final String? postUrl;

  const LinkedInPublishResult({this.postUrl});

  @override
  List<Object?> get props => [postUrl];
}
