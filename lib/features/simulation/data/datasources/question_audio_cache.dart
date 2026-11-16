import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../../../core/error/exceptions.dart';
import '../models/question_audio_model.dart';

/// Local WAV files for direct question audio.
///
/// [version] is part of every filename. The interview payload does not yet
/// include the TTS model, voice, or format. Increment [version] when any of
/// those change, or a cached clip from the previous configuration will play.
/// When the payload does include them, pass them into [fileName]; they are
/// already part of the hash.
abstract class QuestionAudioCache {
  static const int version = 1;

  String fileName({
    required String questionId,
    required String questionText,
    String? model,
    String? voice,
    String? format,
  });

  /// A path that already passed [isPlayableWav], or null.
  Future<String?> validPath(String fileName);

  /// Writes atomically. Returns how long the write took, in milliseconds.
  Future<int> write(String fileName, Uint8List bytes);

  Future<void> evict(String fileName);

  Future<void> clear();
}

class FileQuestionAudioCache implements QuestionAudioCache {
  FileQuestionAudioCache({required this.directory});

  final Future<Directory> Function() directory;

  @override
  String fileName({
    required String questionId,
    required String questionText,
    String? model,
    String? voice,
    String? format,
  }) {
    final safe = questionId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final trimmed = safe.length > 80 ? safe.substring(0, 80) : safe;
    final identity = [
      '${QuestionAudioCache.version}',
      model ?? '',
      voice ?? '',
      format ?? '',
      questionText,
    ].join('\u001f');
    final hash =
        _fnv1a64(utf8.encode(identity)).toRadixString(16).padLeft(16, '0');
    return 'v${QuestionAudioCache.version}_${trimmed}_$hash.wav';
  }

  @override
  Future<String?> validPath(String fileName) async {
    final file = await _file(fileName);
    if (!await file.exists()) return null;
    try {
      final bytes = await file.readAsBytes();
      if (isPlayableWav(bytes)) return file.path;
    } catch (_) {}
    await _deleteQuiet(file);
    return null;
  }

  @override
  Future<int> write(String fileName, Uint8List bytes) async {
    if (!isPlayableWav(bytes)) {
      throw CacheException('Invalid question audio');
    }
    final target = await _file(fileName);
    final part = File('${target.path}.part');
    final watch = Stopwatch()..start();
    try {
      await target.parent.create(recursive: true);
      await part.writeAsBytes(bytes, flush: true);
      if (await target.exists()) await target.delete();
      await part.rename(target.path);
    } on FileSystemException catch (error) {
      await _deleteQuiet(part);
      throw CacheException(error.message);
    }
    return watch.elapsedMilliseconds;
  }

  @override
  Future<void> evict(String fileName) async {
    final file = await _file(fileName);
    await _deleteQuiet(file);
    await _deleteQuiet(File('${file.path}.part'));
  }

  @override
  Future<void> clear() async {
    final folder = await _folder();
    if (await folder.exists()) {
      await folder.delete(recursive: true);
    }
  }

  Future<Directory> _folder() async {
    final root = await directory();
    return Directory('${root.path}/question_audio');
  }

  Future<File> _file(String fileName) async {
    final folder = await _folder();
    return File('${folder.path}/$fileName');
  }

  Future<void> _deleteQuiet(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}

int _fnv1a64(List<int> bytes) {
  var hash = 0xcbf29ce484222325;
  for (final byte in bytes) {
    hash ^= byte;
    hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
  }
  return hash;
}
