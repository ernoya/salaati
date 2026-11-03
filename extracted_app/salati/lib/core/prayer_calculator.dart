import 'dart:math' as math;

/// حساب مواقيت الصلاة فلكيًا بدون إنترنت — مطابق لخوارزميات
/// "Prayer Times Calculation" (Hamid Zarrabi-Zadeh / praytimes.org)
class PrayerCalculator {
  static const List<String> keys = [
    'fajr',
    'sunrise',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  static const Map<String, String> arNames = {
    'fajr': 'الفجر',
    'sunrise': 'الشروق',
    'dhuhr': 'الظهر',
    'asr': 'العصر',
    'maghrib': 'المغرب',
    'isha': 'العشاء',
  };

  static const Map<String, String> enNames = {
    'fajr': 'Fajr',
    'sunrise': 'Sunrise',
    'dhuhr': 'Dhuhr',
    'asr': 'Asr',
    'maghrib': 'Maghrib',
    'isha': 'Isha',
  };

  static double _d2r(double d) => d * math.pi / 180.0;
  static double _r2d(double r) => r * 180.0 / math.pi;
  static double _sin(double d) => math.sin(_d2r(d));
  static double _cos(double d) => math.cos(_d2r(d));
  static double _tan(double d) => math.tan(_d2r(d));

  static double fixAngle(double a) {
    a = a - 360.0 * (a / 360.0).floorToDouble();
    return a < 0 ? a + 360.0 : a;
  }

  static double fixHour(double h) {
    h = h - 24.0 * (h / 24.0).floorToDouble();
    return h < 0 ? h + 24.0 : h;
  }

  static double julianDate(int year, int month, int day) {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    final a = (year / 100).floorToDouble();
    final b = 2 - a + (a / 4).floorToDouble();
    return (365.25 * (year + 4716)).floorToDouble() +
        (30.6001 * (month + 1)).floorToDouble() +
        day +
        b -
        1524.5;
  }

  static Map<String, double> _sunPosition(double jd) {
    final d = jd - 2451545.0;
    final g = fixAngle(357.529 + 0.98560028 * d);
    final q = fixAngle(280.459 + 0.98564736 * d);
    final l = fixAngle(q + 1.915 * _sin(g) + 0.020 * _sin(2 * g));
    final e = 23.439 - 0.00000036 * d;
    final ra = fixHour(_r2d(math.atan2(_cos(e) * _sin(l), _cos(l))) / 15.0);
    final decl = _r2d(math.asin(_sin(e) * _sin(l)));
    return {'decl': decl, 'eqt': q / 15.0 - ra};
  }

  /// يحسب المواقيت كأجزاء من الساعة (0..24) بالتوقيت المحلي للنقطة
  static Map<String, double> rawTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    required PrayerMethod method,
    required String madhab, // 'shafi' | 'hanafi'
    double? manualFajrAngle,
    double? manualIshaAngle,
    int? manualIshaMinutes,
    double manualAsrFactor = 1,
    int dhuhrMinutes = 0,
    int maghribMinutes = 0,
    double elevation = 0,
    double timezoneOffsetHours = 0,
    bool? daylightSaving,
  }) {
    final jdBase = julianDate(date.year, date.month, date.day) -
        longitude / (15.0 * 24.0);
    double transitTime = 0, decl = 0;

    Map<String, double> sunAt(double tHours) =>
        _sunPosition(jdBase + tHours / 24.0);

    // المرور الشمسي (الزوال)
    double midDay(double t) => fixHour(12.0 - sunAt(t)['eqt']!);
    transitTime = midDay(12);
    decl = sunAt(12)['decl']!;

    // زاوية ارتفاع الشمس (سالبة تحت الأفق) → جزء من اليوم بالساعات
    double hourAngleFromAltitude(double altitude) {
      final cosH = (_sin(altitude) - _sin(decl) * _sin(latitude)) /
          (_cos(decl) * _cos(latitude));
      if (cosH < -1 || cosH > 1) return double.nan;
      return _r2d(math.acos(cosH)) / 15.0;
    }

    final fajrAngle = manualFajrAngle ?? method.fajrAngle;
    final ishaAngle = manualIshaAngle ?? method.ishaAngle;

    // تصحيح الانكسار الجوي + الارتفاع
    final riseSetAltitude = -0.833 - 0.0347 * math.sqrt(elevation.clamp(0, 6000));

    final asrFactor = madhab == 'hanafi' ? 2.0 : 1.0;

    double asrTime() {
      final angle = _r2d(math.atan(
          1.0 / (asrFactor * manualAsrFactor + _tan((latitude - decl).abs()))));
      final h = hourAngleFromAltitude(angle);
      return transitTime + (h.isNaN ? 5.0 : h);
    }

    var fajrH = hourAngleFromAltitude(-fajrAngle);
    var sunriseH = hourAngleFromAltitude(riseSetAltitude);
    var sunsetH = hourAngleFromAltitude(riseSetAltitude);

    // معالجة خطوط العرض العالية: عندما لا تغيب الشمس/لا يظهر الفجر بزاوية محددة
    if (sunriseH.isNaN || sunsetH.isNaN) {
      sunriseH = 6.0;
      sunsetH = 6.0;
    }
    final nightLength = (24.0 - 2 * sunsetH).clamp(0.0, 24.0);
    final asr = asrTime();
    double isha;
    if (ishaAngle != null) {
      final h = hourAngleFromAltitude(-ishaAngle);
      // عند تعذر الحساب (خطوط العرض العالية) نستخدم جزءًا من الليل
      final fallback = sunsetH + nightLength / 7.0;
      isha = transitTime + (h.isNaN ? fallback : h);
    } else {
      isha = transitTime + sunsetH + ((manualIshaMinutes ?? 90) / 60.0);
    }
    if (fajrH.isNaN) {
      // تقدير: سُبع الليل قبل الشروق
      fajrH = sunriseH + nightLength / 7.0;
    }

    // تحويل من منتصف الليل الشمسي إلى التوقيت المحلي للمنطقة الزمنية
    final gmtDiff = timezoneOffsetHours - longitude / 15.0;
    double adjust(double t) => fixHour(t + gmtDiff);

    return {
      'fajr': adjust(transitTime - (fajrH.isNaN ? 0 : fajrH)),
      'sunrise': adjust(transitTime - (sunriseH.isNaN ? 0 : sunriseH)),
      'dhuhr': adjust(transitTime + dhuhrMinutes / 60.0),
      'asr': adjust(asr),
      'maghrib': adjust(transitTime + (sunsetH.isNaN ? 0 : sunsetH) +
          maghribMinutes / 60.0),
      'isha': adjust(isha),
    };
  }

  /// يرجع المواقيت كDateTime فعلية (مع معالجة تجاوز منتصف الليل)
  static Map<String, DateTime> prayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    required PrayerMethod method,
    String madhab = 'shafi',
    double? manualFajrAngle,
    double? manualIshaAngle,
    int? manualIshaMinutes,
    double manualAsrFactor = 1,
    int dhuhrMinutes = 0,
    int maghribMinutes = 0,
    double elevation = 0,
    Map<String, int> adjustments = const {},
    double? tzOffsetHours,
  }) {
    final raw = rawTimes(
      date: date,
      latitude: latitude,
      longitude: longitude,
      method: method,
      madhab: madhab,
      manualFajrAngle: manualFajrAngle,
      manualIshaAngle: manualIshaAngle,
      manualIshaMinutes: manualIshaMinutes,
      manualAsrFactor: manualAsrFactor,
      dhuhrMinutes: dhuhrMinutes,
      maghribMinutes: maghribMinutes,
      elevation: elevation,
      timezoneOffsetHours: tzOffsetHours ??
          date.timeZoneOffset.inMinutes / 60.0,
    );

    final result = <String, DateTime>{};
    final base = DateTime(date.year, date.month, date.day);
    raw.forEach((key, hours) {
      final h = hours + (adjustments[key] ?? 0) / 60.0;
      result[key] = base.add(Duration(seconds: (h * 3600).round()));
    });
    return result;
  }

  /// اتجاه القبلة بالدرجات من الشمال
  static double qiblaDirection(double latitude, double longitude) {
    const kaabaLat = 21.4225;
    const kaabaLng = 39.8262;
    final phiK = _d2r(kaabaLat);
    final phi = _d2r(latitude);
    final dLng = _d2r(kaabaLng - longitude);
    final y = math.sin(dLng);
    final x = math.cos(phi) * math.tan(phiK) - math.sin(phi) * math.cos(dLng);
    var deg = _r2d(math.atan2(y, x));
    return (deg + 360.0) % 360.0;
  }

  /// المسافة بالكيلومترات إلى مكة المكرمة
  static double distanceToKaaba(double latitude, double longitude) {
    const kaabaLat = 21.4225, kaabaLng = 39.8262;
    const r = 6371.0;
    final dLat = _d2r(kaabaLat - latitude);
    final dLng = _d2r(kaabaLng - longitude);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        _cos(latitude) * _cos(kaabaLat) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  /// الوقت المتبقي للصلاة القادمة
  static Map<String, dynamic> nextPrayer(Map<String, DateTime> times, DateTime now) {
    for (final key in keys) {
      final t = times[key];
      if (t == null) continue;
      if (t.isAfter(now)) {
        return {'key': key, 'time': t, 'remaining': t.difference(now)};
      }
    }
    final fajr = times['fajr']!.add(const Duration(days: 1));
    return {'key': 'fajr', 'time': fajr, 'remaining': fajr.difference(now)};
  }

  /// الصلاة الحالية (التي دخل وقتها)
  static String currentPrayer(Map<String, DateTime> times, DateTime now) {
    String current = 'isha';
    for (final key in const ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
      final t = times[key];
      if (t != null && !now.isBefore(t)) current = key;
    }
    return current;
  }
}

