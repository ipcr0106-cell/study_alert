import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'theme/theme_notifier.dart';
import 'theme/eight_bit_notifier.dart';
import 'theme/theme_scope.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_welcome_screen.dart';
import 'screens/create_nickname_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_permissions_screen.dart';
import 'screens/study_screen.dart';
import 'screens/result_screen.dart';
import 'models/session_result.dart';
import 'services/api_service.dart';

// Supabase: 빌드 시 주입 — 로컬은 `frontend/.env` + `flutter run --dart-define-from-file=.env`
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
const _supabaseAnonKey =
    String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

final themeNotifier = ThemeNotifier();
final eightBitNotifier = EightBitNotifier();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
    throw StateError(
      'SUPABASE_URL / SUPABASE_ANON_KEY가 비었습니다. '
      'frontend/.env.example을 복사해 .env를 만든 뒤 값을 넣고, '
      'flutter run --dart-define-from-file=.env 로 실행하세요. '
      '(또는 동일 키를 --dart-define=... 로 전달)',
    );
  }

  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );

  await themeNotifier.load();
  await eightBitNotifier.load();

  runApp(const ReelyApp());
}

class ReelyApp extends StatelessWidget {
  const ReelyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      themeNotifier: themeNotifier,
      eightBitNotifier: eightBitNotifier,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (_, mode, __) => ValueListenableBuilder<bool>(
          valueListenable: eightBitNotifier,
          builder: (_, eightBit, __) {
            final theme = eightBit ? AppTheme.eightBitLightTheme : AppTheme.lightTheme;
            final darkTheme =
                eightBit ? AppTheme.eightBitDarkTheme : AppTheme.darkTheme;
            return MaterialApp(
              title: 'Reely',
              theme: theme,
              darkTheme: darkTheme,
              themeMode: mode,
              // 일반↔8비트 전환 시 TextStyle inherit 불일치로 lerp 예외 방지
              themeAnimationDuration: Duration.zero,
              debugShowCheckedModeBanner: false,
              initialRoute: '/',
              routes: {
                '/': (_) => const SplashScreen(),
                '/login': (_) => const AuthWelcomeScreen(),
                '/onboarding/nickname': (_) => const CreateNicknameScreen(),
                '/onboarding/permissions': (_) =>
                    const OnboardingPermissionsScreen(),
                '/main': (_) => const MainScreen(),
              },
              onGenerateRoute: (settings) {
                if (settings.name == '/result') {
                  final args = settings.arguments as SessionResult;
                  return MaterialPageRoute(
                    builder: (_) => ResultScreen(result: args),
                  );
                }
                if (settings.name == '/study') {
                  final subject = settings.arguments is Subject
                      ? settings.arguments as Subject
                      : null;
                  return MaterialPageRoute(
                    builder: (_) => StudyScreen(subject: subject),
                  );
                }
                return null;
              },
            );
          },
        ),
      ),
    );
  }
}
