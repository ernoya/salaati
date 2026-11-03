import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../core/prayer_calculator.dart';
import '../core/settings.dart';

/// جدولة تنبيهات الأذان في الخلفية (إشعارات محلية مجدولة لسبعة أيام)
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _supported = false;
  static bool _initialized = false;

  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      if (!Platform.isAndroid && !Platform.isIOS) return;
      _supported = true;
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(
          _tzName(DateTime.now().timeZoneName, DateTime.now().timeZoneOffset)));

      const androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestAlertPermission: true,
        requestBadgePermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
      );

      if (Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await android?.requestNotificationsPermission();
        await android?.requestExactAlarmsPermission();
      } else {
        await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, sound: true);
      }
      _initialized = true;
    } catch (_) {
      _supported = false;
    }
  }

  static String _tzName(String abbrev, Duration offset) {
    final hours = offset.inMinutes / 60.0;
    // اختيار منطقة زمنية مطابقة حسب الإزاحة
    const map = {
      2: 'Africa/Cairo',
      3: 'Asia/Riyadh',
      4: 'Asia/Dubai',
      1: 'Africa/Tunis',
      0: 'Africa/Casablanca',
      -5: 'America/New_York',
      -8: 'America/Los_Angeles',
      5: 'Asia/Karachi',
      7: 'Asia/Jakarta',
      8: 'Asia/Singapore',
    };
    return map[hours.round()] ?? 'UTC';
  }

  /// إعادة جدولة كل التنبيهات لسبعة أيام قادمة
  static Future<void> scheduleAll(SettingsProvider s) async {
    if (!_supported || !_initialized) return;
    try {
      await _plugin.cancelAll();
      if (!s.athanEnabled) return;

      final now = DateTime.now();
      var id = 100;
      for (var day = 0; day < 7; day++) {
        final date = now.add(Duration(days: day));
        final times = s.timesFor(date);
        for (final key in PrayerCalculator.keys) {
          if (key == 'sunrise') continue;
          final at = times[key]!;
          if (at.isBefore(now.add(const Duration(minutes: 1)))) continue;

          final name = s.isArabic
              ? PrayerCalculator.arNames[key]!
              : PrayerCalculator.enNames[key]!;

          // تنبيه ما قبل الأذان لكل صلاة على حدة
          final pre = s.preAthanMinutesFor(key);
          if (pre > 0) {
            final preAt = at.subtract(Duration(minutes: pre));
            if (preAt.isAfter(now)) {
              await _schedule(
                id++,
                preAt,
                s.isArabic
                    ? 'اقترب وقت $name'
                    : '$name is approaching',
                s.isArabic
                    ? 'باقي $pre دقيقة على أذان $name'
                    : '$pre minutes until $name athan',
                sound: 'ping',
              );
            }
          }

          await _schedule(
            id++,
            at,
            s.isArabic ? 'حان وقت صلاة $name' : 'It is time for $name',
            s.isArabic
                ? 'الله أكبر — حان الآن وقت صلاة $name'
                : 'Allahu Akbar — it is time for $name prayer',
            sound: s.athanSound,
          );
        }
      }

      // جدولة التذكير الصوتي الدوري بالصلاة على النبي ﷺ
      if (s.salawatAudioReminderEnabled && s.salawatIntervalMinutes > 0) {
        var salawatId = 5000;
        final interval = Duration(minutes: s.salawatIntervalMinutes);
        var t = now.add(interval);
        final end = now.add(const Duration(days: 2));
        while (t.isBefore(end)) {
          if (t.hour >= 7 && t.hour <= 23) {
            await _schedule(
              salawatId++,
              t,
              s.isArabic ? 'صلِّ على محمّد ﷺ' : 'Blessings upon Muhammad ﷺ',
              s.isArabic
                  ? 'اللَّهُمَّ صَلِّ وَسَلِّمْ وَبَارِكْ عَلَى نَبِيِّنَا مُحَمَّدٍ ﷺ'
                  : 'Allahumma salli wa sallim ala nabiyyina Muhammad ﷺ',
              sound: 'salawat',
            );
          }
          t = t.add(interval);
        }
      }
    } catch (_) {
      // تجاهل أخطاء الجدولة (مثلاً على الويب)
    }
  }

  static Future<void> _schedule(
    int id,
    DateTime at,
    String title,
    String body, {
    String sound = 'makkah',
  }) async {
    final soundFile = sound == 'madinah'
        ? 'athan_madina'
        : sound == 'alafasy'
            ? 'athan_alafasy'
            : sound == 'ping' || sound == 'salawat'
                ? 'notification'
                : 'athan_makkah';

    final android = AndroidNotificationDetails(
      'athan_channel',
      'أذان الصلاة',
      channelDescription: 'تنبيهات مواقيت الصلاة والأذان',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundFile),
      enableVibration: true,
      styleInformation: BigTextStyleInformation(body),
      ticker: title,
    );

    final ios = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      sound: '$soundFile.wav',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(at, tz.local),
      NotificationDetails(android: android, iOS: ios),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// إشعار فوري للتجربة
  static Future<void> testNow(SettingsProvider s) async {
    if (!_supported || !_initialized) return;
    await _schedule(
      1,
      DateTime.now().add(const Duration(seconds: 3)),
      s.isArabic ? 'تجربة الأذان' : 'Athan test',
      s.isArabic
          ? 'هذا تنبيه تجريبي — ستسمع صوت الأذان عند دخول وقت الصلاة'
          : 'Test notification — athan will play at prayer time',
    );
  }
}
