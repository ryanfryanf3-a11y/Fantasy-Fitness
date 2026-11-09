-- Each inventory row is one owned instance of a catalog item.
alter table public.inventory
  drop constraint if exists inventory_user_id_item_id_key;

-- Store generated, instance-specific properties separately from the shared catalog.
alter table public.inventory
  add column instance_data jsonb not null default '{}'::jsonb,
  add constraint inventory_instance_data_object
    check (jsonb_typeof(instance_data) = 'object');

-- Equip a specific owned instance, replacing any equipped item in the same slot.
drop function if exists public.equip_item(text);

create function public.equip_item(p_inventory_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_slot item_slot;
begin
  select i.slot into v_slot
  from public.inventory inv
  join public.items i on i.id = inv.item_id
  where inv.user_id = auth.uid()
    and inv.id = p_inventory_id;

  if not found then
    raise exception 'Item instance not in inventory';
  end if;

  update public.inventory inv
  set equipped = (inv.id = p_inventory_id)
  from public.items i
  where i.id = inv.item_id
    and inv.user_id = auth.uid()
    and i.slot = v_slot;
end;
$$;

revoke execute on function public.equip_item(uuid) from public, anon;
grant execute on function public.equip_item(uuid) to authenticated;

-- Unequip only the specified owned instance.
drop function if exists public.unequip_item(text);

create function public.unequip_item(p_inventory_id uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  update public.inventory
  set equipped = false
  where id = p_inventory_id
    and user_id = auth.uid();

  if not found then
    raise exception 'Item instance not in inventory';
  end if;
end;
$$;

revoke execute on function public.unequip_item(uuid) from public, anon;
grant execute on function public.unequip_item(uuid) to authenticated;


