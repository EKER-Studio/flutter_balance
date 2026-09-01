import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:balance/core/presentation/theme/app_layout_tokens.dart';
import 'package:balance/core/presentation/widgets/clamped_layout.dart';
import 'package:balance/l10n/app_localizations.dart';

/// Aggregated package license entry holding the package name and its license texts.
class PackageLicense {
  final String packageName;
  final List<String> paragraphs;

  const PackageLicense({required this.packageName, required this.paragraphs});
}

/// A native, offline-accessible screen displaying open-source software licenses.
class LicensesScreen extends StatefulWidget {
  final PackageInfo? packageInfo;

  const LicensesScreen({super.key, this.packageInfo});

  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends State<LicensesScreen> {
  late final Future<PackageInfo> _packageInfoFuture;
  late final Future<List<PackageLicense>> _licensesFuture;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = widget.packageInfo != null
        ? Future.value(widget.packageInfo!)
        : PackageInfo.fromPlatform();
    _licensesFuture = _loadLicenses();
  }

  static Future<List<PackageLicense>> _loadLicenses() async {
    final packageMap = <String, List<String>>{};

    await for (final entry in LicenseRegistry.licenses) {
      final text = entry.paragraphs.map((p) => p.text).join('\n\n');
      for (final package in entry.packages) {
        packageMap.putIfAbsent(package, () => []).add(text);
      }
    }

    final sortedKeys = packageMap.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return sortedKeys
        .map(
          (pkg) =>
              PackageLicense(packageName: pkg, paragraphs: packageMap[pkg]!),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.openSourceLicenses), centerTitle: false),
      body: SafeArea(
        child: ClampedLayout(
          maxWidth: AppLayoutTokens.maxSingleColumnContentWidth,
          child: FutureBuilder<List<dynamic>>(
            future: Future.wait([_packageInfoFuture, _licensesFuture]),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                final packageInfo = snapshot.data?[0] as PackageInfo?;
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeaderCard(
                          context,
                          version: packageInfo?.version ?? '',
                          licenseCount: null,
                          isDark: isDark,
                          colorScheme: colorScheme,
                          theme: theme,
                          l10n: l10n,
                        ),
                        const SizedBox(height: 24),
                        const CircularProgressIndicator(),
                      ],
                    ),
                  ),
                );
              }

              final packageInfo = snapshot.data![0] as PackageInfo;
              final licenses = snapshot.data![1] as List<PackageLicense>;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                itemCount: licenses.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildHeaderCard(
                        context,
                        version: packageInfo.version,
                        licenseCount: licenses.length,
                        isDark: isDark,
                        colorScheme: colorScheme,
                        theme: theme,
                        l10n: l10n,
                      ),
                    );
                  }

                  final item = licenses[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      color: colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                        shape: const Border(),
                        collapsedShape: const Border(),
                        title: Text(
                          item.packageName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          '${item.paragraphs.length} ${item.paragraphs.length == 1 ? "licencja" : "licencje"}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            child: SelectableText(
                              item.paragraphs.join('\n\n---\n\n'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                color: colorScheme.onSurfaceVariant,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context, {
    required String version,
    required int? licenseCount,
    required bool isDark,
    required ColorScheme colorScheme,
    required ThemeData theme,
    required AppLocalizations l10n,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: isDark
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : colorScheme.primaryContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.monitor_weight_outlined,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Balance',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (version.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'v$version',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  '© 2026 EKER Studio',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Powered by Flutter',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (licenseCount != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$licenseCount open-source packages',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
