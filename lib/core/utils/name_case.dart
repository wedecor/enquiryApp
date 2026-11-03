/// Tidies a person's name for saving: trims, collapses spaces, and capitalises
/// words typed entirely in small letters ("priya sharma" → "Priya Sharma").
///
/// Words that already contain a capital are left exactly as typed, so
/// "McKenzie", "ABC Events" or "D'Souza" are never changed.
String tidyPersonName(String raw) {
  final words = raw.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  return words.map(_capitaliseIfAllLower).join(' ');
}

String _capitaliseIfAllLower(String word) {
  if (word != word.toLowerCase()) return word; // has a capital already
  return word[0].toUpperCase() + word.substring(1);
}
