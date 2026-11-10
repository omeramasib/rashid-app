const _preferredLocales = <String, List<String>>{
  'ar': ['ar_SA', 'ar_AE', 'ar_EG', 'ar_JO', 'ar_KW', 'ar_QA', 'ar_BH'],
  'en': ['en_US', 'en_GB', 'en_AU', 'en_CA', 'en_IN'],
};

/// Picks a recognizer locale for [languageCode] (`ar` or `en`).
///
/// Order: a preferred regional locale, then any locale of the same language.
///
/// On Android 13 and newer, `speech_to_text` reports only on-device languages.
/// That list often omits Arabic even when the network recognizer supports it,
/// so a missing entry is not treated as proof the language is unavailable.
/// The preferred locale is still returned and the recognizer is allowed to
/// accept or reject it. Returns null only when there is no preferred locale
/// for [languageCode] and none of the reported locales match.
String? resolveSpeechLocale(String languageCode, List<String> available) {
  final language = languageCode.toLowerCase();
  final preferred = _preferredLocales[language] ?? const <String>[];
  if (available.isEmpty) {
    return preferred.isEmpty ? null : preferred.first;
  }
  final normalized = {
    for (final id in available) _normalize(id): id,
  };
  for (final id in preferred) {
    final match = normalized[_normalize(id)];
    if (match != null) return match;
  }
  for (final entry in normalized.entries) {
    if (entry.key == language || entry.key.startsWith('${language}_')) {
      return entry.value;
    }
  }
  return preferred.isEmpty ? null : preferred.first;
}

String _normalize(String id) => id.replaceAll('-', '_').toLowerCase();
