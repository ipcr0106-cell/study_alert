import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../navigation/post_auth_navigation.dart';
import '../services/supabase_service.dart';
import '../theme/auth_ui_colors.dart';
import '../widgets/auth_social_login_tile.dart';
import '../widgets/google_brand_icon.dart';
import 'login_methods_screen.dart';

// 링크 행 스타일 (prefer_const_constructors 대응)
const _policyLinkStyle = TextStyle(
  fontSize: 13,
  color: AuthUiColors.footerGray,
  decoration: TextDecoration.underline,
  decorationColor: AuthUiColors.footerGray,
);

const _policyDotStyle = TextStyle(color: AuthUiColors.footerGray);

/// 약관 동의 후 회원가입 수단 (현재 구글만)
class SignupMethodsScreen extends StatefulWidget {
  const SignupMethodsScreen({super.key});

  @override
  State<SignupMethodsScreen> createState() => _SignupMethodsScreenState();
}

class _SignupMethodsScreenState extends State<SignupMethodsScreen> {
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = SupabaseService.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn && mounted) {
        await PostAuthNavigator.go(context);
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  void _showPolicySheet(String title) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: MediaQuery.paddingOf(ctx).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                '추후 정책 페이지 URL로 연결할 수 있습니다.',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _signUpWithGoogle() async {
    try {
      await SupabaseService.signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('가입 진행 실패: $e')),
      );
    }
  }

  void _goToLoginFlow() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const LoginMethodsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '가입하기',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            AuthSocialLoginTile(
              icon: const GoogleBrandIcon(size: 24),
              label: '구글로 시작하기',
              onTap: _signUpWithGoogle,
            ),
            const SizedBox(height: 28),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => _showPolicySheet('개인정보 처리방침'),
                    child: const Text('개인정보 처리방침', style: _policyLinkStyle),
                  ),
                  const Text(' · ', style: _policyDotStyle),
                  TextButton(
                    onPressed: () => _showPolicySheet('이용약관'),
                    child: const Text('이용약관', style: _policyLinkStyle),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.center,
                children: [
                  Text(
                    '이미 계정이 있나요? ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  GestureDetector(
                    onTap: _goToLoginFlow,
                    child: Text(
                      '로그인',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
