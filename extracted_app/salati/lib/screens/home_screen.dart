import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/prayer_calculator.dart';
import '../core/settings.dart';
import '../core/cities.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../services/athan_service.dart';
import 'qibla_screen.dart';
import 'quran_screen.dart';
import 'azkar_screen.dart';
import 'tasbih_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import 'mosques_screen.dart';
import 'names_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final athan = context.watch<AthanService>();

    return Ticker(
      builder: (context, now) {
        final times = settings.timesFor(now);
        final next = PrayerCalculator.nextPrayer(times, now);
        final current = PrayerCalculator.currentPrayer(times, now);

        return GradientScaffold(
          child: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _Header(settings: settings, now: now)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: _NextPrayerCard(
                      next: next,
                      now: now,
                      settings: settings,
                      athan: athan,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: _TimesList(times: times, nextKey: next['key'] as String, settings: settings),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _QuickGrid(settings: settings),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _ExtraReminders(settings: settings, current: current),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final SettingsProvider settings;
  final DateTime now;
  const _Header({required this.settings, required this.now});

  @override
  Widget build(BuildContext context) {
    final s = settings;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppLogo(size: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.isArabic ? 'مواقيت الصلاة والأذان' : 'Prayer Times & Athan',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                    Text(
                      '${weekdayName(now, s.isArabic)} • ${hijriDate(now, s.isArabic)}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gold),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                icon: const Icon(Icons.settings_outlined),
                color: AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CitiesScreen())),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x1FFFFFFF),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0x22FFFFFF)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 15, color: AppColors.teal),
                      const SizedBox(width: 5),
                      Text(s.city,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      const Icon(Icons.expand_more,
                          size: 16, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NextPrayerCard extends StatelessWidget {
  final Map<String, dynamic> next;
  final DateTime now;
  final SettingsProvider settings;
  final AthanService athan;

  const _NextPrayerCard({
    required this.next,
    required this.now,
    required this.settings,
    required this.athan,
  });

  @override
  Widget build(BuildContext context) {
    final key = next['key'] as String;
    final time = next['time'] as DateTime;
    final remaining = next['remaining'] as Duration;
    final progress = 1.0 -
        (remaining.inSeconds / (remaining.inSeconds + _elapsedSeconds())).clamp(0.0, 1.0);
    final name = settings.isArabic
        ? PrayerCalculator.arNames[key]!
        : PrayerCalculator.enNames[key]!;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      radius: 26,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF13485A), Color(0xFF0B2735)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppColors.tealGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Color(0x5514C4A6), blurRadius: 16)
                  ],
                ),
                child: Icon(_iconFor(key), color: AppColors.night, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings.isArabic ? 'الصلاة القادمة' : 'Next Prayer',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                    Text(
                      '$name • ${formatTime(time, settings.use24h)}',
                      style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0x2214C4A6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x5514C4A6)),
                ),
                child: Text(
                  settings.isArabic ? 'متبقي' : 'left',
                  style: const TextStyle(fontSize: 11, color: AppColors.teal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          CountdownText(remaining, size: 40),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.isNaN ? 0 : progress,
              minHeight: 6,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(settings.isArabic ? 'من الآن' : 'time remaining',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              if (athan.isPlaying)
                TextButton.icon(
                  onPressed: athan.stop,
                  icon: const Icon(Icons.stop_circle, size: 16, color: AppColors.danger),
                  label: Text(settings.isArabic ? 'إيقاف الأذان' : 'Stop Athan',
                      style: const TextStyle(fontSize: 12, color: AppColors.danger)),
                )
              else
                TextButton.icon(
                  onPressed: () => athan.playAthan(key),
                  icon: const Icon(Icons.volume_up_outlined,
                      size: 16, color: AppColors.gold),
                  label: Text(settings.isArabic ? 'تجربة الأذان' : 'Play Athan',
                      style: const TextStyle(fontSize: 12, color: AppColors.gold)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  int _elapsedSeconds() {
    final times = settings.timesFor(now);
    final current = PrayerCalculator.currentPrayer(times, now);
    final start = times[current];
    if (start == null) return 3600;
    return math.max(60, now.difference(start).inSeconds);
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'fajr':
        return Icons.nights_stay_outlined;
      case 'sunrise':
        return Icons.wb_twilight;
      case 'dhuhr':
        return Icons.wb_sunny_outlined;
      case 'asr':
        return Icons.sunny_snowing;
      case 'maghrib':
        return Icons.wb_twilight_outlined;
      default:
        return Icons.nightlight_outlined;
    }
  }
}

class _TimesList extends StatelessWidget {
  final Map<String, DateTime> times;
  final String nextKey;
  final SettingsProvider settings;
  const _TimesList({required this.times, required this.nextKey, required this.settings});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      radius: 22,
      child: Column(
        children: [
          for (final key in PrayerCalculator.keys)
            _row(key, times[key]!),
        ],
      ),
    );
  }

  Widget _row(String key, DateTime t) {
    final isNext = key == nextKey;
    final name = settings.isArabic
        ? PrayerCalculator.arNames[key]!
        : PrayerCalculator.enNames[key]!;
    final isSunrise = key == 'sunrise';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: isNext ? const Color(0x1F14C4A6) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isNext
            ? Border.all(color: const Color(0x5514C4A6))
            : null,
      ),
      child: Row(
        children: [
          Icon(
            isSunrise ? Icons.wb_twilight : _iconFor(key),
            size: 19,
            color: isNext
                ? AppColors.teal
                : isSunrise
                    ? AppColors.gold
                    : AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
                color: isNext ? AppColors.teal : AppColors.textPrimary,
              ),
            ),
          ),
          if (isSunrise)
            Padding(
              padding: const EdgeInsets.only(right: 8, left: 8),
              child: Text(settings.isArabic ? 'شروق' : 'rise',
                  style:
                      const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ),
          Text(
            formatTime(t, settings.use24h),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isNext ? AppColors.teal : AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 6),
          if (isNext)
            const Icon(Icons.notifications_active,
                size: 15, color: AppColors.gold)
          else
            const SizedBox(width: 15),
        ],
      ),
    );
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'fajr':
        return Icons.nights_stay_outlined;
      case 'dhuhr':
        return Icons.wb_sunny_outlined;
      case 'asr':
        return Icons.sunny_snowing;
      case 'maghrib':
        return Icons.wb_twilight_outlined;
      default:
        return Icons.nightlight_outlined;
    }
  }
}

