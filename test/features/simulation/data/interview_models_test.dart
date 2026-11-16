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

  test('parses each question audio status', () {
    QuestionAudioModel parse(String status, {String? url, String? mime}) {
      return QuestionAudioModel.fromJson({
        'question_id': 'q-1',
        'status': status,
        'audio_url': url,
        'mime_type': mime,
        'duration_ms': status == 'ready' ? 3280 : null,
        'expires_in_seconds': status == 'ready' ? 300 : null,
      });
    }

    expect(parse('pending').status, QuestionAudioStatus.pending);
    expect(parse('processing').audioUrl, isNull);
    expect(parse('failed').status, QuestionAudioStatus.failed);
    expect(parse('disabled').status, QuestionAudioStatus.disabled);
    final ready = parse(
      'ready',
      url: 'https://example.test/a.wav?signature=secret',
      mime: 'audio/wav; codecs=1',
    );
    expect(ready.status, QuestionAudioStatus.ready);
    expect(ready.audioUrl, contains('signature=secret'));
    expect(ready.mimeType, 'audio/wav; codecs=1');
    expect(ready.durationMs, 3280);
    expect(ready.expiresInSeconds, 300);
  });

  test('rejects a ready payload that cannot be played', () {
    expect(
      () => QuestionAudioModel.fromJson({
        'question_id': 'q-1',
        'status': 'ready',
        'audio_url': '',
        'mime_type': 'audio/wav',
      }),
      throwsFormatException,
    );
    expect(
      () => QuestionAudioModel.fromJson({
        'question_id': 'q-1',
        'status': 'ready',
        'audio_url': 'https://example.test/a.mp3',
        'mime_type': 'audio/mpeg',
      }),
      throwsFormatException,
    );
    expect(
      () => QuestionAudioModel.fromJson({
        'question_id': 'q-1',
        'status': 'unknown',
      }),
      throwsFormatException,
    );
  });
}
