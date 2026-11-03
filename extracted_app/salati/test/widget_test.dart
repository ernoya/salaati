import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_now/core/prayer_calculator.dart';

void main() {
  test('Cairo prayer times are correct', () {
    final t = PrayerCalculator.prayerTimes(
      date: DateTime(2026, 11, 3),
      latitude: 30.0444,
      longitude: 31.2357,
      method: PrayerMethod.egyptian,
      tzOffsetHours: 2,
    );
    expect(t['fajr']!.hour, 4);
    expect(t['dhuhr']!.hour, 11);
    expect(t['asr']!.hour, 14);
    expect(t['maghrib']!.hour, 17);
    expect(t['isha']!.hour, 18);
  });

  test('Qibla from Cairo ~136 degrees', () {
    expect(PrayerCalculator.qiblaDirection(30.0444, 31.2357).round(), 136);
  });
}
