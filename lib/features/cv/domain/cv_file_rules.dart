import 'entities/selected_cv_file.dart';

enum CvFileProblem { empty, extension, tooLarge, notPdf }

class CvFileRules {
  static const int maxBytes = 10 * 1024 * 1024;

  static CvFileProblem? validate(SelectedCvFile file) {
    final name = file.name.trim().toLowerCase();
    if (!name.endsWith('.pdf')) return CvFileProblem.extension;
    if (file.bytes.isEmpty || file.sizeBytes <= 0) return CvFileProblem.empty;
    final size =
        file.bytes.length > file.sizeBytes ? file.bytes.length : file.sizeBytes;
    if (size > maxBytes) return CvFileProblem.tooLarge;
    if (file.bytes.length < 5 || !_isPdf(file.bytes)) {
      return CvFileProblem.notPdf;
    }
    return null;
  }

  static bool _isPdf(List<int> bytes) {
    return bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46 &&
        bytes[4] == 0x2D;
  }
}