/// طرق الحساب المعتمدة
enum PrayerMethod {
  egyptian(5, 'الهيئة المصرية العامة للمساحة', 'Egyptian General Authority', 19.5, 17.5),
  ummAlQura(4, 'أم القرى — مكة المكرمة', 'Umm Al-Qura, Makkah', 18.5, null, ishaMinutes: 90),
  mwl(3, 'رابطة العالم الإسلامي', 'Muslim World League', 18.0, 17.0),
  isna(2, 'الجمعية الإسلامية لأمريكا الشمالية', 'ISNA (North America)', 15.0, 15.0),
  karachi(1, 'جامعة العلوم الإسلامية — كراتشي', 'University of Islamic Sciences, Karachi', 18.0, 18.0),
  dubai(16, 'الإمارات — دبي', 'Dubai', 18.2, 18.2),
  kuwait(9, 'الكويت', 'Kuwait', 18.0, 17.5),
  qatar(10, 'قطر', 'Qatar', 18.0, null, ishaMinutes: 90),
  singapore(11, 'سنغافورة', 'Singapore', 20.0, 18.0),
  turkey(13, 'تركيا — ديانت', 'Turkey (Diyanet)', 18.0, 17.0),
  tehran(7, 'إيران — طهران', 'Tehran', 17.7, 14.0),
  morocco(21, 'المغرب', 'Morocco', 19.0, 17.0),
  algeria(19, 'الجزائر', 'Algeria', 18.0, 17.0),
  tunisia(20, 'تونس', 'Tunisia', 18.0, 18.0),
  jordan(23, 'الأردن', 'Jordan', 18.0, 18.0);

  const PrayerMethod(this.apiId, this.arLabel, this.enLabel, this.fajrAngle,
      this.ishaAngle,
      {this.ishaMinutes});

  final int apiId;
  final String arLabel;
  final String enLabel;
  final double fajrAngle;
  final double? ishaAngle;
  final int? ishaMinutes;

  String label(bool isArabic) => isArabic ? arLabel : enLabel;
}
