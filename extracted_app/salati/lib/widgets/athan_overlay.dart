import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/prayer_calculator.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../services/athan_service.dart';

/// شاشة أذان كاملة تظهر عند دخول وقت الصلاة
class AthanOverlay extends StatelessWidget {
  final String prayerKey;
  const AthanOverlay({super.key, required this.prayerKey});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    final athan = context.watch<AthanService>();
    final name = s.isArabic
        ? PrayerCalculator.arNames[prayerKey]!
        : PrayerCalculator.enNames[prayerKey]!;

    return Stack(
      children: [
        // خلفية معتمة ضبابية
        BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(color: const Color(0xE6040C11)),
        ),
        Positioned.fill(
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // قوس متوهج
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gold.withOpacity(0.24),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.goldGradient,
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.gold.withOpacity(0.4),
                              blurRadius: 40)
                        ],
                      ),
                      child: const Icon(Icons.mosque,
                          size: 62, color: AppColors.night),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  s.isArabic ? 'حان الآن وقت صلاة' : 'It is time for',
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: const TextStyle(
                      fontFamily: 'AmiriQuran',
                      fontSize: 46,
                      height: 1.3,
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  s.isArabic
                      ? 'الله أكبر الله أكبر — لا إله إلا الله'
                      : 'Allahu Akbar, Allahu Akbar — La ilaha illa Allah',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textPrimary),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    await athan.stop();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: Text(
                    s.isArabic ? 'إغلاق' : 'Dismiss',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
