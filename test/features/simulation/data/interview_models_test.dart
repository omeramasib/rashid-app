import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rashed_app/features/simulation/data/models/answer_evaluation_model.dart';
import 'package:rashed_app/features/simulation/data/models/interview_finish_result_model.dart';
import 'package:rashed_app/features/simulation/data/models/interview_question_model.dart';
import 'package:rashed_app/features/simulation/data/models/interview_report_model.dart';
import 'package:rashed_app/features/simulation/data/models/interview_start_response_model.dart';
import 'package:rashed_app/features/simulation/data/models/question_audio_model.dart';
import 'package:rashed_app/features/simulation/domain/entities/question_audio.dart';

void main() {
  test('parses a start payload including optional question fields', () {
    final response = InterviewStartResponseModel.fromJson({
      'simulation_id': 'sim-1',
      'interview_setting_id': 'setting-1',
      'status': 'ready',
      'report_status': 'pending',
      'questions': [
        {
          'id': 'q-1',
          'question_text': 'Tell me about a project.',
          'audio_url': null,
          'category': 'technical',
          'position': 1,
        },
      ],
    });

    expect(response.simulationId, 'sim-1');
    expect(response.interviewSettingId, 'setting-1');
    expect(response.status, 'ready');
    expect(response.reportStatus, 'pending');
    expect(response.questions.single.questionText, 'Tell me about a project.');
    expect(response.questions.single.audioUrl, isNull);
    expect(response.questions.single.category, 'technical');
    expect(response.questions.single.position, 1);
  });

  test('keeps missing evaluation fields null', () {
    final evaluation = AnswerEvaluationModel.fromJson({
      'question_id': 'q-1',
      'score': null,
      'strengths': null,
      'weaknesses': ['Too short'],
      'suggested_answer': null,
      'skipped': false,
    });

    expect(evaluation.score, isNull);
    expect(evaluation.strengths, isNull);
    expect(evaluation.weaknesses, ['Too short']);
    expect(evaluation.suggestedAnswer, isNull);
    expect(evaluation.skipped, isFalse);
  });

  test('parses a skip evaluation', () {
    final evaluation = AnswerEvaluationModel.fromJson({
      'question_id': 'q-1',
      'score': null,
      'strengths': null,
      'weaknesses': null,
      'suggested_answer': null,
      'skipped': true,
    });

    expect(evaluation.skipped, isTrue);
    expect(evaluation.score, isNull);
  });

  test('parses finish data and leaves an absent summary null', () {
    final result = InterviewFinishResultModel.fromJson({
      'simulation_id': 'sim-1',
      'score': 82,
      'performance_status': 'excellent',
      'total_questions': 2,
      'answered_questions': 1,
      'skipped_questions': 1,
      'unanswered_questions': 0,
      'status': 'completed',
      'report_status': 'completed',
      'report_summary': null,
    });

    expect(result.score, 82);
    expect(result.performanceStatus, 'excellent');
    expect(result.totalQuestions, 2);
    expect(result.answeredQuestions, 1);
    expect(result.skippedQuestions, 1);
    expect(result.unansweredQuestions, 0);
    expect(result.reportSummary, isNull);
  });

  test('parses a report and does not invent missing sections', () {
    final report = InterviewReportModel.fromJson({
      'simulation_id': 'sim-1',
      'score': null,
      'performance_status': null,
      'job_field': 'Nurse',
      'interview_type': 'technical',
      'difficulty': 'medium',
      'language': 'English',
      'status': 'completed',
      'report_status': 'failed',
      'report_summary': null,
      'strengths': null,
      'improvements': [],
      'recommendations': null,
      'date': null,
      'completed_at': null,
      'answered_questions': 0,
      'skipped_questions': 0,
      'unanswered_questions': 1,
      'questions': [
        {
          'id': 'q-1',
          'question_text': 'Why this role?',
          'answer_text': null,
          'evaluation_score': null,
          'strengths': null,
          'weaknesses': null,
          'suggested_answer': null,
          'is_skipped': false,
          'category': null,
          'position': 1,
        },
      ],
    });

    expect(report.score, isNull);
    expect(report.strengths, isNull);
    expect(report.improvements, isEmpty);
    expect(report.recommendations, isNull);
    expect(report.reportSummary, isNull);
    expect(report.questions.single.evaluationScore, isNull);
    expect(report.questions.single.answerText, isNull);
    expect(report.questions.single.isSkipped, isFalse);
  });

  test('parses nullable and missing question audio without dropping the text',
      () {
    final withNulls = InterviewQuestionModel.fromJson({
      'id': 'q-1',
      'question_text': 'Tell me about yourself.',
      'audio_url': null,
      'audio': {
        'status': 'pending',
        'url': null,
        'mime_type': null,
        'duration_ms': null,
      },
    });
    expect(withNulls.questionText, 'Tell me about yourself.');
    expect(withNulls.audioUrl, isNull);
    expect(withNulls.audio?.status, QuestionAudioStatus.pending);
    expect(withNulls.audio?.url, isNull);

    final missing = InterviewQuestionModel.fromJson({
      'id': 'q-2',
      'question_text': 'Still visible.',
    });
    expect(missing.audio, isNull);
    expect(missing.questionText, 'Still visible.');

    final malformed = InterviewQuestionModel.fromJson({
      'id': 'q-3',
      'question_text': 'Still visible.',
      'audio': {'status': 'later'},
    });
    expect(malformed.audio, isNull);
  });

  test('accepts a wav payload and rejects unplayable bytes', () {
    expect(isPlayableWav(_sampleWav(), contentType: 'audio/wav'), isTrue);
    expect(isPlayableWav(Uint8List(0), contentType: 'audio/wav'), isFalse);
    expect(
      isPlayableWav(_sampleWav(), contentType: 'audio/mpeg'),
      isFalse,
    );
    expect(isPlayableWav(Uint8List.fromList([1, 2, 3, 4])), isFalse);
  });
}

Uint8List _sampleWav() {
  final fmt = ByteData(16)
    ..setUint16(0, 1, Endian.little)
    ..setUint16(2, 1, Endian.little)
    ..setUint32(4, 16000, Endian.little)
    ..setUint32(8, 32000, Endian.little)
    ..setUint16(12, 2, Endian.little)
    ..setUint16(14, 16, Endian.little);
  final fmtBytes = fmt.buffer.asUint8List();
  final data = Uint8List(2);
  final chunks = BytesBuilder()
    ..add('fmt '.codeUnits)
    ..add(_le32(fmtBytes.length))
    ..add(fmtBytes)
    ..add('data'.codeUnits)
    ..add(_le32(data.length))
    ..add(data);
  final payload = chunks.toBytes();
  return (BytesBuilder()
        ..add('RIFF'.codeUnits)
        ..add(_le32(payload.length))
        ..add('WAVE'.codeUnits)
        ..add(payload))
      .toBytes();
}

Uint8List _le32(int value) {
  return (ByteData(4)..setUint32(0, value, Endian.little)).buffer.asUint8List();
}
