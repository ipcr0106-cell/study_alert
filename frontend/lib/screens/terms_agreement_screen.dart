import 'package:flutter/material.dart';

import '../theme/auth_ui_colors.dart';
import '../theme/retro_ui.dart';
import 'signup_methods_screen.dart';

/// 회원가입 전 약관·나이 동의
class TermsAgreementScreen extends StatefulWidget {
  const TermsAgreementScreen({super.key});

  @override
  State<TermsAgreementScreen> createState() => _TermsAgreementScreenState();
}

class _TermsAgreementScreenState extends State<TermsAgreementScreen> {
  bool _ageOk = false;
  bool _termsOk = false;
  bool _privacyOk = false;

  bool get _allChecked => _ageOk && _termsOk && _privacyOk;

  bool get _masterChecked => _allChecked;

  void _setMasterChecked(bool v) {
    setState(() {
      _ageOk = v;
      _termsOk = v;
      _privacyOk = v;
    });
  }

  void _showDetailSheet(String title) {
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
                '상세 약관 문구는 추후 서비스 정책에 맞게 연결됩니다.',
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
              '약관동의',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 28),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _masterChecked,
              onChanged: (v) => _setMasterChecked(v ?? false),
              title: const Text(
                '모두 동의합니다.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(color: AuthUiColors.borderGray, height: 1),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _ageOk,
              onChanged: (v) => setState(() => _ageOk = v ?? false),
              title: const Text('만 14세 이상입니다.'),
            ),
            _RequiredAgreementRow(
              checked: _termsOk,
              title: '[필수] 이용약관 동의',
              onChanged: (v) => setState(() => _termsOk = v ?? false),
              onDetail: () => _showDetailSheet('이용약관'),
            ),
            _RequiredAgreementRow(
              checked: _privacyOk,
              title: '[필수] 개인정보 수집 및 이용 동의',
              onChanged: (v) => setState(() => _privacyOk = v ?? false),
              onDetail: () => _showDetailSheet('개인정보 수집 및 이용'),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _allChecked
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SignupMethodsScreen(),
                          ),
                        );
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: reelyRadius(context, 12),
                  ),
                ),
                child: const Text(
                  '동의하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _RequiredAgreementRow extends StatelessWidget {
  const _RequiredAgreementRow({
    required this.checked,
    required this.title,
    required this.onChanged,
    required this.onDetail,
  });

  final bool checked;
  final String title;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: checked,
            onChanged: onChanged,
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(!checked),
              child: Text(
                title,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
            onPressed: onDetail,
          ),
        ],
      ),
    );
  }
}
