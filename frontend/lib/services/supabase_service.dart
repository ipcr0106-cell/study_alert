import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/onboarding_step.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  static bool get isLoggedIn => currentUser != null;

  static Future<void> signInWithGoogle() async {
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.reely://login-callback/',
      // Android: 인앱 WebView 대신 외부 브라우저에서 OAuth 후 딥링크로 복귀
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  static Future<void> signInWithKakao() async {
    // 비즈앱 없이 account_email 동의를 쓸 수 없을 때: Supabase 기본 요청에 포함되는
    // account_email 때문에 KOE205가 나므로, 이메일을 제외한 scope만 명시한다.
    await client.auth.signInWithOAuth(
      OAuthProvider.kakao,
      redirectTo: 'io.supabase.reely://login-callback/',
      scopes: 'profile_nickname profile_image',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Stream<AuthState> get onAuthStateChange =>
      client.auth.onAuthStateChange;

  /// 로그인 후 닉네임·권한 온보딩 필요 여부 (profiles 테이블·RPC 적용 전이면 메인으로 폴백)
  static Future<OnboardingStep> resolveOnboardingStep() async {
    final user = currentUser;
    if (user == null) {
      return OnboardingStep.readyForMain;
    }
    try {
      final row = await client
          .from('profiles')
          .select('nickname, permissions_onboarding_done')
          .eq('id', user.id)
          .maybeSingle();
      final nick = row?['nickname'] as String?;
      if (nick == null || nick.trim().isEmpty) {
        return OnboardingStep.needsNickname;
      }
      final done = row?['permissions_onboarding_done'];
      if (done != true) {
        return OnboardingStep.needsPermissions;
      }
      return OnboardingStep.readyForMain;
    } on PostgrestException catch (e) {
      debugPrint('resolveOnboardingStep: $e');
      return OnboardingStep.readyForMain;
    }
  }

  /// 닉네임이 다른 사용자와 겹치지 않는지 (Supabase RPC)
  static Future<bool> isNicknameAvailable(String raw) async {
    final nick = raw.trim();
    if (nick.isEmpty) return false;
    final res = await client.rpc(
      'is_nickname_available',
      params: {'p_nickname': nick},
    );
    return res == true;
  }

  /// 닉네임 저장 (신규 insert 또는 기존 행 update)
  static Future<void> saveNickname(String raw) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('로그인된 사용자만 닉네임을 저장할 수 있습니다.');
    }
    final nick = raw.trim();
    if (nick.isEmpty) {
      throw ArgumentError('닉네임을 입력해 주세요.');
    }
    final existing = await client
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();
    if (existing == null) {
      await client.from('profiles').insert({
        'id': user.id,
        'nickname': nick,
        'permissions_onboarding_done': false,
      });
    } else {
      await client.from('profiles').update({'nickname': nick}).eq('id', user.id);
    }
  }

  /// 권한 온보딩 완료 플래그
  static Future<void> markPermissionsOnboardingDone() async {
    final user = currentUser;
    if (user == null) return;
    await client
        .from('profiles')
        .update({'permissions_onboarding_done': true}).eq('id', user.id);
  }
}
