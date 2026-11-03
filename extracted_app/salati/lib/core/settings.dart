import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'prayer_calculator.dart';

/// إعدادات التطبيق + التخزين المحلي
class SettingsProvider extends ChangeNotifier {
  static const _prefix = 'pn_';

  bool isArabic = true;
  double latitude = 30.0444;
  double longitude = 31.2357;
  String cityAr = 'الجيزة';
  String cityEn = 'Giza';
  bool useGps = true;

  PrayerMethod method = PrayerMethod.egyptian;
  String madhab = 'shafi';
  int dhuhrMinutes = 0;
  int maghribMinutes = 0;
  double? manualFajrAngle;
  double? manualIshaAngle;
  int? manualIshaMinutes;

  Map<String, int> adjustments = {
    'fajr': 0,
    'sunrise': 0,
    'dhuhr': 0,
    'asr': 0,
    'maghrib': 0,
    'isha': 0,
  };

  // الأذان والتنبيهات الاستباقية
  bool athanEnabled = true;
  String athanSound = 'makkah';
  double athanVolume = 0.9;
  bool vibrate = true;
  bool silentDuringCall = false;
  double preAthanMinutes = 0;

  // تنبيه استباقي مخصص لكل صلاة على حدة (بالدقائق: 0 = معطل)
  Map<String, int> preAthanByPrayer = {
    'fajr': 15,
    'dhuhr': 10,
    'asr': 10,
    'maghrib': 10,
    'isha': 10,
  };

  // الأذكار العائمة على الشاشة
  bool floatingAzkarEnabled = true;
  int floatingAzkarIntervalMinutes = 15; // كل 15 دقيقة

  // التذكير الصوتي الدوري "صلّ على محمد" ﷺ
  bool salawatAudioReminderEnabled = true;
  int salawatIntervalMinutes = 30; // كل 30 دقيقة (قابلة للتعديل: 15, 30, 45, 60, 120 دقيقة)
  double salawatVolume = 0.9;

  // المظهر
  String theme = 'night'; // night | emerald | sand
  bool use24h = true;

