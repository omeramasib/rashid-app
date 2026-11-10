/// Adds [addition] after [existing] with a single separating space.
///
/// An empty or blank [addition] returns [existing] unchanged.
String appendTranscript(String existing, String addition) {
  final text = addition.trim();
  if (text.isEmpty) return existing;
  if (existing.isEmpty || existing.trimRight().length != existing.length) {
    return '$existing$text';
  }
  return '$existing $text';
}
