-- Reely: 과목(subjects) · 공부 세션(sessions)
-- Supabase Dashboard → SQL Editor 에서 전체 실행하세요.
-- 실행 후: Settings → API → "Restart project" 또는 잠시 후 스키마 캐시가 갱신됩니다.

-- ── 과목 ─────────────────────────────────────────────────
create table if not exists public.subjects (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  color text not null default '#6366F1',
  created_at timestamptz not null default now()
);

create index if not exists subjects_user_id_idx on public.subjects (user_id);

alter table public.subjects enable row level security;

drop policy if exists "subjects_select_own" on public.subjects;
create policy "subjects_select_own"
  on public.subjects for select
  to authenticated
  using (auth.uid()::text = user_id::text);

drop policy if exists "subjects_insert_own" on public.subjects;
create policy "subjects_insert_own"
  on public.subjects for insert
  to authenticated
  with check (auth.uid()::text = user_id::text);

drop policy if exists "subjects_update_own" on public.subjects;
create policy "subjects_update_own"
  on public.subjects for update
  to authenticated
  using (auth.uid()::text = user_id::text);

drop policy if exists "subjects_delete_own" on public.subjects;
create policy "subjects_delete_own"
  on public.subjects for delete
  to authenticated
  using (auth.uid()::text = user_id::text);

-- ── 세션 (집중 시간 기록) ─────────────────────────────────
create table if not exists public.sessions (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  subject_id bigint references public.subjects (id) on delete set null,
  start_time timestamptz not null,
  end_time timestamptz,
  focus_time integer not null default 0,
  distraction_count integer not null default 0
);

-- 이미 sessions 테이블만 있고 subject_id가 없을 때(IF NOT EXISTS로 CREATE가 스킵된 경우)
alter table public.sessions
  add column if not exists subject_id bigint references public.subjects (id) on delete set null;

create index if not exists sessions_user_id_idx on public.sessions (user_id);
create index if not exists sessions_start_time_idx on public.sessions (start_time);
create index if not exists sessions_subject_id_idx on public.sessions (subject_id);

alter table public.sessions enable row level security;

drop policy if exists "sessions_select_own" on public.sessions;
create policy "sessions_select_own"
  on public.sessions for select
  to authenticated
  using (auth.uid()::text = user_id::text);

drop policy if exists "sessions_insert_own" on public.sessions;
create policy "sessions_insert_own"
  on public.sessions for insert
  to authenticated
  with check (auth.uid()::text = user_id::text);

drop policy if exists "sessions_update_own" on public.sessions;
create policy "sessions_update_own"
  on public.sessions for update
  to authenticated
  using (auth.uid()::text = user_id::text);

drop policy if exists "sessions_delete_own" on public.sessions;
create policy "sessions_delete_own"
  on public.sessions for delete
  to authenticated
  using (auth.uid()::text = user_id::text);
