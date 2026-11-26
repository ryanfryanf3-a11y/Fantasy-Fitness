-- Instance-specific stats are stored as columns rather than JSON.
alter table public.inventory
  drop column if exists instance_data;

alter table public.inventory
  add column if not exists attack integer not null default 0,
  add column if not exists defense integer not null default 0,
  add column if not exists hp integer not null default 0,
  add column if not exists regeneration integer not null default 0,
  add column if not exists hit_chance numeric(5, 4) not null default 0
    check (hit_chance between 0 and 1),
  add column if not exists crit_chance numeric(5, 4) not null default 0
    check (crit_chance between 0 and 1);
