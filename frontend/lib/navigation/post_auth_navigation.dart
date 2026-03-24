import 'package:flutter/material.dart';

import '../models/onboarding_step.dart';
import '../services/supabase_service.dart';

/// OAuth 이후·스플래시에서 온보딩/메인으로 분기
class PostAuthNavigator {
  PostAuthNavigator._();

  static Future<void> go(BuildContext context) async {
    final step = await SupabaseService.resolveOnboardingStep();
    if (!context.mounted) return;
    final nav = Navigator.of(context);
    switch (step) {
      case OnboardingStep.needsNickname:
        nav.pushNamedAndRemoveUntil(
          '/onboarding/nickname',
          (route) => false,
        );
      case OnboardingStep.needsPermissions:
        nav.pushNamedAndRemoveUntil(
          '/onboarding/permissions',
          (route) => false,
        );
      case OnboardingStep.readyForMain:
        nav.pushNamedAndRemoveUntil('/main', (route) => false);
    }
  }
}
