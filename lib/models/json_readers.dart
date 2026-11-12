/// Strict JSON readers shared by the models.
///
/// They accept numbers sent as JSON numbers or numeric strings, and throw a
/// [FormatException] naming the field when a value is missing or malformed.
/// The API layer turns that into a user-facing parse failure.
library;

double readDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException('Expected a number for "$key"', value);
}

/// Like [readDouble], but returns null when the field is absent or invalid.
/// Used for partial updates, where every field is optional.
double? readDoubleOrNull(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int readInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException('Expected an integer for "$key"', value);
}

String readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException('Expected a string for "$key"', value);
}

DateTime readDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException('Expected an ISO 8601 date for "$key"', value);
}

Map<String, dynamic> readMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is Map<String, dynamic>) return value;
  throw FormatException('Expected an object for "$key"', value);
}

List<Map<String, dynamic>> readList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is List) {
    return [
      for (final item in value)
        if (item is Map<String, dynamic>)
          item
        else
          throw FormatException('Expected objects in "$key"', item),
    ];
  }
  throw FormatException('Expected a list for "$key"', value);
}