class _QuickGrid extends StatelessWidget {
  final SettingsProvider settings;
  const _QuickGrid({required this.settings});

  @override
  Widget build(BuildContext context) {
    final items = [
      _QItem(Icons.explore_outlined, settings.isArabic ? 'القبلة' : 'Qibla',
          const Color(0xFF14C4A6), () => _push(context, const QiblaScreen())),
      _QItem(Icons.menu_book_outlined, settings.isArabic ? 'القرآن' : 'Quran',
          const Color(0xFFE7C173), () => _push(context, const QuranScreen())),
      _QItem(Icons.auto_stories_outlined, settings.isArabic ? 'الأذكار' : 'Azkar',
          const Color(0xFF7FA8FF), () => _push(context, const AzkarScreen())),
      _QItem(Icons.timer_outlined, settings.isArabic ? 'السبحة' : 'Tasbih',
          const Color(0xFFF49AC1), () => _push(context, const TasbihScreen())),
      _QItem(Icons.calendar_month_outlined, settings.isArabic ? 'التقويم' : 'Calendar',
          const Color(0xFF9BE86B), () => _push(context, const CalendarScreen())),
      _QItem(Icons.mosque_outlined, settings.isArabic ? 'مساجد' : 'Mosques',
          const Color(0xFFFFB86B), () => _push(context, const MosquesScreen())),
      _QItem(Icons.auto_awesome_outlined, settings.isArabic ? 'أسماء الله' : '99 Names',
          const Color(0xFFB79CFF), () => _push(context, const NamesScreen())),
      _QItem(Icons.notifications_none, settings.isArabic ? 'الأذان' : 'Athan',
          const Color(0xFF6BE8E0), () => _push(context, const SettingsScreen())),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.82,
      children: [
        for (final it in items)
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: it.onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0x12FFFFFF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0x1AFFFFFF)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: it.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(it.icon, color: it.color, size: 21),
                    ),
                    const SizedBox(height: 7),
                    Text(it.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _push(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}

class _QItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  _QItem(this.icon, this.label, this.color, this.onTap);
}

class _ExtraReminders extends StatelessWidget {
  final SettingsProvider settings;
  final String current;
  const _ExtraReminders({required this.settings, required this.current});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isFriday = now.weekday == DateTime.friday;
    final reminders = <(IconData, String, String)>[
      (
        Icons.wb_sunny_outlined,
        settings.isArabic ? 'قيام الليل' : 'Qiyam Al-Layl',
        settings.isArabic ? 'بعد صلاة العشاء' : 'after Isha'
      ),
      (
        Icons.nightlight_outlined,
        settings.isArabic ? 'صيام الأيام البيض' : 'Fasting White Days',
        settings.isArabic ? '١٣ و١٤ و١٥ من الهجري' : '13, 14, 15 Hijri'
      ),
      (
        Icons.event_repeat_outlined,
        settings.isArabic ? 'صيام الاثنين والخميس' : 'Mon & Thu Fasting',
        isFriday && settings.isArabic ? 'غدًا الخميس' : (settings.isArabic ? 'سنة نبوية' : 'Sunnah')
      ),
      (
        Icons.menu_book_outlined,
        settings.isArabic ? 'الورد القرآني' : 'Quranic Werd',
        settings.isArabic ? 'اقرأ صفحتين' : 'Read 2 pages'
      ),
      if (isFriday)
        (
          Icons.auto_stories,
          settings.isArabic ? 'سورة الكهف' : 'Surah Al-Kahf',
          settings.isArabic ? 'اليوم جمعة' : 'It is Friday'
        ),
    ];

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            settings.isArabic ? 'تذكيرات إسلامية' : 'Islamic Reminders',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          for (final r in reminders)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Icon(r.$1, size: 18, color: AppColors.gold),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(r.$2,
                          style: const TextStyle(fontSize: 13))),
                  Text(r.$3,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class CitiesScreen extends StatefulWidget {
  const CitiesScreen({super.key});

  @override
  State<CitiesScreen> createState() => _CitiesScreenState();
}

class _CitiesScreenState extends State<CitiesScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final s = context.read<SettingsProvider>();
    final list = citiesList(s.isArabic).where((c) {
      if (query.isEmpty) return true;
      final q = query.toLowerCase();
      return c.ar.toLowerCase().contains(q) ||
          c.en.toLowerCase().contains(q) ||
          c.countryAr.contains(q) ||
          c.countryEn.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      body: GradientScaffold(
        child: SafeArea(
          child: Column(
            children: [
              AppBar(title: Text(s.isArabic ? 'اختيار المدينة' : 'Choose City')),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) => setState(() => query = v),
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: s.isArabic ? 'ابحث عن مدينة...' : 'Search city...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
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
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final c = list[i];
                    final isSelected = c.lat == s.latitude && c.lng == s.longitude;
                    return Card(
                      color: isSelected ? const Color(0x1F14C4A6) : const Color(0x12FFFFFF),
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        onTap: () {
                          s.setCity(
                              ar: c.ar,
                              en: c.en,
                              lat: c.lat,
                              lng: c.lng,
                              gps: false);
                          Navigator.pop(context);
                        },
                        leading: const Icon(Icons.location_city, color: AppColors.teal),
                        title: Text(s.isArabic ? c.ar : c.en,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text(s.isArabic ? c.countryAr : c.countryEn,
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: AppColors.teal, size: 20)
                            : null,
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

List<City> citiesList(bool isArabic) => cities;
