-- ─── 과목(subjects) 테이블 ───────────────────────────────────────────────────
create table if not exists public.subjects (
  id        bigserial primary key,
  user_id   uuid      not null references auth.users (id) on delete cascade,
  name      text      not null,
  color     text      not null default '#6366F1',
  created_at timestamptz not null default now()
);

alter table public.subjects enable row level security;

drop policy if exists "subjects_own_all" on public.subjects;
create policy "subjects_own_all"
  on public.subjects
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ─── sessions 테이블에 subject_id 컬럼 추가 ──────────────────────────────────
-- sessions 테이블이 아직 없으면 기본 구조로 생성
create table if not exists public.sessions (
  id                bigserial primary key,
  user_id           uuid      not null references auth.users (id) on delete cascade,
  start_time        timestamptz not null default now(),
  end_time          timestamptz,
  focus_time        int       not null default 0,
  distraction_count int       not null default 0,
  created_at        timestamptz not null default now()
);

-- subject_id 컬럼 추가 (이미 존재하면 무시)
alter table public.sessions
  add column if not exists subject_id bigint references public.subjects (id) on delete set null;

-- sessions RLS (서비스롤이 관리하므로 정책만 설정)
alter table public.sessions enable row level security;

drop policy if exists "sessions_own_select" on public.sessions;
create policy "sessions_own_select"
  on public.sessions for select
  using (auth.uid() = user_id);
