-- Fantasy Fitness: initial schema
--
-- The server owns every reward. Clients insert raw data (workout sets, meals, sleep
-- hours, cardio) and read their own rows. XP, stats, Energy, quest completion and loot
-- are written only by the security-definer functions in this file.

-- ---------------------------------------------------------------------------
-- Types
-- ---------------------------------------------------------------------------

create type public.guild_class as enum ('warrior', 'ranger', 'monk', 'paladin');
create type public.guild_rank as enum ('F', 'E', 'D', 'C', 'B', 'A', 'S');
create type public.quest_kind as enum ('daily', 'weekly', 'story', 'side');
create type public.objective_metric as enum (
  'lift',          -- sets of `exercise` meeting min reps / weight
  'workouts',      -- completed workouts
  'protein_days',  -- days the protein target was met
  'sleep_nights',  -- nights with at least `min_hours` of sleep
  'distance_km',   -- cardio distance
  'weekly_quests'  -- weekly quests completed (story arcs)
);
create type public.item_slot as enum ('head', 'chest', 'weapon', 'trinket');
create type public.rarity as enum ('common', 'uncommon', 'rare', 'epic', 'legendary');
create type public.meal_type as enum ('breakfast', 'lunch', 'dinner', 'snack');
create type public.verification_status as enum ('pending', 'verified', 'rejected');

-- ---------------------------------------------------------------------------
-- Leveling: level n starts at 100 * n * (n - 1) total XP.
-- ---------------------------------------------------------------------------

create function public.level_for_xp(total_xp integer) returns integer
language sql immutable as $$
  select floor((1 + sqrt(1 + total_xp / 25.0)) / 2)::integer
$$;

create function public.xp_for_level(lvl integer) returns integer
language sql immutable as $$
  select 100 * lvl * (lvl - 1)
$$;

-- ---------------------------------------------------------------------------
-- Catalogs (read-only for players)
-- ---------------------------------------------------------------------------

create table public.items (
  id text primary key,
  name text not null,
  slot public.item_slot not null,
  rarity public.rarity not null,
  -- In-game effect only. Gear never changes real performance or exam results.
  effect text not null,
  flavor text not null default '',
  starter boolean not null default false,
  droppable boolean not null default true
);

create table public.dungeons (
  id text primary key,
  name text not null,
  tier text not null,
  required_rank public.guild_rank not null default 'F',
  boss text not null,
  boss_health integer not null check (boss_health > 0),
  energy_cost integer not null check (energy_cost > 0),
  loot_rarity public.rarity not null,
  system_image text not null,
  map_x double precision not null check (map_x between 0 and 1),
  map_y double precision not null check (map_y between 0 and 1),
  sort_order integer not null default 0
);

-- Bodyweight-relative rank standards.
create table public.rank_exams (
  id text primary key,
  rank public.guild_rank not null,
  lift text not null,
  bodyweight_multiple numeric(4, 2) not null check (bodyweight_multiple > 0)
);

-- Quest blueprints; `generate_quests` turns these into per-player quests.
-- objectives: [{name, detail, metric, target, exercise?, min_reps?, min_weight_lb?, min_hours?}]
create table public.quest_templates (
  id text primary key,
  guild_class public.guild_class,          -- null = any class
  kind public.quest_kind not null,
  arc text not null,
  title text not null,
  objectives jsonb not null,
  rewards text[] not null default '{}',    -- display labels, e.g. "+120 XP"
  xp_reward integer not null default 0,
  reward_rarity public.rarity,             -- chest granted on completion
  sort_order integer not null default 0
);

-- ---------------------------------------------------------------------------
-- Players
-- ---------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default 'Adventurer' check (char_length(display_name) between 1 and 40),
  guild_class public.guild_class not null default 'warrior',
  rank public.guild_rank not null default 'F',
  xp integer not null default 0 check (xp >= 0),
  level integer generated always as (public.level_for_xp(xp)) stored,
  level_start_xp integer generated always as (public.xp_for_level(public.level_for_xp(xp))) stored,
  next_level_xp integer generated always as (public.xp_for_level(public.level_for_xp(xp) + 1)) stored,
  energy integer not null default 3 check (energy >= 0),
  max_energy integer not null default 5 check (max_energy > 0),
  bodyweight_lb numeric(5, 1) check (bodyweight_lb between 60 and 700),
  -- Food is fuel: calorie targets have a floor.
  calorie_target integer not null default 2400 check (calorie_target >= 1200),
  protein_target_g integer not null default 140 check (protein_target_g between 30 and 400),
  carbs_target_g integer not null default 260 check (carbs_target_g between 50 and 900),
  fat_target_g integer not null default 70 check (fat_target_g between 30 and 300),
  has_completed_onboarding boolean not null default false,
  created_at timestamptz not null default now()
);

