@Tags(['screenshot'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:balance/core/presentation/theme/app_theme.dart';
import 'package:balance/features/weight/domain/bmi_category.dart';
import 'package:balance/features/weight/presentation/utils/bmi_category_localizer.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'helpers/screenshot_test_helper.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final effectiveLocales = getEffectiveLocales();
  final prefix = getScreenshotPrefix();

  setUpAll(() async {
    await binding.convertFlutterSurfaceToImage();
  });

  group('07_home_widgets Screenshot Generator', () {
    for (final localeCode in effectiveLocales) {
      for (final isDark in [false, true]) {
        final themeLabel = isDark ? 'dark' : 'light';
        final theme = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
        final themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
        final locale = Locale(localeCode);

        // 07_home_widgets / 01_widget_2x1
        testWidgets(
          'Capture 07_home_widgets/01_widget_2x1 [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              MaterialApp(
                debugShowCheckedModeBanner: false,
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                theme: theme,
                themeMode: themeMode,
                home: ScreenshotDeviceFrame(
                  isDark: isDark,
                  child: Scaffold(
                    body: WidgetPreviewCanvas(
                      title: 'Widget 2 × 1',
                      isDark: isDark,
                      child: HomeWidget2x1View(
                        currentWeight: 87.0,
                        unit: 'kg',
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),
              ),
            );

            await tester.pumpAndSettle();

            await binding.takeScreenshot(
              '$prefix$localeCode/07_home_widgets/01_widget_2x1_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // 07_home_widgets / 02_widget_3x2
        testWidgets(
          'Capture 07_home_widgets/02_widget_3x2 [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              MaterialApp(
                debugShowCheckedModeBanner: false,
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                theme: theme,
                themeMode: themeMode,
                home: ScreenshotDeviceFrame(
                  isDark: isDark,
                  child: Scaffold(
                    body: WidgetPreviewCanvas(
                      title: 'Widget 3 × 2',
                      isDark: isDark,
                      child: HomeWidget3x2View(
                        currentWeight: 87.0,
                        targetWeight: 85.0,
                        delta: -0.2,
                        unit: 'kg',
                        bmiCategory: BmiCategory.overweight,
                        bmiValue: 27.8,
                        goalProgressPct: 73,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),
              ),
            );

            await tester.pumpAndSettle();

            await binding.takeScreenshot(
              '$prefix$localeCode/07_home_widgets/02_widget_3x2_$themeLabel',
            );
          },
          tags: 'screenshot',
        );
      }
    }
  });
}

/// Canvas wrapper to present home widgets cleanly in screenshots.
class WidgetPreviewCanvas extends StatelessWidget {
  final Widget child;
  final String title;
  final bool isDark;

  const WidgetPreviewCanvas({
    super.key,
    required this.child,
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F1117), Color(0xFF141721), Color(0xFF1A1D29)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE9EEF5), Color(0xFFF3F6FA), Color(0xFFE3E9F2)],
          );

    return DecoratedBox(
      decoration: BoxDecoration(gradient: bgGradient),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark
                      ? const Color(0xFFC4C7D0)
                      : const Color(0xFF555B68),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// Visual representation of the compact 2x1 home screen widget.
class HomeWidget2x1View extends StatelessWidget {
  final double currentWeight;
  final String unit;
  final bool isDark;

  const HomeWidget2x1View({
    super.key,
    required this.currentWeight,
    required this.unit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cardBg = isDark ? const Color(0xFF1E2128) : const Color(0xFFFFFFFF);
    final borderColor = isDark
        ? const Color(0xFF2E333D)
        : const Color(0xFFE2E4E9);
    final textHeader = isDark
        ? const Color(0xFFC4C7D0)
        : const Color(0xFF44474F);
    final primaryBlue = isDark
        ? const Color(0xFFA8C7FA)
        : const Color(0xFF005BDE);
    final buttonBg = isDark ? const Color(0xFF2A3140) : const Color(0xFFE8F0FE);
    final buttonIconColor = isDark
        ? const Color(0xFFA8C7FA)
        : const Color(0xFF005BDE);

    return Container(
      width: 336,
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Balance • ${l10n.today}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textHeader,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      currentWeight.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: primaryBlue,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textHeader,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: buttonBg, shape: BoxShape.circle),
            child: Icon(Icons.add, color: buttonIconColor, size: 20),
          ),
        ],
      ),
    );
  }
}

/// Visual representation of the full 3x2 home screen widget.
class HomeWidget3x2View extends StatelessWidget {
  final double currentWeight;
  final double targetWeight;
  final double delta;
  final String unit;
  final BmiCategory bmiCategory;
  final double bmiValue;
  final int goalProgressPct;
  final bool isDark;

  const HomeWidget3x2View({
    super.key,
    required this.currentWeight,
    required this.targetWeight,
    required this.delta,
    required this.unit,
    required this.bmiCategory,
    required this.bmiValue,
    required this.goalProgressPct,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cardBg = isDark ? const Color(0xFF1E2128) : const Color(0xFFFFFFFF);
    final borderColor = isDark
        ? const Color(0xFF2E333D)
        : const Color(0xFFE2E4E9);
    final textHeader = isDark
        ? const Color(0xFFC4C7D0)
        : const Color(0xFF44474F);
    final primaryBlue = isDark
        ? const Color(0xFFA8C7FA)
        : const Color(0xFF005BDE);
    final progressBg = isDark
        ? const Color(0xFF2E333D)
        : const Color(0xFFE5E7EB);

    final isLoss = delta <= 0;
    final chipBg = isLoss
        ? (isDark ? const Color(0xFF1B3B1E) : const Color(0xFFE8F5E9))
        : (isDark ? const Color(0xFF3E2723) : const Color(0xFFFFEBEE));
    final chipTextColor = isLoss
        ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
        : (isDark ? const Color(0xFFE57373) : const Color(0xFFC62828));

    final bmiBg = isDark ? const Color(0xFF3E2E1E) : const Color(0xFFFFF3E0);
    final bmiTextColor = isDark
        ? const Color(0xFFFFB74D)
        : const Color(0xFFEF6C00);

    final deltaStr = isLoss
        ? '${delta.toStringAsFixed(1)} $unit'
        : '+${delta.toStringAsFixed(1)} $unit';

    return Container(
      width: 348,
      height: 168,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Balance • ${l10n.today}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textHeader,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          currentWeight.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: primaryBlue,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          unit,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textHeader,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: chipBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            deltaStr,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: chipTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.today}, 08:30',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: textHeader.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: bmiBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      bmiCategory.localizedName(l10n),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: bmiTextColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'BMI ${bmiValue.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: bmiTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${l10n.chartTargetLabel}: ${targetWeight.toStringAsFixed(1)} $unit',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: textHeader,
                    ),
                  ),
                  Text(
                    '$goalProgressPct%',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 6,
                  width: double.infinity,
                  color: progressBg,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (goalProgressPct / 100.0).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
