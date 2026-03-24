import 'package:flutter/material.dart';
import '../theme/theme_notifier.dart';
import '../theme/theme_scope.dart';
import '../services/supabase_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = context.findAncestorWidgetOfExactType<ThemeScopeInherited>();
    final themeNotifier = scope?.themeNotifier;
    final eightBitNotifier = scope?.eightBitNotifier;

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          const _SectionHeader('테마'),
          if (themeNotifier != null && eightBitNotifier != null)
            ListenableBuilder(
              listenable:
                  Listenable.merge([themeNotifier, eightBitNotifier]),
              builder: (_, __) => Column(
                children: [
                  _themeRadio(
                      themeNotifier, themeNotifier.value, ThemeMode.system, '시스템 설정'),
                  _themeRadio(
                      themeNotifier, themeNotifier.value, ThemeMode.light, '라이트 모드'),
                  _themeRadio(
                      themeNotifier, themeNotifier.value, ThemeMode.dark, '다크 모드'),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('8비트 모드'),
                    subtitle: const Text(
                      '픽셀풍 테두리·배경과 Galmuri 폰트로 레트로 게임 느낌',
                    ),
                    value: eightBitNotifier.value,
                    onChanged: (v) => eightBitNotifier.setEnabled(v),
                  ),
                ],
              ),
            ),
          const Divider(),
          const _SectionHeader('계정'),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: () => _confirmSignOut(context),
          ),
        ],
      ),
    );
  }

  Widget _themeRadio(
    ThemeNotifier notifier,
    ThemeMode current,
    ThemeMode value,
    String label,
  ) {
    return RadioListTile<ThemeMode>(
      title: Text(label),
      value: value,
      groupValue: current,
      onChanged: (v) {
        if (v != null) notifier.setTheme(v);
      },
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('로그아웃')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await SupabaseService.signOut();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
