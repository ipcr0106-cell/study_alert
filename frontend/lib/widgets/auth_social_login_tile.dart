import 'package:flutter/material.dart';

import '../theme/auth_ui_colors.dart';
import '../theme/retro_ui.dart';

/// 흰 배경·회색 테두리 소셜 로그인/가입 버튼 행
class AuthSocialLoginTile extends StatelessWidget {
  const AuthSocialLoginTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : Colors.white;

    final r = reelyRadius(context, 12);
    return Material(
      color: fill,
      borderRadius: r,
      child: InkWell(
        onTap: onTap,
        borderRadius: r,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: r,
            border: Border.all(color: AuthUiColors.borderGray),
            color: fill,
          ),
          child: Row(
            children: [
              SizedBox(width: 28, child: Center(child: icon)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
