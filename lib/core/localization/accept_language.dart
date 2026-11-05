/// Builds API `Accept-Language` header values from app locale codes.
class AcceptLanguage {
  AcceptLanguage._();

  /// Returns `ar` or `en` for supported app languages.
  static String forLanguageCode(String languageCode) {
    return languageCode == 'ar' ? 'ar' : 'en';
  }
}
