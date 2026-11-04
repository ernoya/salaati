import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../core/prayer_calculator.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../services/athan_service.dart';
import '../services/notification_service.dart';
import '../widgets/common.dart';
import 'home_screen.dart' show CitiesScreen;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    final athan = context.watch<AthanService>();

    return Scaffold(
      body: GradientScaffold(
        child: SafeArea(
          child: Column(
            children: [
              AppBar(title: Text(s.isArabic ? 'الإعدادات' : 'Settings')),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                  children: [
                    _section(s.isArabic ? 'اللغة والمظهر' : 'Language & Look'),
                    _card([
                      _switchTile(
                        icon: Icons.translate,
                        title: s.isArabic ? 'العربية' : 'Arabic',
                        subtitle: s.isArabic
                            ? 'واجهة التطبيق بالعربية'
                            : 'App interface language',
                        value: s.isArabic,
                        onChanged: (v) => s.arabic = v,
                      ),
                      _divider(),
                      _switchTile(
                        icon: Icons.schedule,
                        title: s.isArabic ? 'نظام ٢٤ ساعة' : '24-hour clock',
                        subtitle: s.isArabic ? '٢٠:٠٠ بدل ٨:٠٠ م' : '20:00 instead of 8:00 PM',
                        value: s.use24h,
                        onChanged: (v) => s.hour24 = v,
                      ),
                    ]),

                    _section(s.isArabic ? 'الموقع' : 'Location'),
                    _card([
                      ListTile(
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          messenger.showSnackBar(const SnackBar(
                              content: Text('جارٍ تحديد الموقع...',
                                  style: TextStyle(fontFamily: 'Cairo'))));
                          try {
                            var perm = await Geolocator.checkPermission();
                            if (perm == LocationPermission.denied) {
                              perm = await Geolocator.requestPermission();
                            }
                            if (perm == LocationPermission.denied ||
                                perm == LocationPermission.deniedForever) {
                              messenger.showSnackBar(const SnackBar(
                                  content: Text(
                                      'تم رفض إذن الموقع — يمكنك اختيار المدينة يدويًا',
                                      style: TextStyle(fontFamily: 'Cairo'))));
                              return;
                            }
                            final pos = await Geolocator.getCurrentPosition(
                              locationSettings: const LocationSettings(
                                  accuracy: LocationAccuracy.medium,
                                  timeLimit: Duration(seconds: 12)),
                            );
                            s.setCity(
                              ar: 'موقعي الحالي',
                              en: 'My Location',
                              lat: pos.latitude,
                              lng: pos.longitude,
                              gps: true,
                            );
                            NotificationService.scheduleAll(s);
                            messenger.showSnackBar(const SnackBar(
                                content: Text('تم تحديث الموقع بنجاح',
                                    style: TextStyle(fontFamily: 'Cairo'))));
                          } catch (e) {
                            messenger.showSnackBar(SnackBar(
                                content: Text('تعذر تحديد الموقع: $e',
                                    style:
                                        const TextStyle(fontFamily: 'Cairo'))));
                          }
                        },
                        leading: const Icon(Icons.my_location,
                            color: AppColors.teal),
                        title: Text(
                            s.isArabic
                                ? 'استخدام موقعي الحالي (GPS)'
                                : 'Use my current location (GPS)',
                            style: const TextStyle(fontSize: 13.5)),
                        subtitle: Text(
                          '${s.latitude.toStringAsFixed(4)}, ${s.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
                        ),
                      ),
                      _divider(),
                      ListTile(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CitiesScreen())),
                        leading: const Icon(Icons.location_city,
                            color: AppColors.gold),
                        title: Text(
                            s.isArabic
                                ? 'اختيار المدينة يدويًا'
                                : 'Choose city manually',
                            style: const TextStyle(fontSize: 13.5)),
                        subtitle: Text(s.city,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                        trailing: const Icon(Icons.chevron_left,
                            size: 18, color: AppColors.textMuted),
                      ),
                    ]),

                    _section(s.isArabic ? 'طريقة حساب المواقيت' : 'Calculation Method'),
                    _card([
                      ListTile(
                        leading: const Icon(Icons.calculate_outlined,
                            color: AppColors.teal),
                        title: Text(
                            s.isArabic ? 'طريقة الحساب' : 'Calculation method',
                            style: const TextStyle(fontSize: 13.5)),
                        subtitle: Text(s.method.label(s.isArabic),
                            style: const TextStyle(
                                fontSize: 11.5, color: AppColors.gold)),
                        trailing: const Icon(Icons.expand_more,
                            size: 20, color: AppColors.textMuted),
                        onTap: () => _pickMethod(context, s),
                      ),
                      _divider(),
                      ListTile(
                        leading: const Icon(Icons.wb_sunny_outlined,
                            color: AppColors.gold),
                        title: Text(
                            s.isArabic ? 'مذهب العصر' : 'Asr calculation',
                            style: const TextStyle(fontSize: 13.5)),
                        subtitle: Text(
                            s.madhab == 'hanafi'
                                ? (s.isArabic ? 'الحنفي (الظل مرتين)' : 'Hanafi (shadow x2)')
                                : (s.isArabic ? 'الجمهور (الظل مرة)' : 'Standard (shadow x1)'),
                            style: const TextStyle(
                                fontSize: 11.5, color: AppColors.textMuted)),
                        trailing: Switch(
                          value: s.madhab == 'hanafi',
                          activeColor: AppColors.teal,
                          onChanged: (v) =>
                              s.madhabName = v ? 'hanafi' : 'shafi',
                        ),
                      ),
                      _divider(),
                      _sliderTile(context,
                        icon: Icons.tune,
                        title: s.isArabic ? 'تعديل دقائق الظهر' : 'Dhuhr offset (min)',
                        value: s.dhuhrMinutes.toDouble(),
                        min: -10,
                        max: 30,
                        label: '${s.dhuhrMinutes}',
                        onChanged: (v) => s.setDhuhrMinutes(v.round()),
                      ),
                      _divider(),
                      _sliderTile(context,
                        icon: Icons.tune,
                        title: s.isArabic ? 'تعديل دقائق المغرب' : 'Maghrib offset (min)',
                        value: s.maghribMinutes.toDouble(),
                        min: -10,
                        max: 30,
                        label: '${s.maghribMinutes}',
                        onChanged: (v) => s.setMaghribMinutes(v.round()),
                      ),
                      _divider(),
                      ExpansionTile(
                        shape: const Border(),
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                        leading: const Icon(Icons.timelapse,
                            color: AppColors.teal),
                        title: Text(
                            s.isArabic
                                ? 'تعديل دقائق كل صلاة'
                                : 'Per-prayer adjustments',
                            style: const TextStyle(fontSize: 13.5)),
                        children: [
                          for (final key in PrayerCalculator.keys)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 2),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 70,
                                    child: Text(
                                      s.isArabic
                                          ? PrayerCalculator.arNames[key]!
                                          : PrayerCalculator.enNames[key]!,
                                      style: const TextStyle(fontSize: 12.5),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline,
                                        size: 18),
                                    onPressed: () => s.setAdjustment(
                                        key, s.adjustments[key]! - 1),
                                  ),
                                  Text('${s.adjustments[key]}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline,
                                        size: 18),
                                    onPressed: () => s.setAdjustment(
                                        key, s.adjustments[key]! + 1),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ]),

                    _section(s.isArabic ? 'الأذان والتنبيهات' : 'Athan & Notifications'),
                    _card([
                      _switchTile(
                        icon: Icons.notifications_active_outlined,
                        title: s.isArabic ? 'تشغيل الأذان' : 'Enable Athan',
                        subtitle: s.isArabic
                            ? 'صوت الأذان عند دخول الوقت — يعمل والتطبيق مغلق'
                            : 'Athan at prayer time — works when app is closed',
                        value: s.athanEnabled,
                        onChanged: (v) {
                          s.enableAthan = v;
                          NotificationService.scheduleAll(s);
                        },
                      ),
                      _divider(),
                      ListTile(
                        leading: const Icon(Icons.notification_add_outlined,
                            color: AppColors.teal),
                        title: Text(
                            s.isArabic
                                ? 'إرسال تنبيه تجريبي الآن'
                                : 'Send a test notification now',
                            style: const TextStyle(fontSize: 13.5)),
                        subtitle: Text(
                            s.isArabic
                                ? 'يتأكد من عمل الإشعارات المجدولة'
                                : 'Verify scheduled notifications work',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                        trailing: const Icon(Icons.send_outlined,
                            size: 18, color: AppColors.gold),
                        onTap: () async {
                          await NotificationService.testNow(s);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  s.isArabic
                                      ? 'سيصلك تنبيه تجريبي بعد ٣ ثوانٍ'
                                      : 'A test notification arrives in 3s',
                                  style:
                                      const TextStyle(fontFamily: 'Cairo'))));
                        },
                      ),
                      _divider(),
                      ListTile(
                        leading: const Icon(Icons.battery_charging_full_outlined,
                            color: AppColors.gold),
                        title: Text(
                            s.isArabic
                                ? 'دقة الأذان في الخلفية وتحسين البطارية'
                                : 'Background Athan & Battery Optimization',
                            style: const TextStyle(fontSize: 13.5)),
                        subtitle: Text(
                            s.isArabic
                                ? 'إرشادات لهواتف سامسونج، شاومي، وهواوي'
                                : 'Guides for Samsung, Xiaomi & Huawei',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                        trailing: const Icon(Icons.info_outline,
                            size: 18, color: AppColors.teal),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppColors.nightLight,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: const BorderSide(color: Color(0x3314B8A6))),
                              title: Row(
                                children: [
                                  const Icon(Icons.battery_saver, color: AppColors.gold),
                                  const SizedBox(width: 8),
                                  Text(s.isArabic ? 'ضمان دقة الأذان' : 'Athan Reliability',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Cairo')),
                                ],
                              ),
                              content: Text(
                                s.isArabic
                                    ? 'لضمان انطلاق صوت الأذان في موعده بدقة والتطبيق مغلق:\n\n'
                                      '1. ادخل إلى إعدادات الهاتف ← التطبيقات ← صلاتي.\n'
                                      '2. اختر "البطارية" وحوّلها إلى "غير مقيد" (Unrestricted).\n'
                                      '3. لهواتف شاومي: فعّل "التشغيل التلقائي" (Autostart).\n'
                                      '4. تأكد من تفعيل إذن "المنبهات والتذكيرات الدقيقة" (Exact Alarms).'
                                    : 'To ensure Athan fires on time when the app is closed:\n\n'
                                      '1. Go to Settings → Apps → Salati.\n'
                                      '2. Set Battery usage to "Unrestricted".\n'
                                      '3. For Xiaomi: Enable "Autostart".\n'
                                      '4. Allow "Alarms & Reminders" permission.',
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textPrimary,
                                    height: 1.6,
                                    fontFamily: 'Cairo'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(s.isArabic ? 'حسناً، فهمت' : 'Got it',
                                      style: const TextStyle(
                                          color: AppColors.teal,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Cairo')),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      _divider(),
                      ListTile(
                        leading: const Icon(Icons.music_note,
                            color: AppColors.gold),
                        title: Text(s.isArabic ? 'صوت الأذان' : 'Athan sound',
                            style: const TextStyle(fontSize: 13.5)),
                        subtitle: Text(_soundName(s.athanSound, s.isArabic),
                            style: const TextStyle(
                                fontSize: 11.5, color: AppColors.gold)),
                        trailing: const Icon(Icons.expand_more,
                            size: 20, color: AppColors.textMuted),
                        onTap: () => _pickSound(context, s, athan),
                      ),
                      _divider(),
                      _sliderTile(context,
                        icon: Icons.volume_up_outlined,
                        title: s.isArabic ? 'مستوى الصوت' : 'Volume',
                        value: s.athanVolume,
                        min: 0,
                        max: 1,
                        label: '${(s.athanVolume * 100).round()}%',
                        onChanged: (v) => s.volume = v,
                      ),
                      _divider(),
                      ExpansionTile(
                        leading: const Icon(Icons.notifications_paused_outlined,
                            color: AppColors.teal),
                        title: Text(
                            s.isArabic
                                ? 'التنبيهات الاستباقية لكل صلاة'
                                : 'Per-prayer proactive alerts',
                            style: const TextStyle(fontSize: 13.5)),
                        subtitle: Text(
                            s.isArabic
                                ? 'تخصيص دقائق التنبيه قبل الأذان لكل صلاة'
                                : 'Customize reminder minutes before each athan',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                        children: [
                          for (final key in const ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'])
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 65,
                                    child: Text(
                                      s.isArabic
                                          ? PrayerCalculator.arNames[key]!
                                          : PrayerCalculator.enNames[key]!,
                                      style: const TextStyle(fontSize: 12.5),
                                    ),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: (s.preAthanMinutesFor(key)).toDouble(),
                                      min: 0,
                                      max: key == 'fajr' ? 60 : 30,
                                      divisions: key == 'fajr' ? 12 : 6,
                                      activeColor: AppColors.teal,
                                      inactiveColor: const Color(0x3314B8A6),
                                      onChanged: (v) {
                                        s.setPreAthanForPrayer(key, v.round());
                                        NotificationService.scheduleAll(s);
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: 48,
                                    child: Text(
                                      s.preAthanMinutesFor(key) == 0
                                          ? (s.isArabic ? 'معطّل' : 'Off')
                                          : '${s.preAthanMinutesFor(key)} ${s.isArabic ? 'د' : 'm'}',
                                      textAlign: TextAlign.end,
                                      style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: s.preAthanMinutesFor(key) == 0
                                              ? AppColors.textMuted
                                              : AppColors.gold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 6),
                        ],
                      ),
                      _divider(),
                      _switchTile(
                        icon: Icons.vibration,
                        title: s.isArabic ? 'الاهتزاز' : 'Vibration',
                        subtitle: s.isArabic
                            ? 'اهتزاز الجهاز مع التنبيه'
                            : 'Vibrate on reminders',
                        value: s.vibrate,
                        onChanged: (v) => s.doVibrate = v,
                      ),
                    ]),

                    _section(s.isArabic ? 'الأذكار العائمة والصلاة على النبي ﷺ' : 'Floating Azkar & Salawat Reminder'),
                    _card([
                      _switchTile(
                        icon: Icons.chat_bubble_outline,
                        title: s.isArabic ? 'الأذكار العائمة على الشاشة' : 'Floating Azkar Notifications',
                        subtitle: s.isArabic
                            ? 'ظهور نافذة عائمة تحتوي أذكاراً مأثورة دورياً'
                            : 'Floating bubble displaying periodic authentic azkar',
                        value: s.floatingAzkarEnabled,
                        onChanged: (v) => s.enableFloatingAzkar = v,
                      ),
                      if (s.floatingAzkarEnabled) ...[
                        _divider(),
                        _sliderTile(context,
                          icon: Icons.timer_outlined,
                          title: s.isArabic
                              ? 'تكرار ظهور الأذكار العائمة (دقيقة)'
                              : 'Floating azkar interval (min)',
                          value: s.floatingAzkarIntervalMinutes.toDouble(),
                          min: 5,
                          max: 60,
                          label: '${s.floatingAzkarIntervalMinutes}',
                          onChanged: (v) => s.floatingInterval = v.round(),
                        ),
                      ],
                      _divider(),
                      _switchTile(
                        icon: Icons.volume_up,
                        title: s.isArabic ? 'التنبيه الصوتي: صلِّ على محمّد ﷺ' : 'Audio Reminder: Blessings upon Muhammad ﷺ',
                        subtitle: s.isArabic
                            ? 'تنبيه صوتي دوري بالصلاة على النبي ﷺ كل زمن محدد'
                            : 'Periodic audio reminder to send blessings upon the Prophet ﷺ',
                        value: s.salawatAudioReminderEnabled,
                        onChanged: (v) {
                          s.enableSalawat = v;
                          NotificationService.scheduleAll(s);
                        },
                      ),
                      if (s.salawatAudioReminderEnabled) ...[
                        _divider(),
                        _sliderTile(context,
                          icon: Icons.schedule,
                          title: s.isArabic
                              ? 'الفترة الزمنية بين التنبيهات (دقيقة)'
                              : 'Salawat reminder interval (min)',
                          value: s.salawatIntervalMinutes.toDouble(),
                          min: 15,
                          max: 120,
                          label: '${s.salawatIntervalMinutes}',
                          onChanged: (v) {
                            s.salawatInterval = v.round();
                            NotificationService.scheduleAll(s);
                          },
                        ),
                        _divider(),
                        ListTile(
                          leading: const Icon(Icons.play_circle_outline, color: AppColors.gold),
                          title: Text(
                            s.isArabic ? 'تجربة صوت "صلّ على محمد" الآن' : 'Test "Salawat" Voice Now',
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: Text(
                            s.isArabic
                                ? 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ'
                                : 'Allahumma salli wa sallim ala Muhammad',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          trailing: const Icon(Icons.volume_up_outlined, size: 18, color: AppColors.teal),
                          onTap: () async {
                            await athan.playNotification();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                s.isArabic
                                    ? 'اللَّهُمَّ صَلِّ وَسَلِّمْ وَبَارِكْ عَلَى نَبِيِّنَا مُحَمَّدٍ ﷺ'
                                    : 'Blessings upon Muhammad ﷺ',
                                style: const TextStyle(fontFamily: 'Cairo'),
                              ),
                            ));
                          },
                        ),
                      ],
                    ]),

                    _section(s.isArabic ? 'عن التطبيق' : 'About'),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      radius: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const AppLogo(size: 46),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      s.isArabic
                                          ? 'مواقيت الصلاة والأذان'
                                          : 'Prayer Now',
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700)),
                                  const Text('v1.0.0',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            s.isArabic
                                ? 'تطبيق إسلامي شامل: مواقيت الصلاة بدقة فلكية بدون إنترنت، الأذان، اتجاه القبلة، القرآن الكريم كاملًا، الأذكار والأدعية، أسماء الله الحسنى، السبحة الإلكترونية والتقويم الهجري.'
                                : 'A complete Islamic app: astronomically accurate offline prayer times, athan, qibla direction, full Quran, azkar & duas, 99 names of Allah, digital tasbih and Hijri calendar.',
                            style: const TextStyle(
                                fontSize: 11.5,
                                height: 1.7,
                                color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _soundName(String id, bool ar) {
    switch (id) {
      case 'madinah':
        return ar ? 'أذان الحرم المدني' : 'Madinah Haram';
      case 'alafasy':
        return ar ? 'مشاري راشد العفاسي' : 'Mishary Alafasy';
      default:
        return ar ? 'أذان الحرم المكي' : 'Makkah Haram';
    }
  }

  Widget _section(String title) => SectionTitle(title);

  Widget _divider() => const Divider(height: 1, color: Color(0x14FFFFFF));

  Widget _card(List<Widget> children) => GlassCard(
        padding: EdgeInsets.zero,
        radius: 18,
        child: Column(children: children),
      );

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      SwitchListTile(
        value: value,
        activeColor: AppColors.teal,
        onChanged: onChanged,
        secondary: Icon(icon, color: AppColors.gold, size: 21),
        title: Text(title, style: const TextStyle(fontSize: 13.5)),
        subtitle: Text(subtitle,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      );

  Widget _sliderTile(BuildContext context, {
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    required String label,
    required ValueChanged<double> onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 4),
        child: Row(
          children: [
            Icon(icon, color: AppColors.gold, size: 21),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text(title,
                              style: const TextStyle(fontSize: 13))),
                      Text(label,
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.teal)),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 7),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: AppColors.teal,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: AppColors.teal,
                    ),
                    child: Slider(
                      value: value.clamp(min, max),
                      min: min,
                      max: max,
                      onChanged: onChanged,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  void _pickMethod(BuildContext context, SettingsProvider s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            for (final m in PrayerMethod.values)
              RadioListTile<PrayerMethod>(
                value: m,
                groupValue: s.method,
                activeColor: AppColors.teal,
                title: Text(m.label(s.isArabic),
                    style: const TextStyle(fontSize: 13.5)),
                subtitle: Text(
                    'Fajr ${m.fajrAngle}° • Isha ${m.ishaAngle != null ? "${m.ishaAngle}°" : "${m.ishaMinutes} min"}',
                    style: const TextStyle(
                        fontSize: 10.5, color: AppColors.textMuted)),
                onChanged: (v) {
                  if (v != null) s.methodName = v;
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _pickSound(
      BuildContext context, SettingsProvider s, AthanService athan) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(s.isArabic ? 'اختر صوت الأذان' : 'Choose athan',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              for (final e in [
                ('makkah', s.isArabic ? 'أذان الحرم المكي' : 'Makkah Haram'),
                ('madinah', s.isArabic ? 'أذان الحرم المدني' : 'Madinah Haram'),
                ('alafasy', s.isArabic ? 'مشاري راشد العفاسي' : 'Mishary Alafasy'),
              ])
                RadioListTile<String>(
                  value: e.$1,
                  groupValue: s.athanSound,
                  activeColor: AppColors.teal,
                  title: Text(e.$2, style: const TextStyle(fontSize: 13.5)),
                  secondary: IconButton(
                    icon: const Icon(Icons.play_circle_outline,
                        color: AppColors.gold),
                    onPressed: () => athan.preview(e.$1),
                  ),
                  onChanged: (v) {
                    if (v != null) s.sound = v;
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
