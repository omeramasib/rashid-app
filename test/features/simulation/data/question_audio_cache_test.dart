import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rashed_app/core/error/exceptions.dart';
import 'package:rashed_app/features/simulation/data/datasources/question_audio_cache.dart';
import 'package:rashed_app/features/simulation/data/models/question_audio_model.dart';

void main() {
  late Directory root;
  late FileQuestionAudioCache cache;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('question-audio-cache');
    cache = FileQuestionAudioCache(directory: () async => root);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('writes atomically and validates before playback', () async {
    final name = cache.fileName(
      questionId: 'q/1',
      questionText: 'Tell me about yourself.',
    );
    expect(name, startsWith('v${QuestionAudioCache.version}_'));
    expect(name, isNot(contains('/')));

    final wrote = await cache.write(name, _wav());
    expect(wrote, greaterThanOrEqualTo(0));
    final path = await cache.validPath(name);
    expect(path, endsWith(name));
    expect(isPlayableWav(await File(path!).readAsBytes()), isTrue);
    expect(await File('$path.part').exists(), isFalse);

    await cache.evict(name);
    expect(await cache.validPath(name), isNull);
  });

  test('a changed question text or cache version does not reuse the file',
      () async {
    final first = cache.fileName(
      questionId: 'q-1',
      questionText: 'Tell me about yourself.',
    );
    final edited = cache.fileName(
      questionId: 'q-1',
      questionText: 'Tell me about a project.',
    );
    final voiced = cache.fileName(
      questionId: 'q-1',
      questionText: 'Tell me about yourself.',
      voice: 'Kore',
    );
    expect(first, isNot(edited));
    expect(first, isNot(voiced));
  });

  test('an invalid cached file is deleted instead of played', () async {
    final name = cache.fileName(questionId: 'q-1', questionText: 'Question');
    final folder = Directory('${root.path}/question_audio');
    await folder.create(recursive: true);
    await File('${folder.path}/$name').writeAsBytes([1, 2, 3, 4]);

    expect(await cache.validPath(name), isNull);
    expect(await File('${folder.path}/$name').exists(), isFalse);
  });

  test('a write failure becomes a cache exception', () async {
    final blocked = FileQuestionAudioCache(
      directory: () async => Directory('${root.path}/not-a-directory'),
    );
    await File('${root.path}/not-a-directory').writeAsString('file');

    expect(
      blocked.write('q.wav', _wav()),
      throwsA(isA<CacheException>()),
    );
  });

  test('clear removes every cached clip', () async {
    final name = cache.fileName(questionId: 'q-1', questionText: 'Question');
    await cache.write(name, _wav());
    await cache.clear();
    expect(await cache.validPath(name), isNull);
  });
}

Uint8List _wav() {
  final fmt = ByteData(16)
    ..setUint16(0, 1, Endian.little)
    ..setUint16(2, 1, Endian.little)
    ..setUint32(4, 16000, Endian.little)
    ..setUint32(8, 32000, Endian.little)
    ..setUint16(12, 2, Endian.little)
    ..setUint16(14, 16, Endian.little);
  final fmtBytes = fmt.buffer.asUint8List();
  final data = Uint8List(2);
  final payload = (BytesBuilder()
        ..add('fmt '.codeUnits)
        ..add(_le(fmtBytes.length))
        ..add(fmtBytes)
        ..add('data'.codeUnits)
        ..add(_le(data.length))
        ..add(data))
      .toBytes();
  return (BytesBuilder()
        ..add('RIFF'.codeUnits)
        ..add(_le(payload.length))
        ..add('WAVE'.codeUnits)
        ..add(payload))
      .toBytes();
}

Uint8List _le(int value) =>
    (ByteData(4)..setUint32(0, value, Endian.little)).buffer.asUint8List();
