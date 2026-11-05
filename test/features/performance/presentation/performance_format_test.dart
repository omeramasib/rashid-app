import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:rashed_app/features/performance/domain/entities/performance_summary.dart';
import 'package:rashed_app/features/performance/presentation/performance_format.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  const english = {
    'rating_excellent': 'Excellent',
    'rating_average': 'Average',
    'performance_status_poor': 'Poor',
    'performance_mock_interview': 'Mock Interview',
  };
  const arabic = {
    'rating_excellent': 'ممتاز',
    'rating_average': 'متوسط',
    'performance_status_poor': 'ضعيف',
    'performance_mock_interview': 'مقابلة محاكاة',
  };

  String translate(Map<String, String> catalog, String key) {
    return catalog[key] ?? '';
  }

  test('formats a naive UTC timestamp in the device timezone', () {
    final completedAt = DateTime.utc(2026, 11, 5, 8, 30);
    expect(completedAt.isUtc, isTrue);

    expect(
      formatCompletedAt(completedAt, 'en'),
      DateFormat('d MMMM y', 'en').format(completedAt.toLocal()),
    );
    expect(
      formatCompletedAt(completedAt, 'ar'),
      DateFormat('d MMMM y', 'ar').format(completedAt.toLocal()),
    );
    expect(formatCompletedAt(null, 'en'), isNull);
  });

  test('localizes performance status in English and Arabic', () {
    expect(
      performanceStatusLabel(
        PerformanceStatus.excellent,
        (key) => translate(english, key),
      ),
      'Excellent',
    );
    expect(
      performanceStatusLabel(
        PerformanceStatus.average,
        (key) => translate(english, key),
      ),
      'Average',
    );
    expect(
      performanceStatusLabel(
        PerformanceStatus.poor,
        (key) => translate(english, key),
      ),
      'Poor',
    );
    expect(
      performanceStatusLabel(
        PerformanceStatus.excellent,
        (key) => translate(arabic, key),
      ),
      'ممتاز',
    );
    expect(
      performanceStatusLabel(
        PerformanceStatus.average,
        (key) => translate(arabic, key),
      ),
      'متوسط',
    );
    expect(
      performanceStatusLabel(
        PerformanceStatus.poor,
        (key) => translate(arabic, key),
      ),
      'ضعيف',
    );
    expect(
      performanceStatusLabel(null, (key) => translate(english, key)),
      isNull,
    );
  });

  test('uses the mock interview title when the job field is blank', () {
    expect(
      recentInterviewTitle(null, english['performance_mock_interview']!),
      'Mock Interview',
    );
    expect(
      recentInterviewTitle('   ', arabic['performance_mock_interview']!),
      'مقابلة محاكاة',
    );
    expect(
      recentInterviewTitle('برمجة', english['performance_mock_interview']!),
      'برمجة',
    );
  });

  test('keeps a zero score and replaces only a null score', () {
    expect(performanceScoreText(null, '—'), '—');
    expect(performanceScoreText(0, '—'), '0%');
    expect(performanceScoreText(72, '—'), '72%');
    expect(performanceCountText(null, '—'), '—');
    expect(performanceCountText(0, '—'), '0');
    expect(performanceCountText(3, '—'), '3');
  });
}
