create table if not exists public.random_attribute_lookups (
  id bigint generated always as identity primary key,
  attack integer not null,
  defense integer not null,
  hp integer not null,
  regeneration integer not null,
  hit_chance numeric(5, 4) not null check (hit_chance between 0 and 1),
  crit_chance numeric(5, 4) not null check (crit_chance between 0 and 1)
);

insert into public.random_attribute_lookups (
  attack, defense, hp, regeneration, hit_chance, crit_chance
) values (
  1, 0, 0, 0, 0, 0
), (
  0, 1, 0, 0, 0, 0
), (
  0, 0, 20, 0, 0, 0
), (
  0, 0, 0, 5, 0, 0
), (
  0, 0, 0, 0, 0.1, 0
), (
  0, 0, 0, 0, 0, 0.05
);

alter table public.random_attribute_lookups enable row level security;
revoke all on public.random_attribute_lookups from anon, authenticated;