import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rashed_app/features/cv/domain/cv_file_rules.dart';
import 'package:rashed_app/features/cv/domain/entities/selected_cv_file.dart';

void main() {
  SelectedCvFile file(String name, Uint8List bytes, {int? size}) {
    return SelectedCvFile(
      name: name,
      sizeBytes: size ?? bytes.length,
      bytes: bytes,
    );
  }

  final pdf = Uint8List.fromList('%PDF-1.4\n'.codeUnits);

  test('accepts a PDF at the 10 MiB limit', () {
    expect(
      CvFileRules.validate(file('Resume.PDF', pdf, size: CvFileRules.maxBytes)),
      isNull,
    );
  });

  test('rejects the wrong extension, an empty file, a non-PDF, and 10 MiB + 1',
      () {
    expect(
      CvFileRules.validate(file('notes.txt', pdf)),
      CvFileProblem.extension,
    );
    expect(
      CvFileRules.validate(
        SelectedCvFile(name: 'empty.pdf', sizeBytes: 0, bytes: Uint8List(0)),
      ),
      CvFileProblem.empty,
    );
    expect(
      CvFileRules.validate(
          file('cv.pdf', Uint8List.fromList('hello'.codeUnits))),
      CvFileProblem.notPdf,
    );
    expect(
      CvFileRules.validate(file('cv.pdf', pdf, size: CvFileRules.maxBytes + 1)),
      CvFileProblem.tooLarge,
    );
  });
}
