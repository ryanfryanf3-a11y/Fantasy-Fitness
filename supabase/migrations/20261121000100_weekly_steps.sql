-- Daily step summaries synced from Apple Health (raw HealthKit samples stay on-device).
create table public.step_logs (
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  logged_on date not null,
  steps integer not null check (steps between 0 and 200000),
  updated_at timestamptz not null default now(),
  primary key (user_id, logged_on)
);

alter table public.step_logs enable row level security;

create policy "Read own steps" on public.step_logs
  for select to authenticated using (user_id = auth.uid());
create policy "Insert own steps" on public.step_logs
  for insert to authenticated with check (user_id = auth.uid());
create policy "Update own steps" on public.step_logs
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Match the repo's column-level grant pattern (logged_on included so PostgREST upserts work).
revoke all on public.step_logs from anon, authenticated;
grant select on public.step_logs to authenticated;
grant insert (logged_on, steps) on public.step_logs to authenticated;
grant update (logged_on, steps) on public.step_logs to authenticated;

-- Refresh weekly quest progress whenever daily steps are logged or updated.
create function public.after_steps_logged() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  perform public.refresh_quests(new.user_id);
  return new;
end;
$$;

create trigger step_logs_after_write
  after insert or update on public.step_logs
  for each row execute function public.after_steps_logged();

revoke execute on function public.after_steps_logged() from public, anon, authenticated;

-- Add step_days (days hitting 8,000+ steps) to objective_progress().
create or replace function public.objective_progress(
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
    when 'step_days' then (
      select count(*)::numeric
      from step_logs s
      where s.user_id = p_user and s.logged_on between p_from and p_to and s.steps >= 8000)
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

-- Add "Hit 8,000 steps" to the Forge Week template for future weeks.
update public.quest_templates
set objectives = objectives || '[{"name": "Hit 8,000 steps", "detail": "5 days this week", "metric": "step_days", "target": 5}]'::jsonb
where id = 'weekly-forge'
  and not exists (
    select 1 from jsonb_array_elements(objectives) elem
    where elem->>'metric' = 'step_days'
  );

-- Backfill any active Forge Week quest so it appears immediately this week.
insert into public.quest_objectives (quest_id, position, name, detail, metric, target)
select
  q.id,
  (select coalesce(max(o.position), 0) + 1 from public.quest_objectives o where o.quest_id = q.id),
  'Hit 8,000 steps',
  '5 days this week',
  'step_days',
  5
from public.quests q
where q.kind = 'weekly'
  and q.title = 'Forge Week'
  and q.ends_on >= current_date
  and not exists (
    select 1 from public.quest_objectives o
    where o.quest_id = q.id and o.metric = 'step_days'
  );
