import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:balance/dev/preview/preview_support.dart';
import 'package:balance/features/settings/presentation/screens/licenses_screen.dart';

/// Shows the open-source licenses screen in the light theme.
@Preview(
  name: 'Licenses - Light',
  group: 'Balance Screens',
  brightness: Brightness.light,
  wrapper: lightPreviewWrapper,
)
Widget licensesScreenLightPreview() => _licensesScreenPreview();

/// Shows the open-source licenses screen in the dark theme.
@Preview(
  name: 'Licenses - Dark',
  group: 'Balance Screens',
  brightness: Brightness.dark,
  wrapper: darkPreviewWrapper,
)
Widget licensesScreenDarkPreview() => _licensesScreenPreview();

Widget _licensesScreenPreview() => LicensesScreen(
  packageInfo: PackageInfo(
    appName: 'Balance',
    packageName: 'com.ekerstudio.balance',
    version: '1.0.0',
    buildNumber: '1',
  ),
);
