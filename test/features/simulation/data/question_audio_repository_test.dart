import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/features/simulation/data/datasources/interview_remote_datasource.dart';
import 'package:rashed_app/features/simulation/data/datasources/question_audio_cache.dart';
import 'package:rashed_app/features/simulation/data/repositories/interview_repository_impl.dart';
import 'package:rashed_app/features/simulation/domain/entities/interview_question.dart';
import 'package:rashed_app/features/simulation/domain/entities/question_audio.dart';

class _Source extends Mock implements InterviewRemoteDataSource {}

void main() {
  late Directory root;
  late _Source source;
  late InterviewRepositoryImpl repository;
  const question = InterviewQuestion(
    id: 'q-1',
    questionText: 'Tell me about yourself.',
  );
  const next = InterviewQuestion(
    id: 'q-2',
    questionText: 'How do you handle feedback?',
  );

  setUp(() async {
    root = await Directory.systemTemp.createTemp('question-audio-repo');
    source = _Source();
    repository = InterviewRepositoryImpl(
      remoteDataSource: source,
      audioCache: FileQuestionAudioCache(directory: () async => root),
    );
    when(() => source.downloadQuestionAudio(any())).thenAnswer(
      (_) async => _wav(),
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('a second play is a local cache hit', () async {
    final first = await repository.getQuestionAudio(question);
    final second = await repository.getQuestionAudio(question);

    expect(first.fold((_) => null, (file) => file.source),
        QuestionAudioSource.cold);
    expect(second.fold((_) => null, (file) => file.source),
        QuestionAudioSource.cache);
    verify(() => source.downloadQuestionAudio('q-1')).called(1);
  });

  test('concurrent requests share one download', () async {
    final gate = Completer<Uint8List>();
    when(() => source.downloadQuestionAudio(any()))
        .thenAnswer((_) => gate.future);
    final first = repository.getQuestionAudio(question);
    final second = repository.getQuestionAudio(question);
    gate.complete(_wav());

    final files = await Future.wait([first, second]);
    expect(files.every((result) => result.isRight()), isTrue);
    verify(() => source.downloadQuestionAudio('q-1')).called(1);
  });

  test('a prefetched file is reused without another download', () async {
    final prefetched =
        await repository.getQuestionAudio(question, prefetch: true);
    final shown = await repository.getQuestionAudio(question);

    expect(
      prefetched.fold((_) => null, (file) => file.source),
      QuestionAudioSource.prefetch,
    );
    expect(
      shown.fold((_) => null, (file) => file.source),
      QuestionAudioSource.prefetch,
    );
    expect(shown.fold((_) => null, (file) => file.httpMs),
        greaterThanOrEqualTo(0));
    verify(() => source.downloadQuestionAudio('q-1')).called(1);
    verifyNever(() => source.downloadQuestionAudio('q-2'));
    expect(next.id, 'q-2');
  });

  test('ending the interview cancels downloads and clears the cache', () async {
    await repository.getQuestionAudio(question);
    when(() => source.cancelQuestionAudio()).thenReturn(null);
    await repository.endQuestionAudio();
    verify(() => source.cancelQuestionAudio()).called(1);

    final again = await repository.getQuestionAudio(question);
    expect(again.fold((_) => null, (file) => file.source),
        QuestionAudioSource.cold);
    verify(() => source.downloadQuestionAudio('q-1')).called(2);
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
