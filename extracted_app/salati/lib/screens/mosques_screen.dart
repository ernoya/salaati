import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/settings.dart';
import '../core/theme.dart';

class Mosque {
  final String name;
  final double lat;
  final double lng;
  final String city;
  const Mosque(this.name, this.lat, this.lng, this.city);

  double distanceFrom(double la, double ln) {
    const r = 6371.0;
    final dLat = (lat - la) * math.pi / 180;
    final dLng = (lng - ln) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(la * math.pi / 180) *
            math.cos(lat * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * r * math.asin(math.sqrt(a));
  }
}

/// قائمة مساجد شهيرة تُستخدم كبديل عند تعذر الوصول لخدمات الخرائط
const List<Mosque> famousMosques = [
  Mosque('المسجد الحرام', 21.4225, 39.8262, 'مكة المكرمة'),
  Mosque('المسجد النبوي', 24.4672, 39.6111, 'المدينة المنورة'),
  Mosque('المسجد الأقصى', 31.7781, 35.2354, 'القدس'),
  Mosque('مسجد قباء', 24.4392, 39.6172, 'المدينة المنورة'),
  Mosque('مسجد السلطان حسن', 30.0360, 31.2609, 'القاهرة'),
  Mosque('مسجد الأزهر', 30.0459, 31.2626, 'القاهرة'),
  Mosque('مسجد محمد علي بالقلعة', 30.0287, 31.2600, 'القاهرة'),
  Mosque('مسجد عمرو بن العاص', 30.0100, 31.2333, 'القاهرة'),
  Mosque('مسجد الحسين', 30.0483, 31.2637, 'القاهرة'),
  Mosque('مسجد السيدة زينب', 30.0317, 31.2400, 'القاهرة'),
  Mosque('مسجد النور', 30.0526, 31.2231, 'الجيزة'),
  Mosque('جامع الشيخ زايد الكبير', 24.4129, 54.4748, 'أبوظبي'),
  Mosque('مسجد الملك الحسين', 31.9559, 35.8656, 'عمّان'),
  Mosque('مسجد الحسن الثاني', 33.6086, -7.6325, 'الدار البيضاء'),
];

class MosquesScreen extends StatefulWidget {
  const MosquesScreen({super.key});

  @override
  State<MosquesScreen> createState() => _MosquesScreenState();
}

class _MosquesScreenState extends State<MosquesScreen> {
  List<Mosque> nearby = [];
  bool loading = true;
  String source = 'local';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final s = context.read<SettingsProvider>();
    // محاولة جلب مساجد قريبة من Overpass API (OpenStreetMap)
    try {
      final client = HttpClient();
      final query = '''
[out:json][timeout:12];
node["amenity"="place_of_worship"]["religion"="muslim"](around:4000,${s.latitude},${s.longitude});
out body 30;
''';
      final uri = Uri.parse('https://overpass-api.de/api/interpreter');
      final req = await client.postUrl(uri)
        ..headers.contentType = ContentType.text
        ..write(query);
      final res = await req.close().timeout(const Duration(seconds: 14));
      final body = await res.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final elements = (data['elements'] as List?) ?? [];
      final list = <Mosque>[];
      for (final e in elements) {
        final m = e as Map<String, dynamic>;
        final tags = (m['tags'] as Map?) ?? {};
        final name = (tags['name:ar'] ?? tags['name'] ?? 'مسجد').toString();
        list.add(Mosque(name, (m['lat'] as num).toDouble(),
            (m['lon'] as num).toDouble(), s.city));
      }
      list.sort((a, b) => a
          .distanceFrom(s.latitude, s.longitude)
          .compareTo(b.distanceFrom(s.latitude, s.longitude)));
      if (mounted) {
        setState(() {
          nearby = list;
          loading = false;
          source = 'osm';
        });
      }
      return;
    } catch (_) {
      // تجاهل واستخدام القائمة المحلية
    }
    final local = [...famousMosques]
      ..sort((a, b) => a
          .distanceFrom(s.latitude, s.longitude)
          .compareTo(b.distanceFrom(s.latitude, s.longitude)));
    if (mounted) {
      setState(() {
        nearby = local;
        loading = false;
        source = 'local';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    return Scaffold(
      body: GradientScaffold(
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: Text(s.isArabic ? 'أقرب المساجد' : 'Nearby Mosques'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: () {
                      setState(() => loading = true);
                      _load();
                    },
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.my_location, size: 14, color: AppColors.teal),
                    const SizedBox(width: 6),
                    Text(s.city,
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(
                        source == 'osm'
                            ? (s.isArabic ? 'من الخريطة المفتوحة' : 'OpenStreetMap')
                            : (s.isArabic ? 'قائمة مساجد شهيرة' : 'Famous mosques'),
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _mapCard(s),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.gold))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        itemCount: nearby.length > 12 ? 12 : nearby.length,
                        itemBuilder: (context, i) {
                          final m = nearby[i];
                          final km = m.distanceFrom(s.latitude, s.longitude);
                          final walk = (km / 5 * 60).round();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: GlassCard(
                              padding: const EdgeInsets.all(14),
                              radius: 16,
                              onTap: () => _openMaps(m),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.teal.withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.mosque,
                                        color: AppColors.teal, size: 21),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(m.name,
                                            style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${km.toStringAsFixed(km < 1 ? 2 : 1)} ${s.isArabic ? "كم" : "km"} • ${s.isArabic ? "مشيًا" : "walk"} $walk ${s.isArabic ? "دقيقة" : "min"}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.directions_outlined,
                                      size: 20, color: AppColors.gold),
                                ],
                              ),
                            ),
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

  /// بطاقة خريطة مصغّرة (مرسومة برمجيًا — تعمل بدون إنترنت)
  Widget _mapCard(SettingsProvider s) {
    return Container(
      height: 118,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x22FFFFFF)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2A36), Color(0xFF123948)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _MiniMapPainter()),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.teal.withOpacity(0.5),
                            blurRadius: 18)
                      ],
                    ),
                    child: const Icon(Icons.my_location,
                        size: 16, color: AppColors.night),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xCC07131A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s.isArabic ? 'موقعك الحالي' : 'Your location',
                      style: const TextStyle(
                          fontSize: 10.5, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 10,
              child: Text(
                '≈ ${nearby.isEmpty ? 0 : (nearby.first.distanceFrom(s.latitude, s.longitude)).toStringAsFixed(1)} ${s.isArabic ? "كم" : "km"}',
                style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMaps(Mosque m) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${m.lat},${m.lng}&travelmode=walking';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم نسخ رابط الاتجاهات',
                style: TextStyle(fontFamily: 'Cairo'))));
      }
    }
  }
}

/// رسم شبكة طرق مبسطة لخلفية الخريطة
class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = const Color(0x1AFFFFFF)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    final thin = Paint()
      ..color = const Color(0x12FFFFFF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 12), thin);
    }
    for (var i = 1; i < 6; i++) {
      final x = size.width * i / 6;
      canvas.drawLine(Offset(x, 0), Offset(x - 16, size.height), thin);
    }
    // طريق رئيسي
    final p = Path()
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.45,
          size.width * 0.65, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.62, size.width,
          size.height * 0.35);
    canvas.drawPath(p, road);
    // مساحات خضراء
    final park = Paint()..color = const Color(0x1A14C4A6);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.05, size.height * 0.08,
                size.width * 0.18, size.height * 0.25),
            const Radius.circular(8)),
        park);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.72, size.height * 0.7,
                size.width * 0.2, size.height * 0.22),
            const Radius.circular(8)),
        park);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
