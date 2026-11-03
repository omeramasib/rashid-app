import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class SelectedCvFile extends Equatable {
  final String name;
  final int sizeBytes;
  final Uint8List bytes;

  const SelectedCvFile({
    required this.name,
    required this.sizeBytes,
    required this.bytes,
  });

  @override
  List<Object> get props => [name, sizeBytes];
}
