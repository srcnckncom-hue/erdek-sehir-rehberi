/// Türkçe'ye uygun basit arama yardımcıları.
///
/// "İskele", "iskele", "ISKELE" ve "iskele" (ı/i farkı) aynı sonucu verir;
/// "ş, ğ, ü, ö, ç" harfleri de yok sayılır ("balikli" → "Balıklı").
abstract final class TextSearch {
  static const _fold = {
    'ı': 'i',
    'ş': 's',
    'ğ': 'g',
    'ü': 'u',
    'ö': 'o',
    'ç': 'c',
    'â': 'a',
    'î': 'i',
    'û': 'u',
  };

  static String normalize(String input) {
    // Türkçe büyük harf kuralı: İ → i, I → ı (sonra ı → i)
    final lower = input.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(_fold[ch] ?? ch);
    }
    return buffer.toString();
  }

  /// Sorgudaki her kelime metinlerden birinde geçiyorsa eşleşir.
  static bool matches(String query, Iterable<String?> fields) {
    final tokens = normalize(query).split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return false;
    final haystack = normalize(fields.whereType<String>().join(' '));
    return tokens.every(haystack.contains);
  }
}
