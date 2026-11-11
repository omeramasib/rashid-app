import 'package:flutter_test/flutter_test.dart';
import 'package:rashed_app/core/speech/append_transcript.dart';
import 'package:rashed_app/core/speech/speech_locale_resolver.dart';
import 'package:rashed_app/core/speech/speech_recognition_service.dart';
import 'package:rashed_app/core/speech/speech_to_text_service.dart';

void main() {
  group('appendTranscript', () {
    test('appends after typed text with one space', () {
      expect(
        appendTranscript(
          'I have five years of Flutter experience.',
          'I worked on several production mobile applications.',
        ),
        'I have five years of Flutter experience. '
        'I worked on several production mobile applications.',
      );
    });

    test('uses the transcript as-is when the answer is empty', () {
      expect(appendTranscript('', '  hello  '), 'hello');
    });

    test('does not add a second space after trailing whitespace', () {
      expect(appendTranscript('first\n', 'second'), 'first\nsecond');
    });

    test('blank transcript leaves the answer unchanged', () {
      expect(appendTranscript('keep me', '   '), 'keep me');
      expect(appendTranscript('keep me', ''), 'keep me');
    });

    test('keeps Arabic text and punctuation from the platform', () {
      expect(appendTranscript('مرحبا،', 'أنا مطور.'), 'مرحبا، أنا مطور.');
    });
  });

  group('resolveSpeechLocale', () {
    test('prefers a known regional locale', () {
      expect(resolveSpeechLocale('ar', ['en_US', 'ar_EG', 'ar_SA']), 'ar_SA');
      expect(resolveSpeechLocale('en', ['ar_SA', 'en_GB', 'en_US']), 'en_US');
    });

    test('accepts dash ids and returns the original id', () {
      expect(resolveSpeechLocale('ar', ['ar-SA']), 'ar-SA');
    });

    test('falls back to any locale of the same language', () {
      expect(resolveSpeechLocale('ar', ['en_US', 'ar_MA']), 'ar_MA');
      expect(resolveSpeechLocale('en', ['en_NZ']), 'en_NZ');
    });

    test('uses the preferred locale when the reported list omits the language',
        () {
      // Android 13+ reports on-device languages only, so Arabic can be
      // missing from a list that still has a working network recognizer.
      expect(resolveSpeechLocale('ar', ['en_US', 'fr_FR']), 'ar_SA');
      expect(resolveSpeechLocale('en', ['ar_EG']), 'en_US');
    });

    test('returns null when the language has no preferred locale and no match',
        () {
      expect(resolveSpeechLocale('fr', ['en_US']), isNull);
    });

    test('tries the default locale when the device lists none', () {
      expect(resolveSpeechLocale('ar', const []), 'ar_SA');
      expect(resolveSpeechLocale('en', const []), 'en_US');
    });
  });

  test('plugin error codes map to sanitized categories', () {
    expect(
        categorizeSpeechError('error_no_match'), SpeechErrorCategory.noSpeech);
    expect(
      categorizeSpeechError('error_speech_timeout'),
      SpeechErrorCategory.noSpeech,
    );
    expect(
      categorizeSpeechError('error_network_timeout'),
      SpeechErrorCategory.network,
    );
    expect(
      categorizeSpeechError('error_language_unavailable'),
      SpeechErrorCategory.languageUnavailable,
    );
    expect(categorizeSpeechError('error_busy'), SpeechErrorCategory.busy);
    expect(
      categorizeSpeechError('error_unknown (42)'),
      SpeechErrorCategory.unknown,
    );
  });
}
