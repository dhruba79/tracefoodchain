dynamic sortJsonAlphabetically(dynamic json) {
  // Primitive type or null
  if (json == null || (json is! Map && json is! List)) {
    return json;
  }

  // Array
  if (json is List) {
    return json.map((item) => sortJsonAlphabetically(item)).toList();
  }

  // Object
  Map<String, dynamic> sortedMap = Map.fromEntries((json as Map<String, dynamic>).entries.toList()..sort((a, b) => a.key.compareTo(b.key)));

  return Map.fromEntries(
    sortedMap.entries.map(
      (entry) => MapEntry(entry.key, sortJsonAlphabetically(entry.value)),
    ),
  );
}
