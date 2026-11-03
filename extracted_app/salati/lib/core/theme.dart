import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// نظام التصميم — لوحة ألوان ليلية بلمسات ذهبية/زمردية
class AppColors {
  static const Color night = Color(0xFF07131A);
  static const Color nightLight = Color(0xFF0E2230);
  static const Color surface = Color(0xFF102B3A);
  static const Color surfaceHigh = Color(0xFF163A4C);
  static const Color teal = Color(0xFF14C4A6);
  static const Color tealDim = Color(0xFF0E8C77);
  static const Color gold = Color(0xFFE7C173);
  static const Color goldDeep = Color(0xFFC79A3F);
  static const Color textPrimary = Color(0xFFF4F8FA);
  static const Color textMuted = Color(0xFF9DB4C0);
  static const Color danger = Color(0xFFF47A7A);

  static const LinearGradient nightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF08202C), Color(0xFF061219), Color(0xFF040C11)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF3DCA4), Color(0xFFE7C173), Color(0xFFC79A3F)],
  );

  static const LinearGradient tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1BE0BE), Color(0xFF0E9C82)],
  );
}

class AppTheme {
  static ThemeData build() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.night,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.teal,
        secondary: AppColors.gold,
        surface: AppColors.surface,
        onPrimary: AppColors.night,
        onSecondary: AppColors.night,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: 'Cairo',
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: TextStyle(fontFamily: 'Cairo', color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.nightLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}

/// خلفية متدرجة مع هالات ضوئية ناعمة
class GradientScaffold extends StatelessWidget {
  final Widget child;
  final bool showGlow;
  const GradientScaffold({super.key, required this.child, this.showGlow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.nightGradient),
      child: Stack(
        children: [
          if (showGlow) ...[
            Positioned(
              top: -120,
              right: -80,
              child: _glow(const Color(0x3314C4A6), 320),
            ),
            Positioned(
              bottom: -140,
              left: -100,
              child: _glow(const Color(0x22E7C173), 360),
            ),
          ],
          child,
        ],
      ),
    );
  }

  Widget _glow(Color color, double size) => IgnorePointer(
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      );
}

/// بطاقة زجاجية
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.color,
    this.gradient,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? const Color(0x14FFFFFF)) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: border ??
            Border.all(color: const Color(0x22FFFFFF), width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionTitle(this.title, {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(color: AppColors.teal, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
