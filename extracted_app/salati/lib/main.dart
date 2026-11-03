import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/settings.dart';
import 'core/theme.dart';
import 'services/athan_service.dart';
import 'services/notification_service.dart';
import 'app_shell.dart';
import 'widgets/athan_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.night,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const PrayerNowBoot());
}

class PrayerNowBoot extends StatefulWidget {
  const PrayerNowBoot({super.key});

  @override
  State<PrayerNowBoot> createState() => _PrayerNowBootState();
}

class _PrayerNowBootState extends State<PrayerNowBoot> {
  final SettingsProvider _settings = SettingsProvider();
  AthanService? _athan;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _settings.load().then((_) async {
      _athan = AthanService(_settings)..start();
      await NotificationService.init();
      await NotificationService.scheduleAll(_settings);
      setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        home: const Scaffold(
          backgroundColor: AppColors.night,
          body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
        ),
      );
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _settings),
        ChangeNotifierProvider.value(value: _athan!),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, s, _) => MaterialApp(
          title: 'Prayer Now',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(),
          locale: Locale(s.isArabic ? 'ar' : 'en'),
          builder: (context, child) => Directionality(
            textDirection: s.isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: _AthanGate(child: child!),
          ),
          home: const AppShell(),
        ),
      ),
    );
  }
}

/// يراقب بدء الأذان ويعرض شاشة الأذان الكاملة
class _AthanGate extends StatelessWidget {
  final Widget child;
  const _AthanGate({required this.child});

  @override
  Widget build(BuildContext context) {
    final athan = context.watch<AthanService>();
    return Stack(
      children: [
        child,
        if (athan.isPlaying && athan.playingKey != null)
          Positioned.fill(
            child: AthanOverlay(prayerKey: athan.playingKey!),
          ),
      ],
    );
  }
}
