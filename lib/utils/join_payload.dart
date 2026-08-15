import 'dart:convert';

/// Parses a pasted invite code: a raw group id, or the QR JSON payload.
Map<String, dynamic>? parseJoinPayload(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.startsWith("{")) {
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);
        final id = map["Id"] ?? map["id"];
        if (id is String && id.trim().isNotEmpty) {
          map["Id"] = id.trim();
          return map;
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }
  return {"Id": trimmed};
}
