import 'dart:convert';

import 'package:flutter/services.dart';

/// Loads a bundled grocery staples list and suggests matches for autocomplete.
class GroceryCatalog {
  static const String assetPath = 'assets/grocery_catalog.json';
  static const int maxSuggestions = 10;

  List<String> _items = const [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;
    _items = decoded.cast<String>();
    _loaded = true;
  }

  /// Returns up to [maxSuggestions] matches for [query].
  /// History matches are ranked first, then catalog; each bucket is alphabetical.
  /// Empty query yields no suggestions.
  List<String> suggest(String query, {List<String> history = const []}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final seen = <String>{};
    final historyMatches = <String>[];
    final catalogMatches = <String>[];

    for (final name in history) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) continue;
      final key = trimmed.toLowerCase();
      if (seen.contains(key)) continue;
      if (!key.contains(q)) continue;
      seen.add(key);
      historyMatches.add(trimmed);
    }

    for (final name in _items) {
      final key = name.toLowerCase();
      if (seen.contains(key)) continue;
      if (!key.contains(q)) continue;
      seen.add(key);
      catalogMatches.add(name);
    }

    historyMatches.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    catalogMatches.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return [...historyMatches, ...catalogMatches].take(maxSuggestions).toList();
  }
}
