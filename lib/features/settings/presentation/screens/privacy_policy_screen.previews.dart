import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:balance/dev/preview/preview_support.dart';
import 'package:balance/features/settings/presentation/screens/privacy_policy_screen.dart';

/// Shows the privacy policy in the light theme.
@Preview(
  name: 'Privacy Policy - Light',
  group: 'Balance Screens',
  brightness: Brightness.light,
  wrapper: lightPreviewWrapper,
)
Widget privacyPolicyScreenLightPreview() => const PrivacyPolicyScreen();

/// Shows the privacy policy in the dark theme.
@Preview(
  name: 'Privacy Policy - Dark',
  group: 'Balance Screens',
  brightness: Brightness.dark,
  wrapper: darkPreviewWrapper,
)
Widget privacyPolicyScreenDarkPreview() => const PrivacyPolicyScreen();
