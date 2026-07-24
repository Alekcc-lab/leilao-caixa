-- ============================================================
--  Leilão Caixa — esquema do banco (rode no Supabase → SQL Editor)
-- ============================================================
-- Uma linha por usuário. A coluna `data` (JSONB) guarda todo o
-- estado do app: finalistas, checklist, farol, premissas por imóvel
-- e os inputs globais. Simples e suficiente para uso pessoal/equipe.

create table if not exists public.app_state (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- Liga o Row Level Security: sem as policies abaixo, ninguém lê nada.
alter table public.app_state enable row level security;

-- Cada usuário só enxerga e altera a PRÓPRIA linha.
drop policy if exists "own row select" on public.app_state;
create policy "own row select" on public.app_state
  for select using (auth.uid() = user_id);

drop policy if exists "own row insert" on public.app_state;
create policy "own row insert" on public.app_state
  for insert with check (auth.uid() = user_id);

drop policy if exists "own row update" on public.app_state;
create policy "own row update" on public.app_state
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "own row delete" on public.app_state;
create policy "own row delete" on public.app_state
  for delete using (auth.uid() = user_id);
