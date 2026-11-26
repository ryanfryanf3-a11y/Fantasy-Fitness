drop function if exists public.grant_random_item(uuid, public.rarity, text);

create function public.grant_random_item(p_user uuid, p_rarity public.rarity, p_source text)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_item text;
  v_inventory_id uuid;
  v_rarity public.rarity := p_rarity;
  v_attack integer := 0;
  v_defense integer := 0;
  v_attack_bonus integer := 0;
  v_defense_bonus integer := 0;
  v_hp integer := 0;
  v_regeneration integer := 0;
  v_hit_chance numeric(5, 4) := 0;
  v_crit_chance numeric(5, 4) := 0;
  v_random_attributes public.random_attribute_lookups%rowtype;
begin
  if p_rarity is null then
    return null;
  end if;

  v_rarity := least(v_rarity, 'epic'::public.rarity);

  while v_rarity <> 'epic' and random() < 0.2 loop
    v_rarity := case v_rarity
      when 'common' then 'uncommon'::public.rarity
      when 'uncommon' then 'rare'::public.rarity
      when 'rare' then 'epic'::public.rarity
      else v_rarity
    end;
  end loop;

  select i.id, i.attack_bonus, i.defense_bonus
  into v_item, v_attack_bonus, v_defense_bonus
  from public.items i
  where i.rarity >= v_rarity
    and i.droppable
  order by i.rarity, random()
  limit 1;

  if v_item is null then
    return null;
  end if;

  v_attack := v_attack + v_attack_bonus;
  v_defense := v_defense + v_defense_bonus;

  if v_rarity >= 'uncommon' then
    select * into v_random_attributes
    from public.random_attribute_lookups
    order by random()
    limit 1;

    if found then
      v_attack := v_attack + v_random_attributes.attack;
      v_defense := v_defense + v_random_attributes.defense;
      v_hp := v_hp + v_random_attributes.hp;
      v_regeneration := v_regeneration + v_random_attributes.regeneration;
      v_hit_chance := v_hit_chance + v_random_attributes.hit_chance;
      v_crit_chance := v_crit_chance + v_random_attributes.crit_chance;
    end if;
  end if;

  if v_rarity >= 'epic' then
    select * into v_random_attributes
    from public.random_attribute_lookups
    order by random()
    limit 1;

    if found then
      v_attack := v_attack + v_random_attributes.attack;
      v_defense := v_defense + v_random_attributes.defense;
      v_hp := v_hp + v_random_attributes.hp;
      v_regeneration := v_regeneration + v_random_attributes.regeneration;
      v_hit_chance := v_hit_chance + v_random_attributes.hit_chance;
      v_crit_chance := v_crit_chance + v_random_attributes.crit_chance;
    end if;
  end if;

  insert into public.inventory (
    user_id, item_id, source, attack, defense, hp, regeneration, hit_chance, crit_chance
  )
  values (
    p_user, v_item, p_source, v_attack, v_defense, v_hp, v_regeneration, v_hit_chance, v_crit_chance
  )
  returning id into v_inventory_id;

  return v_inventory_id;
end;
$$;

revoke execute on function public.grant_random_item(uuid, public.rarity, text)
  from public, anon, authenticated;