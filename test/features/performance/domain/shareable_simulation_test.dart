import 'package:flutter_test/flutter_test.dart';
import 'package:rashed_app/features/performance/domain/entities/performance_summary.dart';
import 'package:rashed_app/features/performance/domain/shareable_simulation.dart';

void main() {
  const older = RecentInterview(
    simulationId: 'sim-older',
    jobField: 'Support',
    completedAt: null,
    score: 99,
  );
  final newest = RecentInterview(
    simulationId: 'sim-newest',
    jobField: 'Programming',
    completedAt: DateTime.utc(2026, 11, 9),
    score: 70,
  );
  final middle = RecentInterview(
    simulationId: 'sim-middle',
    jobField: 'Analysis',
    completedAt: DateTime.utc(2026, 11, 4),
    score: 90,
  );

  test('the only scored interview is the latest result', () {
    expect(
      latestShareableInterview([
        const RecentInterview(simulationId: ' ', score: 10),
        const RecentInterview(simulationId: '   ', score: 10),
        const RecentInterview(simulationId: 'sim-only', score: 80),
        const RecentInterview(simulationId: 'unscored'),
      ])?.simulationId,
      'sim-only',
    );
  });

  test('a later completion wins over a higher score and list order', () {
    expect(
      latestShareableInterview([middle, newest])?.simulationId,
      'sim-newest',
    );
    expect(
      latestShareableInterview([newest, middle])?.simulationId,
      'sim-newest',
    );
  });

  test('equal completion times keep the first returned interview', () {
    final tied = RecentInterview(
      simulationId: 'sim-tied',
      completedAt: newest.completedAt,
      score: 70,
    );

    expect(
      latestShareableInterview([newest, tied])?.simulationId,
      'sim-newest',
    );
  });

  test('missing completion times make several results ambiguous', () {
    expect(latestShareableInterview([older, newest]), isNull);
    expect(
      latestShareableInterview(const [
        RecentInterview(simulationId: 'sim-a', score: 10),
        RecentInterview(simulationId: 'sim-b', score: 20),
      ]),
      isNull,
    );
  });

  test('no scored interview leaves sharing unavailable', () {
    expect(latestShareableInterview(const []), isNull);
    expect(
      latestShareableInterview(const [
        RecentInterview(simulationId: 'sim-a'),
      ]),
      isNull,
    );
  });

  test('the best share id is never taken from the latest interview', () {
    final summary = PerformanceSummary(
      bestScore: 99,
      recentInterviews: [newest, older],
    );

    expect(bestShareableSimulationId(summary), isNull);
    expect(
      bestShareableSimulationId(
        PerformanceSummary(
          bestScore: 70,
          bestSimulationId: ' sim-best ',
          recentInterviews: [newest],
        ),
      ),
      'sim-best',
    );
    expect(
      bestShareableSimulationId(
        const PerformanceSummary(bestSimulationId: '   '),
      ),
      isNull,
    );
  });
}
