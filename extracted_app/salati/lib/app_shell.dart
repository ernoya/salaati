import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import 'screens/home_screen.dart';
import 'screens/quran_screen.dart';
import 'screens/azkar_screen.dart';
import 'screens/tasbih_screen.dart';
import 'screens/qibla_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  final _pages = const [
    HomeScreen(),
    QuranScreen(),
    AzkarScreen(),
    TasbihScreen(),
    QiblaScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    final labels = s.isArabic
        ? ['الرئيسية', 'القرآن', 'الأذكار', 'السبحة', 'القبلة']
        : ['Home', 'Quran', 'Azkar', 'Tasbih', 'Qibla'];
    const icons = [
      Icons.home_outlined,
      Icons.menu_book_outlined,
      Icons.auto_stories_outlined,
      Icons.timer_outlined,
      Icons.explore_outlined
    ];
    const activeIcons = [
      Icons.home,
      Icons.menu_book,
      Icons.auto_stories,
      Icons.timer,
      Icons.explore
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: index, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.nightLight.withOpacity(0.96),
          border: const Border(top: BorderSide(color: Color(0x1AFFFFFF))),
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 20, offset: Offset(0, -4))
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => index = i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: index == i
                                  ? AppColors.teal.withOpacity(0.16)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Icon(
                              index == i ? activeIcons[i] : icons[i],
                              size: 21,
                              color: index == i
                                  ? AppColors.teal
                                  : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            labels[i],
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 9.5,
                              fontWeight: index == i
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: index == i
                                  ? AppColors.teal
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
