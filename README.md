# Reely

집중 시간·공부 세션을 기록하고, 전면 카메라와 얼굴 감지로 졸음·자리 이탈을 보조하는 Flutter 앱입니다.  
과목·일별/주별 통계는 Express 백엔드와 Supabase(PostgreSQL)를 통해 저장합니다.

## 주요 기능

- **인증**: Supabase Auth
- **홈**: 오늘 집중 시간, 과목별 공부 시작
- **공부 화면**: 타이머, ML Kit 기반 얼굴·눈·고개 상태 추정, 실제 집중 시간 집계
- **공부방**: Supabase Realtime Presence + Broadcast로 동시 접속자 상태, 실시간 집중 시간 공유
- **깨우기**: 졸음 상태인 상대 카드의 🔔 버튼으로 알람(효과음) 전송 — 수신자는 졸음이 풀릴 때까지 루프 재생
- **기록 / 분석**: 캘린더·통계(백엔드 API)
- **테마**: 라이트 / 다크 / 시스템, 선택적 **8비트 모드**(Galmuri 폰트·픽셀풍 UI)

## 프로젝트 구조

```
study_alert/
├── frontend/          # Flutter 앱 (패키지명: reely)
├── backend/           # Express API (focusguard-backend)
└── supabase/
    └── migrations/    # SQL 마이그레이션
```

## 사전 요구 사항

- Flutter SDK (`pubspec.yaml`의 `environment.sdk` 범위 준수)
- Node.js 18+ (백엔드)
- Supabase 프로젝트

## Supabase 설정

1. 프로젝트를 생성한 뒤 `supabase/migrations`의 SQL을 적용합니다.
2. **Realtime**: 공부방에 사용하는 채널(예: `study-room`)에 대해 **Broadcast** 등 필요한 Realtime 기능이 켜져 있는지 대시보드에서 확인합니다.
3. Flutter: `frontend/.env.example`을 복사해 **`frontend/.env`**를 만들고 **URL**과 **anon public key**만 채웁니다. (`.env`는 `.gitignore`에 있어 Git에 안 올라갑니다.)  
   - 실행: `flutter run --dart-define-from-file=.env`  
   - **service_role** 키는 앱·`.env`에 넣지 마세요. (백엔드 서버 전용)

## 백엔드 실행

```bash
cd backend
npm install
npm run dev            # 또는 npm start
```

`backend/.env.example`을 복사해 **`backend/.env`**를 만든 뒤 값을 채웁니다.

기본 포트는 **4000**입니다 (`PORT` 생략 시).

## Flutter 앱 실행

```bash
cd frontend
flutter pub get
flutter run --dart-define-from-file=.env
```

### API 베이스 URL

`ApiService.baseUrl`은 컴파일 시 `API_BASE_URL`로 정해집니다 (`frontend/lib/services/api_service.dart`).

- **기본값(미지정)**: `http://10.0.2.2:4000` — **Android 에뮬레이터에서만** 호스트 PC의 백엔드를 가리킵니다.
- **실제 폰·친구 APK**: 에뮬레이터 주소는 동작하지 않습니다. 백엔드를 **인터넷에 배포**(Render, Railway, VPS 등)하거나, 같은 Wi‑Fi에서 **PC의 사설 IP**(예: `http://192.168.0.10:4000`)로 빌드해야 합니다. PC 방화벽에서 4000 포트 허용이 필요할 수 있습니다.

## 테스트용 APK 빌드 (스토어 없이 배포)

친구에게 줄 APK는 **반드시** 접속 가능한 백엔드 주소를 넣어 다시 빌드하세요.

```bash
cd frontend
flutter build apk --release --dart-define-from-file=.env --dart-define=API_BASE_URL=https://your-api.example.com
```

로컬 PC를 같은 Wi‑Fi 폰에서 쓰는 예:

```bash
flutter build apk --release --dart-define-from-file=.env --dart-define=API_BASE_URL=http://192.168.0.10:4000
```

(`192.168.0.10`은 `ipconfig` 등으로 본 본인 PC의 IPv4로 바꿉니다.)

산출물: `frontend/build/app/outputs/flutter-apk/app-release.apk`  
수신자는 **출처를 알 수 없는 앱 설치**를 허용한 뒤 APK를 설치하면 됩니다.

## 서드파티·라이선스 (요약)

| 항목 | 출처 / 라이선스 |
|------|-----------------|
| 깨우기 효과음 | `assets/mixkit_wake_alarm.mp3` — Mixkit Sound Effects Free License (`assets/AUDIO_LICENSE.txt`) |
| 8비트 폰트 | Galmuri11 — SIL OFL (`frontend/fonts/CREDITS.txt`) |

## 보안·운영 참고

- **`.env`는 Git에 올리지 마세요.** 루트·`frontend`·`backend`의 `.gitignore`에 포함되어 있습니다. 공개 저장소에는 **`.env.example`만** (가짜/플레이스홀더 값) 두면 됩니다.
- 예전에 `main.dart` 등에 키를 넣었다면 **공개 푸시 전에 제거**하고, Supabase 대시보드에서 **anon 키 로테이트**를 검토하세요. (클라이언트 anon 키는 APK에도 들어가므로 **RLS**로 데이터 보호가 필수입니다.)
- CI·배포는 **저장소 시크릿 + dart-define / define-from-file**로 주입하는 것을 권장합니다.
- 앱스토어·플레이 스토어 출시에는 별도의 개발자 등록, 서명, 개인정보 처리방침 URL 등이 필요합니다.

## 라이선스

앱 소스 코드의 라이선스는 저장소 소유자가 지정합니다. 위 서드파티 에셋은 각각의 라이선스를 따릅니다.
