import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../data/azkar_data.dart';

class AzkarScreen extends StatelessWidget {
  const AzkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    return Scaffold(
      body: GradientScaffold(
        child: SafeArea(
          child: Column(
            children: [
              AppBar(title: Text(s.isArabic ? 'الأذكار والأدعية' : 'Azkar & Duas')),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    const SectionTitle('الأذكار اليومية / Daily Azkar'),
                    for (final c in azkarCategories)
                      _CategoryCard(
                        emoji: c.emoji,
                        title: s.isArabic ? c.titleAr : c.titleEn,
                        subtitle: '${c.items.length} ${s.isArabic ? "ذكر" : "items"}',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => AzkarDetail(category: c))),
                      ),
                    const SizedBox(height: 10),
                    const SectionTitle('أدعية مأثورة / Duas'),
                    for (final d in duas)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          radius: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.favorite_border,
                                      size: 15, color: AppColors.gold),
                                  const SizedBox(width: 8),
                                  Text(s.isArabic ? d.titleAr : d.titleEn,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.gold)),
                                  const Spacer(),
                                  if (d.source.isNotEmpty)
                                    Text(d.source,
                                        style: const TextStyle(
                                            fontSize: 9.5,
                                            color: AppColors.textMuted)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(d.text,
                                  textDirection: TextDirection.rtl,
                                  style: const TextStyle(
                                      fontFamily: 'AmiriQuran',
                                      fontSize: 18,
                                      height: 1.9)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _CategoryCard(
      {required this.emoji,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        radius: 16,
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0x14FFFFFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_left, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class AzkarDetail extends StatefulWidget {
  final ZikrCategory category;
  const AzkarDetail({super.key, required this.category});

  @override
  State<AzkarDetail> createState() => _AzkarDetailState();
}

class _AzkarDetailState extends State<AzkarDetail> {
  final Map<int, int> counts = {};

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    return Scaffold(
      body: GradientScaffold(
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                  title: Text(s.isArabic
                      ? widget.category.titleAr
                      : widget.category.titleEn)),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: widget.category.items.length,
                  itemBuilder: (context, i) {
                    final z = widget.category.items[i];
                    final done = counts[i] ?? 0;
                    final finished = done >= z.repeat;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: finished
                            ? const Color(0x1F14C4A6)
                            : const Color(0x12FFFFFF),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: finished
                                ? const Color(0x5514C4A6)
                                : const Color(0x1AFFFFFF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(z.text,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                  fontFamily: 'AmiriQuran',
                                  fontSize: 19,
                                  height: 2.0)),
                          if (z.virtue.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.star_border,
                                    size: 13, color: AppColors.gold),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(z.virtue,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.gold)),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (z.source.isNotEmpty)
                                Text(z.source,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMuted)),
                              const Spacer(),
                              Material(
                                color: finished
                                    ? AppColors.teal.withOpacity(0.15)
                                    : AppColors.gold.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => setState(() {
                                    counts[i] = finished ? 0 : done + 1;
                                  }),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 7),
                                    child: Row(
                                      children: [
                                        Icon(
                                            finished
                                                ? Icons.check_circle
                                                : Icons.touch_app_outlined,
                                            size: 15,
                                            color: finished
                                                ? AppColors.teal
                                                : AppColors.gold),
                                        const SizedBox(width: 6),
                                        Text(
                                          '$done / ${z.repeat}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: finished
                                                  ? AppColors.teal
                                                  : AppColors.gold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
}