-- Capability stats. Only ever raised by server functions when real performance rises.
create table public.stats (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  strength integer not null default 0,
  endurance integer not null default 0,
  speed integer not null default 0,
  agility integer not null default 0,
  vitality integer not null default 0,
  updated_at timestamptz not null default now()
);

create table public.inventory (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  item_id text not null references public.items (id),
  equipped boolean not null default false,
  source text not null default 'loot',
  acquired_at timestamptz not null default now(),
  unique (user_id, item_id)
);

-- ---------------------------------------------------------------------------
-- Raw activity data (written by the client)
-- Dates are the player's local calendar date, sent by the app.
-- ---------------------------------------------------------------------------

create table public.workouts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  quest_id uuid,
  workout_date date not null,
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  is_exam boolean not null default false
);

create table public.workout_sets (
  id uuid primary key default gen_random_uuid(),
  workout_id uuid not null references public.workouts (id) on delete cascade,
  exercise text not null check (char_length(exercise) between 1 and 80),
  weight_lb numeric(6, 1) not null default 0 check (weight_lb between 0 and 2000),
  reps integer not null check (reps between 1 and 100),
  performed_at timestamptz not null default now()
);

create table public.cardio_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  logged_on date not null,
  activity text not null,
  distance_km numeric(6, 2) not null default 0 check (distance_km between 0 and 500),
  duration_min numeric(6, 1) not null check (duration_min between 1 and 1440),
  created_at timestamptz not null default now()
);

-- Nightly summary only; raw HealthKit samples stay on the device.
create table public.sleep_logs (
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  night_of date not null,
  hours numeric(4, 2) not null check (hours between 0 and 24),
  created_at timestamptz not null default now(),
  primary key (user_id, night_of)
);

-- ---------------------------------------------------------------------------
-- Quests
-- ---------------------------------------------------------------------------

create table public.quests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  template_id text references public.quest_templates (id),
  kind public.quest_kind not null,
  arc text not null,
  title text not null,
  rewards text[] not null default '{}',
  xp_reward integer not null default 0,
  reward_rarity public.rarity,
  starts_on date not null,
  ends_on date not null,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  unique (user_id, kind, starts_on)
);

alter table public.workouts
  add constraint workouts_quest_id_fkey foreign key (quest_id) references public.quests (id) on delete set null;

create table public.quest_objectives (
  id uuid primary key default gen_random_uuid(),
  quest_id uuid not null references public.quests (id) on delete cascade,
  position integer not null,
  name text not null,
  detail text not null default '',
  metric public.objective_metric not null,
  target numeric not null check (target > 0),
  exercise text,
  min_reps integer,
  min_weight_lb numeric(6, 1),
  min_hours numeric(4, 2),
  progress numeric not null default 0,
  is_complete boolean not null default false,
  unique (quest_id, position)
);

-- ---------------------------------------------------------------------------
-- Dungeons and exams
-- ---------------------------------------------------------------------------

create table public.dungeon_runs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  dungeon_id text not null references public.dungeons (id),
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  victory boolean,
  xp_awarded integer not null default 0,
  loot_item_ids text[] not null default '{}'
);

create table public.exam_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  exam_id text not null references public.rank_exams (id),
  workout_id uuid references public.workouts (id) on delete set null,
  result_weight_lb numeric(6, 1) check (result_weight_lb between 0 and 2000),
  video_path text,
  verification_status public.verification_status not null default 'pending',
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Tavern
-- ---------------------------------------------------------------------------

create table public.recipes (
  id uuid primary key default gen_random_uuid(),
  author_id uuid default auth.uid() references public.profiles (id) on delete set null,
  name text not null check (char_length(name) between 1 and 80),
  meal_type public.meal_type not null,
  minutes integer not null default 15 check (minutes between 1 and 1440),
  servings integer not null default 1 check (servings between 1 and 50),
  -- Per serving. Null until macros are calculated from the ingredients.
  calories integer check (calories >= 0),
  protein_g integer check (protein_g >= 0),
  carbs_g integer check (carbs_g >= 0),
  fat_g integer check (fat_g >= 0),
  photo_path text,
  is_public boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.recipe_ingredients (
  recipe_id uuid not null references public.recipes (id) on delete cascade,
  position integer not null,
  name text not null check (char_length(name) between 1 and 80),
  amount text not null default '',
  primary key (recipe_id, position)
);

-- Rated on separate axes; macro profile is computed, never rated.
create table public.recipe_ratings (
  recipe_id uuid not null references public.recipes (id) on delete cascade,
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  taste smallint not null check (taste between 1 and 5),
  ease smallint not null check (ease between 1 and 5),
  cost smallint not null check (cost between 1 and 5),
  created_at timestamptz not null default now(),
  primary key (recipe_id, user_id)
);

create table public.meal_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  recipe_id uuid references public.recipes (id) on delete set null,
  name text not null default '',
  servings numeric(4, 2) not null default 1 check (servings > 0 and servings <= 20),
  calories integer not null default 0 check (calories >= 0),
  protein_g integer not null default 0 check (protein_g >= 0),
  carbs_g integer not null default 0 check (carbs_g >= 0),
  fat_g integer not null default 0 check (fat_g >= 0),
  eaten_on date not null,
  created_at timestamptz not null default now()
);

