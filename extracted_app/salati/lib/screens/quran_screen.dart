import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../data/quran_service.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  List<Surah>? _surahs;
  String _query = '';
  List<({Surah surah, int ayah, String text})> _results = const [];

  @override
  void initState() {
    super.initState();
    QuranService.load().then((v) {
      if (mounted) setState(() => _surahs = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    return Scaffold(
      body: GradientScaffold(
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: Text(s.isArabic ? 'القرآن الكريم' : 'Holy Quran'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.bookmark_border),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const BookmarksScreen())),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) {
                    setState(() {
                      _query = v;
                      _results = v.length > 1 ? QuranService.search(v) : const [];
                    });
                  },
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: s.isArabic
                        ? 'ابحث في آيات القرآن...'
                        : 'Search the Quran...',
                    hintStyle:
                        const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.textMuted),
                    filled: true,
                    fillColor: const Color(0x14FFFFFF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _surahs == null
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.gold))
                    : _query.length > 1
                        ? _buildSearch(s)
                        : _buildList(s),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearch(SettingsProvider s) {
    if (_results.isEmpty) {
      return Center(
        child: Text(s.isArabic ? 'لا توجد نتائج' : 'No results',
            style: const TextStyle(color: AppColors.textMuted)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final r = _results[i];
        return GlassCard(
          padding: const EdgeInsets.all(14),
          radius: 16,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => SurahReader(
                    surah: r.surah, initialAyah: r.ayah, highlight: true)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${r.surah.name} • ${r.ayah}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.gold)),
              const SizedBox(height: 6),
              Text(r.text,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                      fontFamily: 'AmiriQuran', fontSize: 19, height: 1.9)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(SettingsProvider s) {
    final list = _surahs!;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final surah = list[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: const Color(0x10FFFFFF),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => SurahReader(surah: surah))),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text('${surah.number}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(surah.name,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                  fontFamily: 'AmiriQuran',
                                  fontSize: 19,
                                  height: 1.4,
                                  fontWeight: FontWeight.w700)),
                          Text(
                            '${surah.translation} • ${surah.ayahCount} ${s.isArabic ? "آية" : "ayahs"} • ${s.isArabic ? (surah.isMeccan ? "مكية" : "مدنية") : surah.type}',
                            style: const TextStyle(
                                fontSize: 10.5, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_left,
                        size: 18, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SurahReader extends StatefulWidget {
  final Surah surah;
  final int initialAyah;
  final bool highlight;
  const SurahReader(
      {super.key,
      required this.surah,
      this.initialAyah = 1,
      this.highlight = false});

  @override
  State<SurahReader> createState() => _SurahReaderState();
}

class _SurahReaderState extends State<SurahReader> {
  late final ScrollController _controller = ScrollController();
  double fontSize = 25;
  bool showEnglish = false;
  List<int> bookmarks = [];

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getStringList('pn_bookmarks') ?? [];
    setState(() => bookmarks = v
        .map((e) => int.tryParse(e.split(':').last) ?? 0)
        .toList());
  }

  Future<void> _toggleBookmark(int ayah) async {
    final p = await SharedPreferences.getInstance();
    final v = p.getStringList('pn_bookmarks') ?? [];
    final key = '${widget.surah.number}:$ayah';
    if (v.contains(key)) {
      v.remove(key);
    } else {
      v.add(key);
    }
    await p.setStringList('pn_bookmarks', v);
    _loadBookmarks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            v.contains(key) ? 'تمت إضافة العلامة' : 'تم حذف العلامة',
            style: const TextStyle(fontFamily: 'Cairo')),
        duration: const Duration(seconds: 1),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    final surah = widget.surah;

    return Scaffold(
      body: GradientScaffold(
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: Text(surah.name,
                    style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 22)),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.text_fields, size: 20),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      builder: (ctx) => StatefulBuilder(
                        builder: (ctx, setSt) => Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(s.isArabic ? 'حجم الخط' : 'Font size',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              Slider(
                                value: fontSize,
                                min: 18,
                                max: 42,
                                activeColor: AppColors.gold,
                                onChanged: (v) {
                                  setSt(() => fontSize = v);
                                  setState(() {});
                                },
                              ),
                              SwitchListTile(
                                value: showEnglish,
                                activeColor: AppColors.teal,
                                title: Text(
                                    s.isArabic
                                        ? 'إظهار الترجمة الإنجليزية'
                                        : 'Show English translation',
                                    style: const TextStyle(fontSize: 13)),
                                onChanged: (v) {
                                  setSt(() => showEnglish = v);
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  controller: _controller,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                  itemCount: surah.ayahs.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) return _basmala(s);
                    final ayahNo = i;
                    final isHighlight = widget.highlight &&
                        ayahNo == widget.initialAyah;
                    final marked = bookmarks.contains(ayahNo);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isHighlight
                            ? AppColors.gold.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: isHighlight
                            ? Border.all(
                                color: AppColors.gold.withOpacity(0.5))
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.teal.withOpacity(0.14),
                                  border: Border.all(
                                      color:
                                          AppColors.teal.withOpacity(0.4)),
                                ),
                                child: Text('$ayahNo',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.teal,
                                        fontWeight: FontWeight.w700)),
                              ),
                              const Spacer(),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                    marked
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    size: 18,
                                    color: marked
                                        ? AppColors.gold
                                        : AppColors.textMuted),
                                onPressed: () => _toggleBookmark(ayahNo),
                              ),
                            ],
                          ),
                          Text(
                            surah.ayahs[i - 1],
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'AmiriQuran',
                              fontSize: fontSize,
                              height: 2.0,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (showEnglish) ...[
                            const SizedBox(height: 8),
                            Text(
                              surah.enAyahs[i - 1],
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  height: 1.5,
                                  color: AppColors.textMuted),
                            ),
                          ],
                          const Divider(color: Color(0x11FFFFFF), height: 18),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _basmala(SettingsProvider s) {
    if (widget.surah.number == 1 || widget.surah.number == 9) {
      return const SizedBox(height: 4);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: TextStyle(
            fontFamily: 'AmiriQuran', fontSize: fontSize + 2, color: AppColors.gold),
      ),
    );
  }
}

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<String> items = [];

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      setState(() => items = p.getStringList('pn_bookmarks') ?? []);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    return Scaffold(
      body: GradientScaffold(
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                  title:
                      Text(s.isArabic ? 'العلامات المرجعية' : 'Bookmarks')),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                            s.isArabic
                                ? 'لا توجد علامات بعد'
                                : 'No bookmarks yet',
                            style:
                                const TextStyle(color: AppColors.textMuted)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final parts = items[i].split(':');
                          final sn = int.tryParse(parts.first) ?? 1;
                          final an = int.tryParse(parts.last) ?? 1;
                          final surah = QuranService.loaded.isEmpty
                              ? null
                              : QuranService.loaded[sn - 1];
                          return Card(
                            color: const Color(0x12FFFFFF),
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              onTap: surah == null
                                  ? null
                                  : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => SurahReader(
                                              surah: surah,
                                              initialAyah: an,
                                              highlight: true))),
                              leading: const Icon(Icons.bookmark,
                                  color: AppColors.gold),
                              title: Text(
                                  '${surah?.name ?? ""} — ${s.isArabic ? "آية" : "Ayah"} $an',
                                  style: const TextStyle(
                                      fontFamily: 'AmiriQuran', fontSize: 17)),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