  late SharedPreferences _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    isArabic = _prefs.getBool('${_prefix}isArabic') ?? true;
    useGps = _prefs.getBool('${_prefix}useGps') ?? true;
    latitude = _prefs.getDouble('${_prefix}lat') ?? 30.0444;
    longitude = _prefs.getDouble('${_prefix}lng') ?? 31.2357;
    cityAr = _prefs.getString('${_prefix}cityAr') ?? 'الجيزة';
    cityEn = _prefs.getString('${_prefix}cityEn') ?? 'Giza';
    final m = _prefs.getInt('${_prefix}method');
    if (m != null) {
      method = PrayerMethod.values.firstWhere((e) => e.index == m,
          orElse: () => PrayerMethod.egyptian);
    }
    madhab = _prefs.getString('${_prefix}madhab') ?? 'shafi';
    dhuhrMinutes = _prefs.getInt('${_prefix}dhuhrMin') ?? 0;
    maghribMinutes = _prefs.getInt('${_prefix}maghribMin') ?? 0;
    manualFajrAngle = _prefs.getDouble('${_prefix}fajrAngle');
    manualIshaAngle = _prefs.getDouble('${_prefix}ishaAngle');
    manualIshaMinutes = _prefs.getInt('${_prefix}ishaMinutes');
    athanEnabled = _prefs.getBool('${_prefix}athanEnabled') ?? true;
    athanSound = _prefs.getString('${_prefix}athanSound') ?? 'makkah';
    athanVolume = _prefs.getDouble('${_prefix}athanVolume') ?? 0.9;
    vibrate = _prefs.getBool('${_prefix}vibrate') ?? true;
    silentDuringCall = _prefs.getBool('${_prefix}silentDuringCall') ?? false;
    preAthanMinutes = _prefs.getDouble('${_prefix}preAthan') ?? 0;
    for (final k in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
      final saved = _prefs.getInt('${_prefix}preAthan_$k');
      if (saved != null) {
        preAthanByPrayer[k] = saved;
      }
    }
    theme = _prefs.getString('${_prefix}theme') ?? 'night';
    use24h = _prefs.getBool('${_prefix}use24h') ?? true;
    floatingAzkarEnabled = _prefs.getBool('${_prefix}floatingAzkar') ?? true;
    floatingAzkarIntervalMinutes = _prefs.getInt('${_prefix}floatingInterval') ?? 15;
    salawatAudioReminderEnabled = _prefs.getBool('${_prefix}salawatEnabled') ?? true;
    salawatIntervalMinutes = _prefs.getInt('${_prefix}salawatInterval') ?? 30;
    salawatVolume = _prefs.getDouble('${_prefix}salawatVolume') ?? 0.9;
    for (final k in adjustments.keys.toList()) {
      adjustments[k] = _prefs.getInt('${_prefix}adj_$k') ?? 0;
    }
    notifyListeners();
  }

  void _saveString(String key, String v) =>
      _prefs.setString('$_prefix$key', v);
  void _saveBool(String key, bool v) => _prefs.setBool('$_prefix$key', v);
  void _saveInt(String key, int v) => _prefs.setInt('$_prefix$key', v);
  void _saveDouble(String key, double v) => _prefs.setDouble('$_prefix$key', v);

  set arabic(bool v) { isArabic = v; _saveBool('isArabic', v); notifyListeners(); }
  set gps(bool v) { useGps = v; _saveBool('useGps', v); notifyListeners(); }
  set themeName(String v) { theme = v; _saveString('theme', v); notifyListeners(); }
  set hour24(bool v) { use24h = v; _saveBool('use24h', v); notifyListeners(); }
  set madhabName(String v) { madhab = v; _saveString('madhab', v); notifyListeners(); }
  set sound(String v) { athanSound = v; _saveString('athanSound', v); notifyListeners(); }
  set enableAthan(bool v) { athanEnabled = v; _saveBool('athanEnabled', v); notifyListeners(); }
  set volume(double v) { athanVolume = v; _saveDouble('athanVolume', v); notifyListeners(); }
  set doVibrate(bool v) { vibrate = v; _saveBool('vibrate', v); notifyListeners(); }
  set preAthan(double v) { preAthanMinutes = v; _saveDouble('preAthan', v); notifyListeners(); }

  set enableFloatingAzkar(bool v) { floatingAzkarEnabled = v; _saveBool('floatingAzkar', v); notifyListeners(); }
  set floatingInterval(int v) { floatingAzkarIntervalMinutes = v; _saveInt('floatingInterval', v); notifyListeners(); }
  set enableSalawat(bool v) { salawatAudioReminderEnabled = v; _saveBool('salawatEnabled', v); notifyListeners(); }
  set salawatInterval(int v) { salawatIntervalMinutes = v; _saveInt('salawatInterval', v); notifyListeners(); }
  set salVolume(double v) { salawatVolume = v; _saveDouble('salawatVolume', v); notifyListeners(); }

  int preAthanMinutesFor(String prayerKey) {
    return preAthanByPrayer[prayerKey] ?? preAthanMinutes.round();
  }

  void setPreAthanForPrayer(String key, int minutes) {
    preAthanByPrayer[key] = minutes;
    _saveInt('preAthan_$key', minutes);
    notifyListeners();
  }

  set methodName(PrayerMethod m) {
    method = m;
    manualFajrAngle = null;
    manualIshaAngle = null;
    manualIshaMinutes = null;
    _saveInt('method', m.index);
    _prefs.remove('${_prefix}fajrAngle');
    _prefs.remove('${_prefix}ishaAngle');
    _prefs.remove('${_prefix}ishaMinutes');
    notifyListeners();
  }

  void setCity({
    required String ar,
    required String en,
    required double lat,
    required double lng,
    bool gps = false,
  }) {
    cityAr = ar;
    cityEn = en;
    latitude = lat;
    longitude = lng;
    useGps = gps;
    _saveString('cityAr', ar);
    _saveString('cityEn', en);
    _saveDouble('lat', lat);
    _saveDouble('lng', lng);
    _saveBool('useGps', gps);
    notifyListeners();
  }

  void setAdjustment(String key, int value) {
    adjustments[key] = value;
    _saveInt('adj_$key', value);
    notifyListeners();
  }

  void setDhuhrMinutes(int v) { dhuhrMinutes = v; _saveInt('dhuhrMin', v); notifyListeners(); }
  void setMaghribMinutes(int v) { maghribMinutes = v; _saveInt('maghribMin', v); notifyListeners(); }
  void setManualFajrAngle(double? v) {
    manualFajrAngle = v;
    if (v == null) { _prefs.remove('${_prefix}fajrAngle'); } else { _saveDouble('fajrAngle', v); }
    notifyListeners();
  }
  void setManualIshaAngle(double? v) {
    manualIshaAngle = v;
    if (v == null) { _prefs.remove('${_prefix}ishaAngle'); } else { _saveDouble('ishaAngle', v); }
    notifyListeners();
  }
  void setManualIshaMinutes(int? v) {
    manualIshaMinutes = v;
    if (v == null) { _prefs.remove('${_prefix}ishaMinutes'); } else { _saveInt('ishaMinutes', v); }
    notifyListeners();
  }

  String get city => isArabic ? cityAr : cityEn;
  String tr(String ar, String en) => isArabic ? ar : en;

  /// مواقيت اليوم
  Map<String, DateTime> timesFor(DateTime date) => PrayerCalculator.prayerTimes(
        date: date,
        latitude: latitude,
        longitude: longitude,
        method: method,
        madhab: madhab,
        manualFajrAngle: manualFajrAngle,
        manualIshaAngle: manualIshaAngle,
        manualIshaMinutes: manualIshaMinutes,
        dhuhrMinutes: dhuhrMinutes,
        maghribMinutes: maghribMinutes,
        adjustments: adjustments,
        tzOffsetHours: DateTime.now().timeZoneOffset.inMinutes / 60.0,
      );
}
