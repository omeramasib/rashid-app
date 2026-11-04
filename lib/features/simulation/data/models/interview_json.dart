int? optionalInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}

String? optionalString(dynamic value) {
  if (value is! String) return null;
  return value;
}

String requiredString(dynamic value) => value is String ? value : '';

bool flag(dynamic value, {bool fallback = false}) {
  return value is bool ? value : fallback;
}

List<String>? optionalStringList(dynamic value) {
  if (value == null) return null;
  if (value is! List) return null;
  return value.whereType<String>().toList();
}
