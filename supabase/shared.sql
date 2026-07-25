-- ============================================================
--  Leilão Caixa — compartilhamento colaborativo entre o grupo
--  (rode no Supabase → SQL Editor, depois do schema.sql)
-- ============================================================
-- Um registro por imóvel compartilhado. Todo usuário autenticado
-- (ou seja, os e-mails que você autorizou no Google) enxerga e pode
-- editar o dossiê compartilhado. Os dados PRIVADOS de cada um
-- continuam isolados em app_state — esta tabela é um canal à parte.

create table if not exists public.shared_properties (
  prop_id         text primary key,
  data            jsonb not null default '{}'::jsonb,
  titulo          text,
  owner_id        uuid not null references auth.users(id) on delete cascade,
  owner_email     text,
  updated_at      timestamptz not null default now(),
  updated_by      uuid,
  updated_by_email text
);

alter table public.shared_properties enable row level security;

-- Todo mundo do grupo (autenticado) LÊ
drop policy if exists "grupo le" on public.shared_properties;
create policy "grupo le" on public.shared_properties
  for select to authenticated using (true);

-- Todo mundo do grupo PUBLICA (registrando-se como dono)
drop policy if exists "grupo publica" on public.shared_properties;
create policy "grupo publica" on public.shared_properties
  for insert to authenticated with check (auth.uid() = owner_id);

-- COLABORATIVO: todo mundo do grupo EDITA o dossiê compartilhado
drop policy if exists "grupo edita" on public.shared_properties;
create policy "grupo edita" on public.shared_properties
  for update to authenticated using (true) with check (true);

-- Só quem publicou pode remover do compartilhamento
drop policy if exists "dono remove" on public.shared_properties;
create policy "dono remove" on public.shared_properties
  for delete to authenticated using (auth.uid() = owner_id);
