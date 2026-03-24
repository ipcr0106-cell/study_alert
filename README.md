# Reely

**Make your time Reely count.**

타이머만 돌리는 앱이 아니라, 전면 카메라와 ML Kit으로 **얼굴·졸음·자리 이탈**을 감지해 **실제 집중 시간**을 쌓는 Flutter 앱입니다.  
과목·세션·통계는 **Express API**와 **Supabase**(Auth · PostgreSQL · Realtime)로 이어져 있고, 같은 방에서 **공부방·깨우기**로 서로 상태를 공유할 수 있습니다.

---

## 목차

- [스택](#스택)
- [저장소 구조](#저장소-구조)
- [빠른 시작](#빠른-시작)
- [환경 변수](#환경-변수)
- [백엔드 배포 (Render 예시)](#백엔드-배포-render-예시)
- [APK 빌드 · 친구에게 공유](#apk-빌드--친구에게-공유)
- [앱 아이콘](#앱-아이콘)
- [문제 해결](#문제-해결)
- [보안](#보안)
- [크레딧 · 라이선스](#크레딧--라이선스)

---

## 스택

| 구분 | 기술 |
|------|------|
| 앱 | Flutter (Dart 3.4+) |
| 백엔드 | Node.js, Express |
| DB · 인증 · 실시간 | Supabase |
| 얼굴 감지 | Google ML Kit Face Detection |
| 배포(예) | [Render](https://render.com) 등 PaaS |

---

## 저장소 구조

```
study_alert/
├── frontend/              # Flutter 앱 (패키지명: reely)
├── backend/               # REST API (npm 패키지: focusguard-backend)
└── supabase/migrations/   # DB 스키마
```

---

## 빠른 시작

### 1) Supabase

1. 프로젝트를 만들고 `supabase/migrations`의 SQL을 적용합니다.  
2. 공부방을 쓴다면 대시보드에서 **Realtime**(해당 채널의 **Broadcast** 등)이 켜져 있는지 확인합니다.  
3. **Project Settings → API**에서 **Project URL**과 **anon public** 키를 복사해 둡니다.  
   - **service_role** 키는 **백엔드에만** 사용합니다. Flutter 코드·`.env`에 넣지 마세요.

### 2) 백엔드 (로컬)

```bash
cd backend
cp .env.example .env   # Windows: copy .env.example .env
# .env에 SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY 입력
npm install
npm run dev
```

기본 포트: **4000** (`PORT`로 변경 가능).

### 3) Flutter (로컬)

```bash
cd frontend
cp .env.example .env   # Windows: copy .env.example .env
# .env에 SUPABASE_URL, SUPABASE_ANON_KEY, (선택) API_BASE_URL 입력
flutter pub get
flutter run --dart-define-from-file=.env
```

- **에뮬레이터**에서 로컬 API만 쓸 때는 `API_BASE_URL`을 비우거나 생략하면 기본값 `http://10.0.2.2:4000`이 쓰입니다.  
- **실제 기기**나 **배포 APK**에서는 반드시 **닿을 수 있는 URL**(예: Render HTTPS)을 `API_BASE_URL`에 넣습니다.

---

## 환경 변수

### `frontend/.env` (Git에 포함하지 않음)

`frontend/.env.example`을 복사한 뒤 채웁니다. 빌드 시 `--dart-define-from-file=.env`로 주입됩니다.

| 키 | 설명 |
|----|------|
| `SUPABASE_URL` | Supabase Project URL |
| `SUPABASE_ANON_KEY` | anon **public** 키 |
| `API_BASE_URL` | Express API 루트 (예: `https://study-alert.onrender.com`). 비우면 에뮬레이터용 로컬 주소 사용. |

### `backend/.env` (Git에 포함하지 않음)

| 키 | 설명 |
|----|------|
| `SUPABASE_URL` | Supabase Project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | **service_role** (서버 전용) |
| `PORT` | 선택. 미설정 시 `4000` |

---

## 백엔드 배포 (Render 예시)

1. GitHub에 이 저장소를 푸시합니다. **루트에 `backend` 폴더**가 보여야 합니다.  
2. [Render](https://render.com)에서 **New → Web Service**, 저장소 연결.  
3. **Root Directory**: `backend`  
4. **Build Command**: `npm install`  
5. **Start Command**: `npm start`  
6. **Environment**에 `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` 등록.  
7. 배포 완료 후 표시되는 `https://<이름>.onrender.com` 을 브라우저로 열어  
   `{"message":"FocusGuard API 동작 중"}` 형태의 응답을 확인합니다.

무료 인스턴스는 유휴 시 **슬립**되어 첫 요청이 느릴 수 있습니다.

---

## APK 빌드 · 친구에게 공유

`frontend/.env`에 **`API_BASE_URL`**을 배포된 HTTPS 주소로 넣은 뒤:

```bash
cd frontend
flutter build apk --release --dart-define-from-file=.env
```

산출물: **`frontend/build/app/outputs/flutter-apk/app-release.apk`**

- **같은 APK**를 여러 사람에게 나눠도 됩니다. 주소는 빌드 시 한 번 박힙니다.  
- 수신자는 Android에서 **출처를 알 수 없는 앱** 설치를 허용해야 할 수 있습니다.  
- 스토어 출시 시에는 별도 개발자 계정·개인정보 처리방침 등이 필요합니다.

---

## 앱 아이콘

소스 이미지: `frontend/assets/app_icon.png`  
아이콘 재생성:

```bash
cd frontend
dart run flutter_launcher_icons
```

---

## 문제 해결

| 증상 | 원인 · 조치 |
|------|-------------|
| 폰에서 과목 추가 시 `10.0.2.2` 연결 실패 | 에뮬레이터 전용 주소입니다. `.env`의 `API_BASE_URL`을 Render 등 **공개 URL**로 넣고 APK를 다시 빌드하세요. |
| Render 빌드에서 `backend` 없음 | GitHub 저장소에 `backend` 폴더가 푸시됐는지 확인하세요. |
| Supabase 초기화 오류 | `flutter run`에 `--dart-define-from-file=.env`를 빼먹지 않았는지, `.env` 키 이름·값이 맞는지 확인하세요. |

---

## 보안

- **`.env`는 절대 커밋하지 마세요.** 이 저장소는 루트·`frontend`·`backend`에서 `.env`를 무시하도록 설정되어 있습니다.  
- 클라이언트에 들어가는 anon 키도 APK에서 추출될 수 있으므로, 데이터 보호는 **Supabase RLS**로 해야 합니다.  
- 공개 저장소에 키를 올린 적이 있다면 **키 로테이트**를 검토하세요.

---

## 크레딧 · 라이선스

| 자산 | 출처 |
|------|------|
| 깨우기 효과음 `mixkit_wake_alarm.mp3` | Mixkit — `frontend/assets/AUDIO_LICENSE.txt` 참고 |
| 8비트 폰트 Galmuri11 | SIL OFL — `frontend/fonts/CREDITS.txt` 참고 |

앱 소스 코드의 라이선스는 저장소 소유자가 정합니다. 위 서드파티는 각 라이선스를 따릅니다.

---

<p align="center">
  <b>Reely</b> — 오늘 집중도, 제대로 셀 수 있게.
</p>
