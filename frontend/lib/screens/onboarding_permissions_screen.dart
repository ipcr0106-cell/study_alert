import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/retro_ui.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/supabase_service.dart';
import '../widgets/reely_logo_image.dart';

/// Android 중심: 캘린더·알림·카메라 런타임 권한 + 사용량 접근(스크린타임) 안내
class OnboardingPermissionsScreen extends StatefulWidget {
  const OnboardingPermissionsScreen({super.key});

  @override
  State<OnboardingPermissionsScreen> createState() =>
      _OnboardingPermissionsScreenState();
}

class _OnboardingPermissionsScreenState extends State<OnboardingPermissionsScreen>
    with WidgetsBindingObserver {
  bool _calendarOk = false;
  bool _notificationOk = false;
  bool _cameraOk = false;

  /// Android: 사용량 접근 설정 화면으로 유도한 뒤 사용자가 단계를 진행했음을 표시
  bool _usageAccessStepDone = false;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  int get _targetCount => _isAndroid ? 4 : 3;

  int get _doneCount {
    var n = 0;
    if (_calendarOk) n++;
    if (_notificationOk) n++;
    if (_cameraOk) n++;
    if (_isAndroid && _usageAccessStepDone) n++;
    return n;
  }

  bool get _canContinue => _doneCount >= _targetCount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissionStates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissionStates();
    }
  }

  Future<void> _refreshPermissionStates() async {
    final cal = await Permission.calendar.status;
    final notif = await Permission.notification.status;
    final cam = await Permission.camera.status;
    if (!mounted) return;
    setState(() {
      _calendarOk = cal.isGranted;
      _notificationOk = notif.isGranted;
      _cameraOk = cam.isGranted;
    });
  }

  Future<void> _request(Permission permission) async {
    final result = await permission.request();
    if (!mounted) return;
    setState(() {
      if (permission == Permission.calendar) {
        _calendarOk = result.isGranted;
      } else if (permission == Permission.notification) {
        _notificationOk = result.isGranted;
      } else if (permission == Permission.camera) {
        _cameraOk = result.isGranted;
      }
    });
  }

  Future<void> _openUsageAccessSettings() async {
    if (!_isAndroid) return;
    const intent = AndroidIntent(
      action: 'android.settings.USAGE_ACCESS_SETTINGS',
    );
    await intent.launch();
    if (!mounted) return;
    setState(() => _usageAccessStepDone = true);
  }

  Future<void> _finish() async {
    if (!_canContinue) return;
    try {
      await SupabaseService.markPermissionsOnboardingDone();
    } catch (_) {
      // 오프라인 등: 로컬 진행은 허용
    }
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            const Center(child: ReelyLogoImage(size: 72, borderRadius: 18)),
            const SizedBox(height: 20),
            Text(
              '원활한 Reely 이용을 위해 권한을 허용해 주세요.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            _PermissionCard(
              icon: Icons.calendar_month,
              iconColor: AppTheme.brandOrange,
              title: '캘린더',
              description: '일정·학습 계획 연동에 활용됩니다.',
              granted: _calendarOk,
              onRequest: () => _request(Permission.calendar),
            ),
            if (_isAndroid) ...[
              const SizedBox(height: 12),
              _PermissionCard(
                icon: Icons.hourglass_bottom,
                iconColor: const Color(0xFF5C6BC0),
                title: '스크린타임',
                description:
                    '공부 중 다른 앱 사용을 제한하는 데 필요합니다. (사용량 접근)',
                granted: _usageAccessStepDone,
                actionLabel: '설정 열기',
                onRequest: _openUsageAccessSettings,
              ),
            ],
            const SizedBox(height: 12),
            _PermissionCard(
              icon: Icons.notifications_active,
              iconColor: AppTheme.brandOrange,
              title: '알림',
              description: '학습 알림과 중요 안내를 보내기 위해 사용합니다.',
              granted: _notificationOk,
              onRequest: () => _request(Permission.notification),
            ),
            const SizedBox(height: 12),
            _PermissionCard(
              icon: Icons.photo_camera,
              iconColor: const Color(0xFF546E7A),
              title: '카메라',
              description: '집중·미션 기능(캠 스터디)에 사용됩니다.',
              granted: _cameraOk,
              onRequest: () => _request(Permission.camera),
            ),
            const SizedBox(height: 20),
            Text(
              '접근 권한은 앱 이용 목적에만 사용되며, 제3자와 공유하지 않습니다.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _canContinue ? _finish : null,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  disabledBackgroundColor:
                      theme.colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: reelyRadius(context, 12),
                  ),
                ),
                child: Text(
                  '계속 ($_doneCount/$_targetCount)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.granted,
    required this.onRequest,
    this.actionLabel,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool granted;
  final VoidCallback onRequest;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);

    return Material(
      color: bg,
      borderRadius: reelyRadius(context, 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: reelyRadius(context, 10),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: granted
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '허용됨',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : OutlinedButton(
                            onPressed: onRequest,
                            child: Text(actionLabel ?? '허용하기'),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