create view public.recipe_summaries with (security_invoker = true) as
select
  r.*,
  coalesce(avg(rr.taste), 0)::float8 as avg_taste,
  coalesce(avg(rr.ease), 0)::float8 as avg_ease,
  coalesce(avg(rr.cost), 0)::float8 as avg_cost,
  count(rr.user_id)::integer as rating_count
from public.recipes r
left join public.recipe_ratings rr on rr.recipe_id = r.id
group by r.id;

-- ---------------------------------------------------------------------------
-- Guilds
-- ---------------------------------------------------------------------------

create table public.guilds (
  id uuid primary key default gen_random_uuid(),
  name text not null unique check (char_length(name) between 2 and 40),
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.guild_members (
  guild_id uuid not null references public.guilds (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role text not null default 'member' check (role in ('leader', 'officer', 'member')),
  joined_at timestamptz not null default now(),
  primary key (guild_id, user_id)
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------

create index on public.inventory (user_id);
create index on public.workouts (user_id, workout_date);
create index on public.workout_sets (workout_id);
create index on public.cardio_logs (user_id, logged_on);
create index on public.quests (user_id, kind, starts_on);
create index on public.quest_objectives (quest_id);
create index on public.dungeon_runs (user_id);
create index on public.exam_attempts (user_id);
create index on public.recipe_ingredients (recipe_id);
create index on public.meal_logs (user_id, eaten_on);
create index on public.guild_members (user_id);

-- ---------------------------------------------------------------------------
-- Row-level security
-- ---------------------------------------------------------------------------

alter table public.items enable row level security;
alter table public.dungeons enable row level security;
alter table public.rank_exams enable row level security;
alter table public.quest_templates enable row level security;
alter table public.profiles enable row level security;
alter table public.stats enable row level security;
alter table public.inventory enable row level security;
alter table public.workouts enable row level security;
alter table public.workout_sets enable row level security;
alter table public.cardio_logs enable row level security;
alter table public.sleep_logs enable row level security;
alter table public.quests enable row level security;
alter table public.quest_objectives enable row level security;
alter table public.dungeon_runs enable row level security;
alter table public.exam_attempts enable row level security;
alter table public.recipes enable row level security;
alter table public.recipe_ingredients enable row level security;
alter table public.recipe_ratings enable row level security;
alter table public.meal_logs enable row level security;
alter table public.guilds enable row level security;
alter table public.guild_members enable row level security;

-- Catalogs: any signed-in player can read.
create policy "Catalog is readable" on public.items for select to authenticated using (true);
create policy "Catalog is readable" on public.dungeons for select to authenticated using (true);
create policy "Catalog is readable" on public.rank_exams for select to authenticated using (true);
-- quest_templates: no policy, so only server functions can read them.

-- Own rows only.
create policy "Read own profile" on public.profiles for select to authenticated using (id = auth.uid());
create policy "Update own profile" on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());
create policy "Read own stats" on public.stats for select to authenticated using (user_id = auth.uid());
create policy "Read own inventory" on public.inventory for select to authenticated using (user_id = auth.uid());

create policy "Read own workouts" on public.workouts for select to authenticated using (user_id = auth.uid());
create policy "Insert own workouts" on public.workouts for insert to authenticated
  with check (user_id = auth.uid() and completed_at is null);

create policy "Read own sets" on public.workout_sets for select to authenticated
  using (exists (select 1 from public.workouts w where w.id = workout_id and w.user_id = auth.uid()));
create policy "Add sets to own open workouts" on public.workout_sets for insert to authenticated
  with check (exists (
    select 1 from public.workouts w
    where w.id = workout_id and w.user_id = auth.uid() and w.completed_at is null
  ));

create policy "Read own cardio" on public.cardio_logs for select to authenticated using (user_id = auth.uid());
create policy "Insert own cardio" on public.cardio_logs for insert to authenticated with check (user_id = auth.uid());
create policy "Read own sleep" on public.sleep_logs for select to authenticated using (user_id = auth.uid());
create policy "Insert own sleep" on public.sleep_logs for insert to authenticated with check (user_id = auth.uid());

create policy "Read own quests" on public.quests for select to authenticated using (user_id = auth.uid());
create policy "Read own objectives" on public.quest_objectives for select to authenticated
  using (exists (select 1 from public.quests q where q.id = quest_id and q.user_id = auth.uid()));

create policy "Read own runs" on public.dungeon_runs for select to authenticated using (user_id = auth.uid());

create policy "Read own exam attempts" on public.exam_attempts for select to authenticated using (user_id = auth.uid());
create policy "Submit own exam attempts" on public.exam_attempts for insert to authenticated
  with check (user_id = auth.uid());

create policy "Read public or own recipes" on public.recipes for select to authenticated
  using (is_public or author_id = auth.uid());
create policy "Create own recipes" on public.recipes for insert to authenticated
  with check (author_id = auth.uid());
create policy "Edit own recipes" on public.recipes for update to authenticated
  using (author_id = auth.uid()) with check (author_id = auth.uid());

create policy "Read ingredients of visible recipes" on public.recipe_ingredients for select to authenticated
  using (exists (
    select 1 from public.recipes r where r.id = recipe_id and (r.is_public or r.author_id = auth.uid())
  ));
create policy "Add ingredients to own recipes" on public.recipe_ingredients for insert to authenticated
  with check (exists (select 1 from public.recipes r where r.id = recipe_id and r.author_id = auth.uid()));

create policy "Ratings are readable" on public.recipe_ratings for select to authenticated using (true);
create policy "Rate as yourself" on public.recipe_ratings for insert to authenticated with check (user_id = auth.uid());
create policy "Change own rating" on public.recipe_ratings for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "Read own meals" on public.meal_logs for select to authenticated using (user_id = auth.uid());
create policy "Log own meals" on public.meal_logs for insert to authenticated with check (user_id = auth.uid());
create policy "Delete own meals" on public.meal_logs for delete to authenticated using (user_id = auth.uid());

create policy "Guilds are readable" on public.guilds for select to authenticated using (true);
create policy "Members are readable" on public.guild_members for select to authenticated using (true);

-- Column-level grants: players may only write the columns listed here. Everything
-- else (XP, level, rank, Energy, stats, inventory, quest progress) is server-only.
revoke all on all tables in schema public from anon, authenticated;
grant select on all tables in schema public to authenticated;
revoke select on public.quest_templates from authenticated;

grant update (display_name, guild_class, bodyweight_lb, calorie_target, protein_target_g, carbs_target_g, fat_target_g)
  on public.profiles to authenticated;
grant insert (id, quest_id, workout_date, started_at, is_exam) on public.workouts to authenticated;
grant insert (workout_id, exercise, weight_lb, reps, performed_at) on public.workout_sets to authenticated;
grant insert (logged_on, activity, distance_km, duration_min) on public.cardio_logs to authenticated;
grant insert (night_of, hours) on public.sleep_logs to authenticated;
grant insert (exam_id, workout_id, result_weight_lb, video_path) on public.exam_attempts to authenticated;
grant insert (id, name, meal_type, minutes, servings, is_public, photo_path) on public.recipes to authenticated;
grant update (name, meal_type, minutes, servings, is_public, photo_path) on public.recipes to authenticated;
grant insert (recipe_id, position, name, amount) on public.recipe_ingredients to authenticated;
grant insert (recipe_id, taste, ease, cost) on public.recipe_ratings to authenticated;
-- recipe_id is included so PostgREST upserts (insert ... on conflict do update) work.
grant update (recipe_id, taste, ease, cost) on public.recipe_ratings to authenticated;
grant insert (recipe_id, name, servings, calories, protein_g, carbs_g, fat_g, eaten_on) on public.meal_logs to authenticated;
grant delete on public.meal_logs to authenticated;

-- ---------------------------------------------------------------------------
-- Internal helpers (not callable by clients)
-- ---------------------------------------------------------------------------

create function public.grant_random_item(p_user uuid, p_rarity public.rarity, p_source text)
returns text
language plpgsql security definer set search_path = public as $$
declare
  v_item text;
begin
  if p_rarity is null then
    return null;
  end if;
  -- Something the player doesn't own yet, at this rarity or the next one up that has one.
  select i.id into v_item
  from items i
  where i.rarity >= p_rarity
    and i.droppable
    and not exists (select 1 from inventory inv where inv.user_id = p_user and inv.item_id = i.id)
  order by i.rarity, random()
  limit 1;
  if v_item is null then
    return null;  -- they own everything; the XP still counts
  end if;
  insert into inventory (user_id, item_id, source) values (p_user, v_item, p_source);
  return v_item;
end;
$$;

create function public.objective_progress(
  p_user uuid, o public.quest_objectives, p_from date, p_to date, p_since timestamptz
) returns numeric
language sql stable security definer set search_path = public as $$
  select case o.metric
    when 'lift' then (
      select count(*)::numeric
      from workout_sets s
      join workouts w on w.id = s.workout_id
      where w.user_id = p_user
        and w.completed_at is not null
        and w.workout_date between p_from and p_to
        and lower(trim(s.exercise)) = lower(trim(o.exercise))
        and s.reps >= coalesce(o.min_reps, 1)
        and s.weight_lb >= coalesce(o.min_weight_lb, 0))
    when 'workouts' then (
      select count(*)::numeric
      from workouts w
      where w.user_id = p_user and w.completed_at is not null and w.workout_date between p_from and p_to)
    when 'protein_days' then (
      select count(*)::numeric
      from (
        select m.eaten_on
        from meal_logs m
        where m.user_id = p_user and m.eaten_on between p_from and p_to
        group by m.eaten_on
        having sum(m.protein_g) >= (select protein_target_g from profiles where id = p_user)
      ) days)
    when 'sleep_nights' then (
      select count(*)::numeric
      from sleep_logs s
      where s.user_id = p_user and s.night_of between p_from and p_to and s.hours >= coalesce(o.min_hours, 7))
    when 'distance_km' then (
      select coalesce(sum(c.distance_km), 0)
      from cardio_logs c
      where c.user_id = p_user and c.logged_on between p_from and p_to)
    when 'weekly_quests' then (
      select count(*)::numeric
      from quests q
      where q.user_id = p_user and q.kind = 'weekly' and q.completed_at >= p_since)
    else 0
  end
$$;

-- Recomputes objective progress from raw data, then completes quests and pays rewards.
create function public.refresh_quests(p_user uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  q record;
begin
  -- Enum order (daily, weekly, story) lets weekly completions count toward story arcs.
  for q in
    select * from quests where user_id = p_user and completed_at is null order by kind, starts_on
  loop
    update quest_objectives o
    set progress = least(public.objective_progress(p_user, o, q.starts_on, q.ends_on, q.created_at), o.target),
        is_complete = public.objective_progress(p_user, o, q.starts_on, q.ends_on, q.created_at) >= o.target
    where o.quest_id = q.id;

    if not exists (select 1 from quest_objectives where quest_id = q.id and not is_complete) then
      update quests set completed_at = now() where id = q.id;
      update profiles set xp = xp + q.xp_reward where id = p_user;
      perform public.grant_random_item(p_user, q.reward_rarity, 'quest');
    end if;
  end loop;
end;
$$;

create function public.instantiate_quest(p_user uuid, t public.quest_templates, p_start date, p_end date)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
begin
  insert into quests (user_id, template_id, kind, arc, title, rewards, xp_reward, reward_rarity, starts_on, ends_on)
  values (p_user, t.id, t.kind, t.arc, t.title, t.rewards, t.xp_reward, t.reward_rarity, p_start, p_end)
  on conflict (user_id, kind, starts_on) do nothing
  returning id into v_id;

  if v_id is null then
    return null;
  end if;

  insert into quest_objectives (quest_id, position, name, detail, metric, target, exercise, min_reps, min_weight_lb, min_hours)
  select
    v_id,
    (o.ordinality - 1)::integer,
    o.value ->> 'name',
    coalesce(o.value ->> 'detail', ''),
    (o.value ->> 'metric')::objective_metric,
    (o.value ->> 'target')::numeric,
    o.value ->> 'exercise',
    (o.value ->> 'min_reps')::integer,
    (o.value ->> 'min_weight_lb')::numeric,
    (o.value ->> 'min_hours')::numeric
  from jsonb_array_elements(t.objectives) with ordinality as o(value, ordinality);

  return v_id;
end;
$$;

revoke execute on function public.grant_random_item(uuid, public.rarity, text) from public, anon, authenticated;
revoke execute on function public.objective_progress(uuid, public.quest_objectives, date, date, timestamptz) from public, anon, authenticated;
revoke execute on function public.refresh_quests(uuid) from public, anon, authenticated;
revoke execute on function public.instantiate_quest(uuid, public.quest_templates, date, date) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- New players
-- ---------------------------------------------------------------------------

create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, display_name)
  values (
    new.id,
    left(coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      'Adventurer'
    ), 40)
  );
  insert into stats (user_id) values (new.id);
  insert into inventory (user_id, item_id, equipped, source)
  select new.id, i.id, true, 'starter' from items i where i.starter;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Activity triggers: refresh quests, Energy and stats when raw data arrives
-- ---------------------------------------------------------------------------

create function public.fill_meal_macros() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  r recipes;
begin
  if new.recipe_id is not null then
    select * into r from recipes where id = new.recipe_id;
    if found then
      new.name := r.name;
      new.calories := round(coalesce(r.calories, 0) * new.servings);
      new.protein_g := round(coalesce(r.protein_g, 0) * new.servings);
      new.carbs_g := round(coalesce(r.carbs_g, 0) * new.servings);
      new.fat_g := round(coalesce(r.fat_g, 0) * new.servings);
    end if;
  end if;
  return new;
end;
$$;

create trigger meal_logs_fill_macros
  before insert on public.meal_logs
  for each row execute function public.fill_meal_macros();

create function public.after_meal_logged() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  perform public.refresh_quests(new.user_id);
  return new;
end;
$$;

create trigger meal_logs_refresh_quests
  after insert on public.meal_logs
  for each row execute function public.after_meal_logged();

-- Sleep refills Energy and earns the Well-Rested buff; rest is never punished.
create function public.after_sleep_logged() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.hours >= 7 then
    update profiles set energy = least(max_energy, energy + 1) where id = new.user_id;
  end if;
  -- Vitality: nights of 7h+ sleep in the last 14 days.
  update stats
  set vitality = greatest(vitality, (
        select count(*)::integer * 5 from sleep_logs
        where user_id = new.user_id and hours >= 7 and night_of > new.night_of - 14)),
      updated_at = now()
  where user_id = new.user_id;
  perform public.refresh_quests(new.user_id);
  return new;
end;
$$;

create trigger sleep_logs_after_insert
  after insert on public.sleep_logs
  for each row execute function public.after_sleep_logged();

create function public.after_cardio_logged() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update profiles set energy = least(max_energy, energy + 1) where id = new.user_id;
  -- Endurance: total cardio minutes over the last 28 days. Speed: best pace in km/h.
  update stats
  set endurance = greatest(endurance, (
        select (coalesce(sum(duration_min), 0) / 10)::integer from cardio_logs
        where user_id = new.user_id and logged_on > new.logged_on - 28)),
      speed = greatest(speed, case
        when new.distance_km > 0 then round(new.distance_km / (new.duration_min / 60.0))::integer
        else 0 end),
      updated_at = now()
  where user_id = new.user_id;
  update profiles set xp = xp + least(round(new.duration_min)::integer, 120) where id = new.user_id;
  perform public.refresh_quests(new.user_id);
  return new;
end;
$$;

create trigger cardio_logs_after_insert
  after insert on public.cardio_logs
  for each row execute function public.after_cardio_logged();

revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.fill_meal_macros() from public, anon, authenticated;
revoke execute on function public.after_meal_logged() from public, anon, authenticated;
revoke execute on function public.after_sleep_logged() from public, anon, authenticated;
revoke execute on function public.after_cardio_logged() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Client RPCs
-- ---------------------------------------------------------------------------

-- Creates today's daily quest, this week's weekly quest and an active story arc if missing.
create function public.generate_quests(p_today date) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_class guild_class;
  v_week_start date := p_today - (extract(isodow from p_today)::integer - 1);  -- Monday
  v_count integer;
  t quest_templates;
begin
  if v_user is null then
    raise exception 'Not signed in';
  end if;
  select guild_class into v_class from profiles where id = v_user and has_completed_onboarding;
  if v_class is null then
    return;
  end if;

  -- Daily: rotate through the class's daily templates (includes rest days).
  if not exists (select 1 from quests where user_id = v_user and kind = 'daily' and starts_on = p_today) then
    select count(*) into v_count from quest_templates
    where kind = 'daily' and (guild_class is null or guild_class = v_class);
    if v_count > 0 then
      select * into t from quest_templates
      where kind = 'daily' and (guild_class is null or guild_class = v_class)
      order by sort_order, id
      offset ((p_today - date '2026-01-05') % v_count + v_count) % v_count
      limit 1;
      perform public.instantiate_quest(v_user, t, p_today, p_today);
    end if;
  end if;

  if not exists (select 1 from quests where user_id = v_user and kind = 'weekly' and starts_on = v_week_start) then
    select * into t from quest_templates
    where kind = 'weekly' and (guild_class is null or guild_class = v_class)
    order by guild_class nulls last, sort_order, id
    limit 1;
    if found then
      perform public.instantiate_quest(v_user, t, v_week_start, v_week_start + 6);
    end if;
  end if;

  -- Story: the next arc the player hasn't finished, four weeks long.
  if not exists (
    select 1 from quests
    where user_id = v_user and kind = 'story' and completed_at is null and ends_on >= p_today
  ) then
    select * into t from quest_templates tt
    where tt.kind = 'story' and (tt.guild_class is null or tt.guild_class = v_class)
      and not exists (
        select 1 from quests q where q.user_id = v_user and q.template_id = tt.id and q.completed_at is not null)
    order by tt.sort_order, tt.id
    limit 1;
    if found then
      perform public.instantiate_quest(v_user, t, p_today, p_today + 27);
    end if;
  end if;

  perform public.refresh_quests(v_user);
end;
$$;

create function public.complete_onboarding(
  p_class public.guild_class, p_display_name text, p_bodyweight_lb numeric, p_today date
) returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then
    raise exception 'Not signed in';
  end if;
  update profiles
  set guild_class = p_class,
      display_name = coalesce(nullif(trim(p_display_name), ''), display_name),
      bodyweight_lb = coalesce(p_bodyweight_lb, bodyweight_lb),
      has_completed_onboarding = true
  where id = auth.uid();
  perform public.generate_quests(p_today);
end;
$$;

-- Closes a logged workout and pays out. Stats only rise with real performance.
create function public.complete_workout(p_workout_id uuid) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  v_sets integer;
  v_volume numeric;
  v_xp integer;
  v_bodyweight numeric;
  v_best_ratio numeric;
begin
  update workouts set completed_at = now()
  where id = p_workout_id and user_id = v_user and completed_at is null;
  if not found then
    raise exception 'Workout not found or already completed';
  end if;

  select count(*), coalesce(sum(weight_lb * reps), 0) into v_sets, v_volume
  from workout_sets where workout_id = p_workout_id;
  v_xp := least(10 * v_sets + floor(v_volume / 500)::integer, 300);

  -- Strength: best estimated 1RM (Epley) relative to bodyweight.
  select bodyweight_lb into v_bodyweight from profiles where id = v_user;
  if v_bodyweight is not null then
    select max(weight_lb * (1 + reps / 30.0)) / v_bodyweight into v_best_ratio
    from workout_sets where workout_id = p_workout_id and weight_lb > 0;
    if v_best_ratio is not null then
      update stats
      set strength = greatest(strength, round(v_best_ratio * 40)::integer), updated_at = now()
      where user_id = v_user;
    end if;
  end if;

  update profiles set xp = xp + v_xp, energy = least(max_energy, energy + 1) where id = v_user;
  perform public.refresh_quests(v_user);

  return jsonb_build_object('xp_gained', v_xp, 'sets', v_sets);
end;
$$;

create function public.equip_item(p_item_id text) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_slot item_slot;
begin
  select i.slot into v_slot
  from inventory inv join items i on i.id = inv.item_id
  where inv.user_id = auth.uid() and inv.item_id = p_item_id;
  if v_slot is null then
    raise exception 'Item not in inventory';
  end if;
  update inventory inv
  set equipped = (inv.item_id = p_item_id)
  from items i
  where i.id = inv.item_id and inv.user_id = auth.uid() and i.slot = v_slot;
end;
$$;

create function public.unequip_item(p_item_id text) returns void
language sql security definer set search_path = public as $$
  update inventory set equipped = false where user_id = auth.uid() and item_id = p_item_id;
$$;

create function public.start_dungeon_run(p_dungeon_id text) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  d dungeons;
  p profiles;
  v_run uuid;
begin
  select * into d from dungeons where id = p_dungeon_id;
  if not found then
    raise exception 'Unknown dungeon';
  end if;
  select * into p from profiles where id = v_user for update;
  if p.rank < d.required_rank then
    raise exception 'Requires %-rank', d.required_rank;
  end if;
  if p.energy < d.energy_cost then
    raise exception 'Not enough Energy';
  end if;
  update profiles set energy = energy - d.energy_cost where id = v_user;
  insert into dungeon_runs (user_id, dungeon_id) values (v_user, d.id) returning id into v_run;
  return v_run;
end;
$$;

-- TODO: move battle resolution server-side; today the client reports the outcome.
create function public.finish_dungeon_run(p_run_id uuid, p_victory boolean) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  r dungeon_runs;
  d dungeons;
  v_xp integer := 0;
  v_items text[] := '{}';
  v_item text;
begin
  update dungeon_runs set finished_at = now(), victory = p_victory
  where id = p_run_id and user_id = v_user and finished_at is null
  returning * into r;
  if not found then
    raise exception 'Run not found or already finished';
  end if;
  select * into d from dungeons where id = r.dungeon_id;

  if p_victory then
    v_xp := 40 * d.energy_cost;
    update profiles set xp = xp + v_xp where id = v_user;
    v_item := public.grant_random_item(v_user, d.loot_rarity, 'dungeon');
    if v_item is not null then
      v_items := v_items || v_item;
    end if;
    v_item := public.grant_random_item(v_user, 'common', 'dungeon');
    if v_item is not null and not v_item = any (v_items) then
      v_items := v_items || v_item;
    end if;
    update dungeon_runs set xp_awarded = v_xp, loot_item_ids = v_items where id = r.id;
  end if;

  return jsonb_build_object('xp', v_xp, 'item_ids', to_jsonb(v_items), 'chest_rarity', d.loot_rarity);
end;
$$;

-- Exams for the next rank above the player's current one.
create function public.unlocked_exams() returns setof public.rank_exams
language sql stable security definer set search_path = public as $$
  select e.*
  from rank_exams e
  join profiles p on p.id = auth.uid()
  where e.rank = (
    select r from unnest(enum_range(null::guild_rank)) as r where r > p.rank order by r limit 1
  )
  order by e.id
$$;

-- Creates a recipe and its ingredients in one transaction.
-- p_ingredients: [{"name": "...", "amount": "..."}]
create function public.create_recipe(
  p_name text, p_meal_type public.meal_type, p_minutes integer, p_servings integer, p_ingredients jsonb
) returns uuid
language plpgsql security invoker set search_path = public as $$
declare
  v_id uuid;
begin
  insert into recipes (name, meal_type, minutes, servings)
  values (p_name, p_meal_type, p_minutes, p_servings)
  returning id into v_id;

  insert into recipe_ingredients (recipe_id, position, name, amount)
  select v_id, (i.ordinality - 1)::integer, i.value ->> 'name', coalesce(i.value ->> 'amount', '')
  from jsonb_array_elements(p_ingredients) with ordinality as i(value, ordinality);

  return v_id;
end;
$$;

revoke execute on function public.generate_quests(date) from public, anon;
revoke execute on function public.complete_onboarding(public.guild_class, text, numeric, date) from public, anon;
revoke execute on function public.complete_workout(uuid) from public, anon;
revoke execute on function public.equip_item(text) from public, anon;
revoke execute on function public.unequip_item(text) from public, anon;
revoke execute on function public.start_dungeon_run(text) from public, anon;
revoke execute on function public.finish_dungeon_run(uuid, boolean) from public, anon;
revoke execute on function public.unlocked_exams() from public, anon;
revoke execute on function public.create_recipe(text, public.meal_type, integer, integer, jsonb) from public, anon;

grant execute on function public.generate_quests(date) to authenticated;
grant execute on function public.complete_onboarding(public.guild_class, text, numeric, date) to authenticated;
grant execute on function public.complete_workout(uuid) to authenticated;
grant execute on function public.equip_item(text) to authenticated;
grant execute on function public.unequip_item(text) to authenticated;
grant execute on function public.start_dungeon_run(text) to authenticated;
grant execute on function public.finish_dungeon_run(uuid, boolean) to authenticated;
grant execute on function public.unlocked_exams() to authenticated;
grant execute on function public.create_recipe(text, public.meal_type, integer, integer, jsonb) to authenticated;

-- ---------------------------------------------------------------------------
-- Storage: each player writes only inside a folder named after their user id.
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public)
values
  ('avatars', 'avatars', true),
  ('recipe-photos', 'recipe-photos', true),
  ('lift-videos', 'lift-videos', false)
on conflict (id) do nothing;

create policy "Upload to own folder" on storage.objects for insert to authenticated
  with check (
    bucket_id in ('avatars', 'recipe-photos', 'lift-videos')
    and (storage.foldername(name))[1] = auth.uid()::text
  );
create policy "Update own files" on storage.objects for update to authenticated
  using (
    bucket_id in ('avatars', 'recipe-photos', 'lift-videos')
    and (storage.foldername(name))[1] = auth.uid()::text
  );
create policy "Delete own files" on storage.objects for delete to authenticated
  using (
    bucket_id in ('avatars', 'recipe-photos', 'lift-videos')
    and (storage.foldername(name))[1] = auth.uid()::text
  );
create policy "Read own lift videos" on storage.objects for select to authenticated
  using (bucket_id = 'lift-videos' and (storage.foldername(name))[1] = auth.uid()::text);
