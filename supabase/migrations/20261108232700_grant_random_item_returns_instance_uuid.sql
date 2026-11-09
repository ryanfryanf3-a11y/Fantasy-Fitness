--Apply after inventory update migration
-- Return the UUID of the inventory row created, not the shared catalog item ID.
drop function if exists public.grant_random_item(uuid, public.rarity, text);

create function public.grant_random_item(p_user uuid, p_rarity public.rarity, p_source text)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_item text;
  v_inventory_id uuid;
begin
  if p_rarity is null then
    return null;
  end if;

  select i.id into v_item
  from public.items i
  where i.rarity >= p_rarity
    and i.droppable
    and not exists (
      select 1 from public.inventory inv
      where inv.user_id = p_user and inv.item_id = i.id
    )
  order by i.rarity, random()
  limit 1;

  if v_item is null then
    return null;
  end if;

  insert into public.inventory (user_id, item_id, source)
  values (p_user, v_item, p_source)
  returning id into v_inventory_id;

  return v_inventory_id;
end;
$$;

revoke execute on function public.grant_random_item(uuid, public.rarity, text)
  from public, anon, authenticated;

-- Keep the existing catalog IDs for older clients and expose the instance IDs as well.
create or replace function public.finish_dungeon_run(p_run_id uuid, p_victory boolean)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_user uuid := auth.uid();
  r public.dungeon_runs;
  d public.dungeons;
  v_xp integer := 0;
  v_instance_ids text[] := '{}';
  v_item_id text;
  v_item_ids text[] := '{}';
begin
  update public.dungeon_runs
  set finished_at = now(), victory = p_victory
  where id = p_run_id and user_id = v_user and finished_at is null
  returning * into r;
  if not found then
    raise exception 'Run not found or already finished';
  end if;

  select * into d from public.dungeons where id = r.dungeon_id;

  if p_victory then
    v_xp := 40 * d.energy_cost;
    update public.profiles set xp = xp + v_xp where id = v_user;

    v_item_id := public.grant_random_item(v_user, d.loot_rarity, 'dungeon')::text;
    if v_item_id is not null then
      v_instance_ids := v_instance_ids || v_item_id;
    end if;

    v_item_id := public.grant_random_item(v_user, 'common', 'dungeon')::text;
    if v_item_id is not null then
      v_instance_ids := v_instance_ids || v_item_id;
    end if;

    select coalesce(array_agg(inv.item_id order by granted.ordinality), '{}')
    into v_item_ids
    from unnest(v_instance_ids) with ordinality as granted(instance_id, ordinality)
    join public.inventory inv on inv.id = granted.instance_id::uuid and inv.user_id = v_user;

    update public.dungeon_runs
    set xp_awarded = v_xp, loot_item_ids = v_item_ids
    where id = r.id;
  end if;

  return jsonb_build_object(
    'xp', v_xp,
    'item_ids', to_jsonb(v_item_ids),
    'inventory_ids', to_jsonb(v_instance_ids),
    'chest_rarity', d.loot_rarity
  );
end;
$$;
