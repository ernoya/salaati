import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/prayer_calculator.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime month;
  DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    month = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    _today = DateTime.now();
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday; // 1 = Mon

    return Scaffold(
      body: GradientScaffold(
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                  title: Text(s.isArabic
                      ? 'التقويم ومواقيت الشهر'
                      : 'Calendar & Monthly Times')),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(() =>
                          month = DateTime(month.year, month.month - 1)),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            gregorianDate(month, s.isArabic),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          Text(hijriDate(month, s.isArabic),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.gold)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => setState(() =>
                          month = DateTime(month.year, month.month + 1)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    for (final d in (s.isArabic
                        ? ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح']
                        : ['M', 'T', 'W', 'T', 'F', 'S', 'S']))
                      Expanded(
                        child: Center(
                          child: Text(d,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: firstWeekday - 1 + daysInMonth,
                  itemBuilder: (context, index) {
                    if (index < firstWeekday - 1) return const SizedBox();
                    final day = index - (firstWeekday - 1) + 1;
                    final d = DateTime(month.year, month.month, day);
                    final isToday = _today.day == d.day &&
                        _today.month == d.month &&
                        _today.year == d.year;
                    final isFriday = d.weekday == DateTime.friday;
                    final times = s.timesFor(d);
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showDayDetails(context, s, d, times),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppColors.teal.withOpacity(0.18)
                              : isFriday
                                  ? AppColors.gold.withOpacity(0.10)
                                  : const Color(0x10FFFFFF),
                          borderRadius: BorderRadius.circular(12),
                          border: isToday
                              ? Border.all(color: AppColors.teal)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    isToday ? FontWeight.w700 : FontWeight.w500,
                                color: isToday
                                    ? AppColors.teal
                                    : isFriday
                                        ? AppColors.gold
                                        : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _hijriDay(d),
                              style: const TextStyle(
                                  fontSize: 8.5, color: AppColors.textMuted),
                            ),
                          ],
                        ),
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

  String _hijriDay(DateTime d) {
    final h = hijriDate(d, true);
    return h.split(' ').first.replaceAll('هـ', '');
  }

  void _showDayDetails(BuildContext context, SettingsProvider s, DateTime d,
      Map<String, DateTime> times) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 16),
              Text(gregorianDate(d, s.isArabic),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              Text(hijriDate(d, s.isArabic),
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.gold)),
              const SizedBox(height: 14),
              for (final key in PrayerCalculator.keys)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                          key == 'sunrise'
                              ? Icons.wb_twilight
                              : Icons.access_time,
                          size: 16,
                          color: AppColors.textMuted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.isArabic
                              ? PrayerCalculator.arNames[key]!
                              : PrayerCalculator.enNames[key]!,
                          style: const TextStyle(fontSize: 13.5),
                        ),
                      ),
                      Text(formatTime(times[key]!, s.use24h),
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w600)),
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
