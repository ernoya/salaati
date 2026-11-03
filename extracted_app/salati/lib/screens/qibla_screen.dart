import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:provider/provider.dart';
import '../core/prayer_calculator.dart';
import '../core/settings.dart';
import '../core/theme.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  bool get _compassAvailable {
    try {
      return FlutterCompass.events != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    final qibla = PrayerCalculator.qiblaDirection(s.latitude, s.longitude);
    final distance = PrayerCalculator.distanceToKaaba(s.latitude, s.longitude);
    final aligned = ValueNotifier<bool>(false);

    return Scaffold(
      body: GradientScaffold(
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: Text(s.isArabic ? 'اتجاه القبلة' : 'Qibla Direction'),
              ),
              Expanded(
                child: StreamBuilder<CompassEvent>(
                  stream: _compassAvailable ? FlutterCompass.events : null,
                  builder: (context, snapshot) {
                    final heading = snapshot.data?.heading ?? 0;
                    final hasSensor = snapshot.data?.heading != null;
                    final rotation = ((heading - qibla) * math.pi / 180);
                    final isAligned = hasSensor &&
                        (heading - qibla).abs() % 360 < 6;
                    aligned.value = isAligned;

                    return Column(
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          s.city,
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 18),
                        Expanded(
                          child: Center(
                            child: SizedBox(
                              width: 300,
                              height: 300,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // قرص البوصلة
                                  Transform.rotate(
                                    angle: -(heading) * math.pi / 180,
                                    child: CustomPaint(
                                      size: const Size(300, 300),
                                      painter: _CompassPainter(isAligned: isAligned),
                                    ),
                                  ),
                                  // سهم القبلة
                                  Transform.rotate(
                                    angle: rotation,
                                    child: CustomPaint(
                                      size: const Size(300, 300),
                                      painter: _QiblaArrowPainter(isAligned: isAligned),
                                    ),
                                  ),
                                  Container(
                                    width: 92,
                                    height: 92,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: isAligned
                                          ? AppColors.tealGradient
                                          : const LinearGradient(colors: [
                                              Color(0xFF16323F),
                                              Color(0xFF0B1F29)
                                            ]),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: Color(0x55000000),
                                            blurRadius: 20)
                                      ],
                                      border: Border.all(
                                          color: isAligned
                                              ? AppColors.teal
                                              : AppColors.gold.withOpacity(0.6),
                                          width: 2),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.mosque,
                                          color: isAligned
                                              ? AppColors.night
                                              : AppColors.gold,
                                          size: 26,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${qibla.round()}°',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: isAligned
                                                ? AppColors.night
                                                : AppColors.gold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (isAligned)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              s.isArabic
                                  ? '✓ أنت الآن في اتجاه القبلة'
                                  : '✓ You are facing the Qibla',
                              style: const TextStyle(
                                  color: AppColors.teal,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14),
                            ),
                          ),
                        if (!hasSensor)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Text(
                              s.isArabic
                                  ? 'حساس البوصلة غير متاح على هذا الجهاز — استخدم الزاوية الرقمية أدناه مع بوصلة عادية.'
                                  : 'Compass sensor not available — use the numeric angle below with a physical compass.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textMuted),
                            ),
                          ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _infoCard(
                                  s.isArabic ? 'زاوية القبلة' : 'Qibla Angle',
                                  '${qibla.round()}°',
                                  Icons.explore_outlined,
                                  AppColors.gold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _infoCard(
                                  s.isArabic ? 'المسافة لمكة' : 'To Makkah',
                                  '${distance.round()} ${s.isArabic ? 'كم' : 'km'}',
                                  Icons.straighten,
                                  AppColors.teal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.phone_android,
                                size: 13, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              s.isArabic
                                  ? 'اتجاه الشمال المُشار إليه هو شمال البوصلة المغناطيسي'
                                  : 'Arrow points to magnetic north',
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
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

  Widget _infoCard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      radius: 18,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10.5, color: AppColors.textMuted)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final bool isAligned;
  _CompassPainter({required this.isAligned});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // حلقة خارجية
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0x33FFFFFF));

    // حلقات داخلية
    for (final r in [radius - 18, radius - 46]) {
      canvas.drawCircle(
          center,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = const Color(0x22FFFFFF));
    }

    // علامات الدرجات
    for (var i = 0; i < 72; i++) {
      final angle = i * 5 * math.pi / 180;
      final isMajor = i % 6 == 0;
      final isMid = i % 3 == 0;
      final len = isMajor ? 14.0 : (isMid ? 8.0 : 5.0);
      final p1 = center + Offset(math.cos(angle), math.sin(angle)) * (radius - len);
      final p2 = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawLine(
          p1,
          p2,
          Paint()
            ..strokeWidth = isMajor ? 2 : 1
            ..color = isMajor
                ? AppColors.gold.withOpacity(0.8)
                : const Color(0x55FFFFFF));
    }

    // أسماء الجهات
    const labels = ['N', 'E', 'S', 'W'];
    for (var i = 0; i < 4; i++) {
      final angle = i * 90 * math.pi / 180 - math.pi / 2;
      final pos = center + Offset(math.cos(angle), math.sin(angle)) * (radius - 34);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: i == 0 ? 18 : 14,
            fontWeight: FontWeight.w700,
            color: i == 0 ? AppColors.danger : const Color(0xAAFFFFFF),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) => old.isAligned != isAligned;
}

class _QiblaArrowPainter extends CustomPainter {
  final bool isAligned;
  _QiblaArrowPainter({required this.isAligned});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..shader = (isAligned ? AppColors.tealGradient : AppColors.goldGradient)
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // سهم يتجه لأعلى (0°) — الدوران يتم بالـTransform
    final path = Path()
      ..moveTo(center.dx, center.dy - size.height / 2 + 16)
      ..lineTo(center.dx - 13, center.dy - size.height / 2 + 58)
      ..lineTo(center.dx + 13, center.dy - size.height / 2 + 58)
      ..close();
    canvas.drawPath(path, paint);

    final rect = Rect.fromCenter(
        center: Offset(center.dx, center.dy - size.height / 2 + 92),
        width: 4,
        height: 60);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);
  }

  @override
  bool shouldRepaint(covariant _QiblaArrowPainter old) => old.isAligned != isAligned;
}
