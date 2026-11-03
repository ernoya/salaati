import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../core/prayer_calculator.dart';
import '../core/settings.dart';

/// جدولة تنبيهات الأذان داخل التطبيق + تشغيل الصوت
class AthanService extends ChangeNotifier {
  AthanService(this.settings);
  final SettingsProvider settings;

  final AudioPlayer _player = AudioPlayer();
  Timer? _ticker;
  String? _playingKey;
  bool _isPlaying = false;
  DateTime? _lastFired;
  String? firingPrayer;

  bool get isPlaying => _isPlaying;
  String? get playingKey => _playingKey;

  void start() {
    _ticker?.cancel();
    _player.setReleaseMode(ReleaseMode.stop);

    // ضبط Audio Focus و AudioContext لمنع التداخل مع المكالمات وتخفيض الصوت مؤقتاً
    AudioPlayer.global.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {
            AVAudioSessionOptions.duckOthers,
          },
        ),
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ),
    );

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _check());
  }

  void _check() {
    if (!settings.athanEnabled) return;
    final now = DateTime.now();
    final times = settings.timesFor(now);
    for (final key in PrayerCalculator.keys) {
      if (key == 'sunrise') continue;
      final t = times[key];
      if (t == null) continue;
      final diff = now.difference(t).inSeconds;
      // نافذة 3 ثوانٍ حول وقت الأذان
      if (diff >= 0 && diff < 3) {
        final stamp = DateTime(t.year, t.month, t.day, t.hour, t.minute);
        if (_lastFired == stamp) continue;
        _lastFired = stamp;
        playAthan(key);
        return;
      }
      final pre = settings.preAthanMinutesFor(key);
      if (pre > 0) {
        final preDiff = t.difference(now).inSeconds;
        if (preDiff >= pre * 60 && preDiff < pre * 60 + 3) {
          playNotification();
        }
      }
    }
  }

  Future<void> playAthan(String prayerKey) async {
    firingPrayer = prayerKey;
    final file = settings.athanSound == 'madinah'
        ? 'audio/athan_madina.mp3'
        : settings.athanSound == 'alafasy'
            ? 'audio/athan_alafasy.mp3'
            : 'audio/athan_makkah.mp3';
    await _player.setVolume(settings.athanVolume);
    await _player.stop();
    await _player.play(AssetSource(file));
    _isPlaying = true;
    _playingKey = prayerKey;
    notifyListeners();
    _player.onPlayerComplete.first.then((_) {
      _isPlaying = false;
      _playingKey = null;
      firingPrayer = null;
      notifyListeners();
    });
  }

  Future<void> playNotification() async {
    await _player.setVolume(settings.athanVolume);
    await _player.play(AssetSource('audio/notification.wav'));
  }

  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _playingKey = null;
    firingPrayer = null;
    notifyListeners();
  }

  /// تجربة الصوت من الإعدادات
  Future<void> preview(String sound) async {
    final old = settings.athanSound;
    settings.sound = sound;
    await playAthan('fajr');
    settings.sound = old;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _player.dispose();
    super.dispose();
  }
}
