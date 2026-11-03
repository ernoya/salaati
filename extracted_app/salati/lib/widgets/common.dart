import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// ساعة تتحدث كل ثانية
class Ticker extends StatefulWidget {
  final Widget Function(BuildContext, DateTime) builder;
  final Duration interval;
  const Ticker({super.key, required this.builder, this.interval = const Duration(seconds: 1)});

  @override
  State<Ticker> createState() => _TickerState();
}

class _TickerState extends State<Ticker> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.interval, (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _now);
}

String formatTime(DateTime t, bool use24, {bool withSeconds = false}) {
  final h = t.hour, m = t.minute, s = t.second;
  if (use24) {
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}'
        '${withSeconds ? ':${s.toString().padLeft(2, '0')}' : ''}';
  }
  final period = h >= 12 ? 'PM' : 'AM';
  final hh = h % 12 == 0 ? 12 : h % 12;
  return '${hh.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
}

String arabicDigits(String s) {
  const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  var out = s;
  for (var i = 0; i < 10; i++) {
    out = out.replaceAll(western[i], eastern[i]);
  }
  return out;
}

String hijriDate(DateTime d, bool isArabic) {
  // تحويل تقريبي دقيق (خوارزمية أم القرى المبسطة)
  final jd = _gregorianToJD(d.year, d.month, d.day);
  final l = jd - 1948440 + 10632;
  final n = ((l - 1) / 10631).floor();
  var l2 = l - 10631 * n + 354;
  final j = (((10985 - l2) / 5316).floor()) * (((50 * l2) / 17719).floor()) +
      ((l2 / 5670).floor()) * (((43 * l2) / 15238).floor());
  l2 = l2 -
      ((30 - j) / 15).floor() * (((17719 * j) / 50).floor()) -
      ((j / 16).floor()) * (((15238 * j) / 43).floor()) +
      29;
  final month = (24 * l2 / 709).floor();
  final day = l2 - ((709 * month) / 24).floor();
  final year = 30 * n + j - 30;

  const monthsAr = [
    'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة',
    'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'
  ];
  const monthsEn = [
    'Muharram', 'Safar', "Rabi' al-Awwal", "Rabi' al-Thani", 'Jumada al-Ula',
    'Jumada al-Akhirah', 'Rajab', "Sha'ban", 'Ramadan', 'Shawwal',
    "Dhul Qa'dah", 'Dhul Hijjah'
  ];
  if (isArabic) {
    return '${arabicDigits('$day')} ${monthsAr[(month - 1).clamp(0, 11)]} ${arabicDigits('$year')} هـ';
  }
  return '$day ${monthsEn[(month - 1).clamp(0, 11)]} $year AH';
}

int _gregorianToJD(int y, int m, int d) {
  if (m <= 2) {
    y -= 1;
    m += 12;
  }
  final a = (y / 100).floor();
  final b = 2 - a + (a / 4).floor();
  return (365.25 * (y + 4716)).floor() +
      (30.6001 * (m + 1)).floor() +
      d +
      b -
      1524;
}

const List<String> _weekdaysAr = [
  'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'
];
const List<String> _monthsGregAr = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس',
  'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
];

String gregorianDate(DateTime d, bool isArabic) {
  if (isArabic) {
    return '${_monthsGregAr[d.month - 1]} ${arabicDigits('${d.year}')}';
  }
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const w = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return '${w[d.weekday - 1]}, ${d.day} ${m[d.month - 1]} ${d.year}';
}

String weekdayName(DateTime d, bool isArabic) => isArabic
    ? _weekdaysAr[d.weekday - 1]
    : const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][d.weekday - 1];

/// شارة صغيرة
class Pill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color color;
  final bool filled;
  final VoidCallback? onTap;
  const Pill(this.text, {super.key, this.icon, this.color = AppColors.teal, this.filled = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: filled ? color.withOpacity(0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(text,
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(borderRadius: BorderRadius.circular(30), onTap: onTap, child: content);
  }
}

/// عدّاد تنازلي كبير
class CountdownText extends StatelessWidget {
  final Duration remaining;
  final double size;
  final Color color;
  const CountdownText(this.remaining, {super.key, this.size = 44, this.color = AppColors.textPrimary});

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    final s = remaining.inSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _unit(two(h), isArabic ? 'ساعة' : 'hr'),
        _sep(),
        _unit(two(m), isArabic ? 'دقيقة' : 'min'),
        _sep(),
        _unit(two(s), isArabic ? 'ثانية' : 'sec'),
      ],
      ),
    );
  }

  Widget _unit(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: size,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()])),
        Text(label,
            style: const TextStyle(
                fontFamily: 'Cairo', fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _sep() => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(':',
            style: TextStyle(
                fontSize: size * 0.7,
                color: AppColors.textMuted.withOpacity(0.6),
                fontWeight: FontWeight.w300)),
      );
}

/// شعار التطبيق (قبة + هلال مرسومان برمجيًا)
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MosquePainter()),
    );
  }
}

class _MosquePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final gold = Paint()
      ..shader = AppColors.goldGradient.createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    // القبة
    final domeRect = Rect.fromLTWH(w * 0.28, h * 0.26, w * 0.44, h * 0.44);
    canvas.drawArc(domeRect, 3.14159, 3.14159, true, gold);
    // بدن القبة
    canvas.drawRect(Rect.fromLTWH(w * 0.28, h * 0.48, w * 0.44, h * 0.16), gold);
    // المآذن
    canvas.drawRect(Rect.fromLTWH(w * 0.14, h * 0.40, w * 0.07, h * 0.34), gold);
    canvas.drawRect(Rect.fromLTWH(w * 0.79, h * 0.40, w * 0.07, h * 0.34), gold);
    canvas.drawCircle(Offset(w * 0.175, h * 0.40), w * 0.045, gold);
    canvas.drawCircle(Offset(w * 0.825, h * 0.40), w * 0.045, gold);
    // القاعدة
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.10, h * 0.64, w * 0.80, h * 0.14),
            Radius.circular(h * 0.02)),
        gold);
    // الهلال
    final moon = Paint()..color = AppColors.night;
    canvas.drawCircle(Offset(w * 0.5, h * 0.14), w * 0.075, gold);
    canvas.drawCircle(Offset(w * 0.54, h * 0.115), w * 0.065, moon);
    // باب
    final door = Paint()..color = AppColors.night.withOpacity(0.85);
    canvas.drawArc(Rect.fromLTWH(w * 0.43, h * 0.56, w * 0.14, h * 0.18), 3.14159, 3.14159, true, door);
    canvas.drawRect(Rect.fromLTWH(w * 0.43, h * 0.65, w * 0.14, h * 0.13), door);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
