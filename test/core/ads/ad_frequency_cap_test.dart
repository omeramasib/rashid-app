import 'package:flutter_test/flutter_test.dart';
import 'package:rashed_app/core/ads/ad_frequency_cap.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('allows an impression until the cooldown has elapsed', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    var now = DateTime(2026, 1, 1, 12);
    final cap = AdFrequencyCap(
      preferences: preferences,
      cooldown: const Duration(minutes: 5),
      now: () => now,
    );

    expect(cap.canShow(), isTrue);
    await cap.recordImpression();
    expect(preferences.getInt(AdFrequencyCap.storageKey), isNotNull);
    expect(cap.canShow(), isFalse);

    now = now.add(const Duration(minutes: 4, seconds: 59));
    expect(cap.canShow(), isFalse);
    now = now.add(const Duration(seconds: 1));
    expect(cap.canShow(), isTrue);
  });
}
