-- Esquema de referência para uma instalação nova.
-- No projeto Supabase "simulados" este esquema e as políticas já foram aplicados.
create table public.simulado_results (
  id uuid primary key default gen_random_uuid(),
  test_date date not null,
  respondent text not null,
  school text not null,
  exam_name text not null,
  grade text not null,
  classroom text not null,
  subject text not null,
  format text not null,
  question_count integer not null check (question_count > 0),
  enrolled integer not null check (enrolled >= 0),
  present integer not null check (present >= 0 and present <= enrolled),
  absent integer generated always as (enrolled - present) stored,
  average_correct numeric(5,2) not null check (average_correct between 0 and 100),
  under_50 integer not null default 0 check (under_50 >= 0),
  from_50_to_70 integer not null default 0 check (from_50_to_70 >= 0),
  from_70_to_90 integer not null default 0 check (from_70_to_90 >= 0),
  from_90_to_100 integer not null default 0 check (from_90_to_100 >= 0),
  strengths text,
  difficulties text,
  analysis_performed text check (analysis_performed in ('Sim','Não','Parcialmente') or analysis_performed is null),
  difficulty_factors text,
  planned_actions text,
  action_owner text,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

alter table public.simulado_results enable row level security;
revoke all on public.simulado_results from anon;
revoke all on public.simulado_results from public;
grant select, insert, update, delete on public.simulado_results to authenticated;

create policy "verified education users can read shared results"
  on public.simulado_results for select to authenticated
  using (
    lower(coalesce((select auth.jwt()->>'email'),'')) like '%@educacao.sp.gov.br'
    or lower(coalesce((select auth.jwt()->>'email'),'')) like '%@professor.educacao.sp.gov.br'
    or lower(coalesce((select auth.jwt()->>'email'),'')) like '%@fde.sp.gov.br'
  );

create policy "verified education users can add shared results"
  on public.simulado_results for insert to authenticated
  with check (
    (
      lower(coalesce((select auth.jwt()->>'email'),'')) like '%@educacao.sp.gov.br'
      or lower(coalesce((select auth.jwt()->>'email'),'')) like '%@professor.educacao.sp.gov.br'
      or lower(coalesce((select auth.jwt()->>'email'),'')) like '%@fde.sp.gov.br'
    ) and created_by = (select auth.uid())
  );

create policy "authors can edit their shared results"
  on public.simulado_results for update to authenticated
  using (
    (
      lower(coalesce((select auth.jwt()->>'email'),'')) like '%@educacao.sp.gov.br'
      or lower(coalesce((select auth.jwt()->>'email'),'')) like '%@professor.educacao.sp.gov.br'
      or lower(coalesce((select auth.jwt()->>'email'),'')) like '%@fde.sp.gov.br'
    ) and created_by = (select auth.uid())
  )
  with check (
    (
      lower(coalesce((select auth.jwt()->>'email'),'')) like '%@educacao.sp.gov.br'
      or lower(coalesce((select auth.jwt()->>'email'),'')) like '%@professor.educacao.sp.gov.br'
      or lower(coalesce((select auth.jwt()->>'email'),'')) like '%@fde.sp.gov.br'
    ) and created_by = (select auth.uid())
  );

create policy "authors can delete their shared results"
  on public.simulado_results for delete to authenticated
  using (
    (
      lower(coalesce((select auth.jwt()->>'email'),'')) like '%@educacao.sp.gov.br'
      or lower(coalesce((select auth.jwt()->>'email'),'')) like '%@professor.educacao.sp.gov.br'
      or lower(coalesce((select auth.jwt()->>'email'),'')) like '%@fde.sp.gov.br'
    ) and created_by = (select auth.uid())
  );

create index simulado_results_school_idx on public.simulado_results (school);
create index simulado_results_test_date_idx on public.simulado_results (test_date desc);
