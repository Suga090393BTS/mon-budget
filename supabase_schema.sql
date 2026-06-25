-- ============================================================
--  Mon budget — schéma Supabase
--  À coller dans : Supabase → SQL Editor → New query → Run
--  Crée une table qui stocke TES données (1 ligne par utilisateur),
--  protégée pour que seule TA connexion puisse les lire/écrire.
-- ============================================================

create table if not exists public.app_state (
  user_id    uuid primary key references auth.users on delete cascade,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- Sécurité : chacun ne voit/modifie que sa propre ligne
alter table public.app_state enable row level security;

drop policy if exists "select own row"  on public.app_state;
drop policy if exists "insert own row"  on public.app_state;
drop policy if exists "update own row"  on public.app_state;

create policy "select own row" on public.app_state
  for select using (auth.uid() = user_id);

create policy "insert own row" on public.app_state
  for insert with check (auth.uid() = user_id);

create policy "update own row" on public.app_state
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
