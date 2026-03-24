/// 로그인 직후 온보딩 단계
enum OnboardingStep {
  /// 닉네임 입력 필요
  needsNickname,

  /// 시스템 권한 안내·요청 단계
  needsPermissions,

  /// 메인 화면으로 진입 가능
  readyForMain,
}
