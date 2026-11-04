import 'package:flutter_test/flutter_test.dart';
import 'package:salati/core/prayer_calculator.dart';

void main() {
  test('Qibla from Cairo is ~136 degrees', () {
    expect(PrayerCalculator.qiblaDirection(30.0444, 31.2357).round(), 136);
  });

  test('Cairo prayer times are ordered and plausible', () {
    final t = PrayerCalculator.prayerTimes(
      date: DateTime(2026, 11, 3),
      latitude: 30.0444,
      longitude: 31.2357,
      method: PrayerMethod.egyptian,
      tzOffsetHours: 2,
    );

    expect(t['fajr']!.isBefore(t['sunrise']!), isTrue);
    expect(t['sunrise']!.isBefore(t['dhuhr']!), isTrue);
    expect(t['dhuhr']!.isBefore(t['asr']!), isTrue);
    expect(t['asr']!.isBefore(t['maghrib']!), isTrue);
    expect(t['maghrib']!.isBefore(t['isha']!), isTrue);

    // Cairo in early November: solar noon falls around 11:45 local time.
    expect(t['dhuhr']!.hour, inInclusiveRange(11, 12));
  });

  test('Distance from Cairo to the Kaaba is ~1300 km', () {
    final d = PrayerCalculator.distanceToKaaba(30.0444, 31.2357);
    expect(d, inInclusiveRange(1000, 1700));
  });
}
