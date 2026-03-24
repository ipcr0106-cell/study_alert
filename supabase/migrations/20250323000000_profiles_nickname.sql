-- Reely: 프로필·닉네임·온보딩 권한 단계
-- Supabase SQL 편집기에서 한 번 실행하거나 CLI로 적용하세요.

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  nickname text,
  permissions_onboarding_done boolean not null default false,
  created_at timestamptz not null default now()
);

create unique index if not exists profiles_nickname_lower_idx
  on public.profiles (lower(trim(nickname)))
  where nickname is not null and length(trim(nickname)) > 0;

alter table public.profiles enable row level security;

drop policy if exists "profiles_own_select" on public.profiles;
create policy "profiles_own_select"
  on public.profiles for select
  using (auth.uid() = id);

drop policy if exists "profiles_own_insert" on public.profiles;
create policy "profiles_own_insert"
  on public.profiles for insert
  with check (auth.uid() = id);

drop policy if exists "profiles_own_update" on public.profiles;
create policy "profiles_own_update"
  on public.profiles for update
  using (auth.uid() = id);

-- 닉네임 중복 검사 (다른 행과만 비교, 신규 가입 시 행 없음)
create or replace function public.is_nickname_available(p_nickname text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v text;
begin
  v := trim(p_nickname);
  if v is null or length(v) = 0 then
    return false;
  end if;
  return not exists (
    select 1 from public.profiles p
    where p.nickname is not null
      and length(trim(p.nickname)) > 0
      and lower(trim(p.nickname)) = lower(v)
  );
end;
$$;

revoke all on function public.is_nickname_available(text) from public;
grant execute on function public.is_nickname_available(text) to authenticated;
