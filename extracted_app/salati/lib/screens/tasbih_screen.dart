import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

const List<({String ar, String en, int target})> tasbihPhrases = [
  (ar: 'سُبْحَانَ اللَّهِ', en: 'Subhan Allah', target: 33),
  (ar: 'الْحَمْدُ لِلَّهِ', en: 'Alhamdulillah', target: 33),
  (ar: 'اللَّهُ أَكْبَرُ', en: 'Allahu Akbar', target: 34),
  (ar: 'لَا إِلَهَ إِلَّا اللَّهُ', en: 'La ilaha illa Allah', target: 100),
  (ar: 'أَسْتَغْفِرُ اللَّهَ', en: 'Astaghfirullah', target: 100),
  (ar: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ', en: 'Subhan Allahi wa bihamdih', target: 100),
  (ar: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ', en: 'La hawla wa la quwwata illa billah', target: 100),
  (ar: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ', en: 'Salawat on the Prophet', target: 100),
];

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  int count = 0;
  int total = 0;
  int phraseIndex = 0;
  bool haptic = true;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      setState(() {
        count = p.getInt('pn_tasbih_count') ?? 0;
        total = p.getInt('pn_tasbih_total') ?? 0;
        phraseIndex = p.getInt('pn_tasbih_phrase') ?? 0;
      });
    });
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('pn_tasbih_count', count);
    await p.setInt('pn_tasbih_total', total);
    await p.setInt('pn_tasbih_phrase', phraseIndex);
  }

  void _increment() {
    final target = tasbihPhrases[phraseIndex].target;
    setState(() {
      count++;
      total++;
      if (count >= target) {
        count = 0;
        if (haptic) HapticFeedback.heavyImpact();
        _flash.value = 1.0;
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) _flash.value = 0.0;
        });
      } else {
        if (haptic) HapticFeedback.selectionClick();
      }
    });
    _persist();
  }

  final ValueNotifier<double> _flash = ValueNotifier(0);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    final phrase = tasbihPhrases[phraseIndex];
    final progress = count / phrase.target;

    return Scaffold(
      body: GradientScaffold(
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: Text(s.isArabic ? 'السبحة الإلكترونية' : 'Digital Tasbih'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: () => setState(() {
                      count = 0;
                      _persist();
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < tasbihPhrases.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Pill(
                            s.isArabic
                                ? tasbihPhrases[i].ar
                                : tasbihPhrases[i].en,
                            filled: i == phraseIndex,
                            color: i == phraseIndex
                                ? AppColors.teal
                                : AppColors.textMuted,
                            onTap: () {
                              setState(() {
                                phraseIndex = i;
                                count = 0;
                              });
                              _persist();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: _increment,
                    child: SizedBox(
                      width: 270,
                      height: 270,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ValueListenableBuilder<double>(
                            valueListenable: _flash,
                            builder: (context, flashVal, child) {
                              if (flashVal > 0) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 285,
                                  height: 285,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.gold.withOpacity(0.9),
                                      width: 3.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.gold.withOpacity(0.6),
                                        blurRadius: 30,
                                        spreadRadius: 8,
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          SizedBox(
                            width: 270,
                            height: 270,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: progress),
                              duration: const Duration(milliseconds: 220),
                              builder: (context, value, _) =>
                                  CircularProgressIndicator(
                                value: value,
                                strokeWidth: 10,
                                backgroundColor: const Color(0x1AFFFFFF),
                                valueColor: const AlwaysStoppedAnimation(
                                    AppColors.gold),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                          ),
                          Container(
                            width: 214,
                            height: 214,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF17475A), Color(0xFF0A2030)],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0x66000000),
                                    blurRadius: 24,
                                    offset: Offset(0, 10)),
                              ],
                              border: Border.all(
                                  color: const Color(0x22FFFFFF), width: 1.5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  s.isArabic ? phrase.ar : phrase.en,
                                  textAlign: TextAlign.center,
                                  textDirection: s.isArabic
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                  style: TextStyle(
                                    fontFamily:
                                        s.isArabic ? 'AmiriQuran' : 'Cairo',
                                    fontSize: s.isArabic ? 24 : 17,
                                    fontWeight: FontWeight.w700,
                                    height: 1.7,
                                    color: AppColors.gold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '$count',
                                  style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 52,
                                      fontWeight: FontWeight.w700,
                                      height: 1.0),
                                ),
                                Text(
                                  '/ ${phrase.target}',
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _action(
                      Icons.undo,
                      s.isArabic ? 'تراجع' : 'Undo',
                      () => setState(() {
                            if (count > 0) count--;
                            if (total > 0) total--;
                            _persist();
                          })),
                  const SizedBox(width: 26),
                  _action(
                      Icons.vibration,
                      s.isArabic ? 'اهتزاز' : 'Vibrate',
                      () => setState(() => haptic = !haptic),
                      active: haptic),
                  const SizedBox(width: 26),
                  _action(
                      Icons.restart_alt,
                      s.isArabic ? 'تصفير' : 'Reset',
                      () => setState(() {
                            count = 0;
                            total = 0;
                            _persist();
                          })),
                ],
              ),
              const SizedBox(height: 14),
              GlassCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                radius: 18,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.legend_toggle,
                        size: 16, color: AppColors.teal),
                    const SizedBox(width: 8),
                    Text(
                      s.isArabic
                          ? 'إجمالي التسبيحات: $total'
                          : 'Total tasbih: $total',
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                s.isArabic ? 'اضغط الدائرة للتسبيح' : 'Tap the circle to count',
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap,
      {bool active = true}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: active ? const Color(0x1AFFFFFF) : const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: active ? const Color(0x33FFFFFF) : Colors.transparent),
            ),
            child: Icon(icon,
                size: 20,
                color: active ? AppColors.textPrimary : AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(label,
              style:
                  const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class MathHelper {
  static double deg2rad(double d) => d * math.pi / 180;
}
