import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../widgets/reely_logo_image.dart';
import '../theme/retro_ui.dart';

const int _maxNicknameBytes = 60;

/// 회원가입 OAuth 직후 닉네임 설정
class CreateNicknameScreen extends StatefulWidget {
  const CreateNicknameScreen({super.key});

  @override
  State<CreateNicknameScreen> createState() => _CreateNicknameScreenState();
}

class _CreateNicknameScreenState extends State<CreateNicknameScreen> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _byteLength => utf8.encode(_controller.text).length;

  bool get _canSubmit =>
      _byteLength > 0 && _byteLength <= _maxNicknameBytes && !_submitting;

  Future<void> _showDuplicateDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('닉네임 설정'),
        content: const Text(
          '이미 사용중인 닉네임이나 다른 닉네임을 사용하세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    try {
      final available =
          await SupabaseService.isNicknameAvailable(_controller.text);
      if (!mounted) return;
      if (!available) {
        await _showDuplicateDialog();
        return;
      }
      await SupabaseService.saveNickname(_controller.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/onboarding/permissions');
    } on PostgrestException catch (e) {
      if (!mounted) return;
      final code = e.code ?? '';
      final lower = e.message.toLowerCase();
      if (code == '23505' ||
          lower.contains('unique') ||
          lower.contains('duplicate')) {
        await _showDuplicateDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: ${e.message}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const ReelyLogoImage(size: 72, borderRadius: 18),
              const SizedBox(height: 24),
              Text(
                '닉네임 만들기',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (_, value, __) {
                  return Text(
                    '${utf8.encode(value.text).length}/$_maxNicknameBytes Bytes',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                maxLines: 1,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '사용하실 닉네임을 입력해주세요.',
                  border: UnderlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (_byteLength > _maxNicknameBytes)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '$_maxNicknameBytes Bytes 이하로 입력해 주세요.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _canSubmit ? _submit : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    disabledBackgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: reelyRadius(context, 12),
                    ),
                  ),
                  child: _submitting
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Text(
                          '완료',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
