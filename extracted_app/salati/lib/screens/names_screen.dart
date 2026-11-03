import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../data/azkar_data.dart';

class NamesScreen extends StatelessWidget {
  const NamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    return Scaffold(
      body: GradientScaffold(
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                  title: Text(s.isArabic
                      ? 'أسماء الله الحسنى'
                      : 'The 99 Names of Allah')),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  s.isArabic
                      ? 'وَلِلَّهِ الْأَسْمَاءُ الْحُسْنَى فَادْعُوهُ بِهَا'
                      : '"To Allah belong the most beautiful names, so call upon Him by them"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: s.isArabic ? 'AmiriQuran' : 'Cairo',
                      fontSize: s.isArabic ? 19 : 12,
                      color: AppColors.gold),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 9,
                    crossAxisSpacing: 9,
                    childAspectRatio: 1.75,
                  ),
                  itemCount: allahNames.length,
                  itemBuilder: (context, i) {
                    final n = allahNames[i];
                    return GlassCard(
                      padding: const EdgeInsets.all(10),
                      radius: 14,
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: AppColors.nightLight,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22)),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(n.ar,
                                  style: const TextStyle(
                                      fontFamily: 'AmiriQuran',
                                      fontSize: 34,
                                      color: AppColors.gold)),
                              const SizedBox(height: 12),
                              Text(n.meaning,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 13, height: 1.7)),
                            ],
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            n.ar,
                            style: const TextStyle(
                                fontFamily: 'AmiriQuran',
                                fontSize: 22,
                                color: AppColors.gold,
                                height: 1.3),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            n.meaning,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 9.5,
                                height: 1.4,
                                color: AppColors.textMuted),
                          ),
                        ],
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
}
