import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Surah {
  final int number;
  final String name;
  final String englishName;
  final String translation;
  final String type; // Meccan | Medinan
  final List<String> ayahs;
  final List<String> enAyahs;

  const Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.translation,
    required this.type,
    required this.ayahs,
    required this.enAyahs,
  });

  bool get isMeccan => type == 'Meccan';
  int get ayahCount => ayahs.length;
}

/// تحميل نص القرآن الكريم كاملًا من الأصول المحلية (بدون إنترنت)
class QuranService {
  static List<Surah>? _cache;

  static Future<List<Surah>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/quran.json');
    final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
    final list = <Surah>[];
    for (final s in (data['surahs'] as List)) {
      final m = s as Map<String, dynamic>;
      list.add(Surah(
        number: m['n'] as int,
        name: m['name'] as String,
        englishName: m['en'] as String,
        translation: m['t'] as String,
        type: m['type'] as String,
        ayahs: (m['ayahs'] as List).cast<String>(),
        enAyahs: (m['enAyahs'] as List).cast<String>(),
      ));
    }
    _cache = list;
    return list;
  }

  static List<Surah> get loaded => _cache ?? const [];

  /// بحث في الآيات — يرجع (سورة، رقم آية، نص)
  static List<({Surah surah, int ayah, String text})> search(String query) {
    final q = _normalize(query);
    if (q.length < 2) return const [];
    final out = <({Surah surah, int ayah, String text})>[];
    for (final s in loaded) {
      for (var i = 0; i < s.ayahs.length; i++) {
        if (_normalize(s.ayahs[i]).contains(q)) {
          out.add((surah: s, ayah: i + 1, text: s.ayahs[i]));
          if (out.length > 300) return out;
        }
      }
    }
    return out;
  }

  static String _normalize(String s) => s
      .replaceAll(RegExp(r'[\u064B-\u0652\u0670\u0640]'), '')
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .trim();
}
