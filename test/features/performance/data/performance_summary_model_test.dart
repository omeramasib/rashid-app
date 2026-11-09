import 'package:flutter_test/flutter_test.dart';
import 'package:rashed_app/features/performance/data/models/performance_summary_model.dart';
import 'package:rashed_app/features/performance/domain/entities/performance_summary.dart';

void main() {
  test('parses a full performance summary', () {
    final summary = PerformanceSummaryModel.fromJson({
      'total_simulations': 3,
      'average_score': 72,
      'best_score': 85,
      'recent_interviews': [
        {
          'simulation_id': ' 11111111-1111-1111-1111-111111111111 ',
          'job_field': ' برمجة ',
          'completed_at': '2026-11-05T08:30:00',
          'score': 85,
          'performance_status': 'excellent',
        },
        {
          'simulation_id': '22222222-2222-2222-2222-222222222222',
          'job_field': 'تحليل',
          'completed_at': '2026-11-04T08:30:00Z',
          'score': 60,
          'performance_status': 'average',
        },
        {
          'simulation_id': '33333333-3333-3333-3333-333333333333',
          'job_field': 'دعم',
          'completed_at': '2026-11-05T08:30:00+03:00',
          'score': 40,
          'performance_status': 'poor',
        },
      ],
    });

    expect(summary.totalSimulations, 3);
    expect(summary.averageScore, 72);
    expect(summary.bestScore, 85);
    expect(summary.bestSimulationId, isNull);
    expect(summary.recentInterviews, hasLength(3));
    expect(
      summary.recentInterviews[0].simulationId,
      '11111111-1111-1111-1111-111111111111',
    );
    expect(summary.recentInterviews[0].jobField, 'برمجة');
    expect(
      summary.recentInterviews[0].completedAt,
      DateTime.utc(2026, 11, 5, 8, 30),
    );
    expect(summary.recentInterviews[0].completedAt!.isUtc, isTrue);
    expect(summary.recentInterviews[0].score, 85);
    expect(
      summary.recentInterviews[0].performanceStatus,
      PerformanceStatus.excellent,
    );
    expect(
      summary.recentInterviews[1].completedAt,
      DateTime.utc(2026, 11, 4, 8, 30),
    );
    expect(
      summary.recentInterviews[1].performanceStatus,
      PerformanceStatus.average,
    );
    expect(
      summary.recentInterviews[2].completedAt,
      DateTime.utc(2026, 11, 5, 5, 30),
    );
    expect(
      summary.recentInterviews[2].performanceStatus,
      PerformanceStatus.poor,
    );
  });

  test('keeps an empty history and null scores', () {
    final summary = PerformanceSummaryModel.fromJson({
      'total_simulations': 0,
      'average_score': null,
      'best_score': null,
      'recent_interviews': [],
    });

    expect(summary.totalSimulations, 0);
    expect(summary.averageScore, isNull);
    expect(summary.bestScore, isNull);
    expect(summary.bestSimulationId, isNull);
    expect(summary.recentInterviews, isEmpty);
  });

  test('does not turn a missing score into zero', () {
    final summary = PerformanceSummaryModel.fromJson({
      'recent_interviews': [
        {
          'simulation_id': 'sim-1',
          'score': null,
          'performance_status': 'unknown',
        },
      ],
    });

    expect(summary.totalSimulations, isNull);
    expect(summary.averageScore, isNull);
    expect(summary.bestScore, isNull);
    expect(summary.recentInterviews.single.score, isNull);
    expect(summary.recentInterviews.single.performanceStatus, isNull);
  });

  test('truncates numeric scores and drops blank interview rows', () {
    final summary = PerformanceSummaryModel.fromJson({
      'total_simulations': 1.9,
      'average_score': 72.8,
      'best_score': '85',
      'recent_interviews': [
        {'job_field': 'برمجة'},
        {'simulation_id': '   '},
        'not-an-object',
        {
          'simulation_id': 'sim-1',
          'job_field': '   ',
          'completed_at': null,
          'score': 70.2,
        },
      ],
    });

    expect(summary.totalSimulations, 1);
    expect(summary.averageScore, 72);
    expect(summary.bestScore, isNull);
    expect(summary.recentInterviews, hasLength(1));
    expect(summary.recentInterviews.single.jobField, isNull);
    expect(summary.recentInterviews.single.completedAt, isNull);
    expect(summary.recentInterviews.single.score, 70);
  });

  test('reads only an explicit best simulation id', () {
    final summary = PerformanceSummaryModel.fromJson({
      'best_score': 90,
      'best_simulation_id': ' sim-best ',
      'recent_interviews': [
        {
          'simulation_id': 'sim-latest',
          'score': 90,
          'completed_at': '2026-11-09T08:30:00Z',
        },
      ],
    });

    expect(summary.bestScore, 90);
    expect(summary.bestSimulationId, 'sim-best');
    expect(summary.recentInterviews.single.simulationId, 'sim-latest');
  });

  test('a blank or non-string best simulation id is ignored', () {
    expect(
      PerformanceSummaryModel.fromJson({
        'best_score': 90,
        'best_simulation_id': '   ',
        'recent_interviews': [
          {'simulation_id': 'sim-latest', 'score': 90},
        ],
      }).bestSimulationId,
      isNull,
    );
    expect(
      PerformanceSummaryModel.fromJson({
        'best_simulation_id': 90,
      }).bestSimulationId,
      isNull,
    );
  });

  test('null and malformed timestamps stay null', () {
    expect(completedAtUtc(null), isNull);
    expect(completedAtUtc(''), isNull);
    expect(completedAtUtc('not-a-date'), isNull);
    expect(completedAtUtc(20261105), isNull);

    final summary = PerformanceSummaryModel.fromJson({
      'recent_interviews': [
        {
          'simulation_id': 'sim-1',
          'job_field': null,
          'completed_at': 'yesterday',
        },
      ],
    });

    expect(summary.recentInterviews.single.jobField, isNull);
    expect(summary.recentInterviews.single.completedAt, isNull);
  });
}
