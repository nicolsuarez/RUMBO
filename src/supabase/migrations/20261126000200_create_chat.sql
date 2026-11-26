-- RUMBO Sprint 3 / PB-26, PB-27. Chat persistente, sin Realtime obligatorio.
create table public.mensaje (
  id_mensaje uuid primary key default gen_random_uuid(),
  id_plan uuid not null references public.plan(id_plan) on delete cascade,
  id_usuario uuid not null default auth.uid() references public.usuario(id_usuario) on delete cascade,
  contenido text not null check (length(btrim(contenido, E' \t\n\r')) between 1 and 2000),
  fecha_hora timestamptz not null default now()
);
create index mensaje_plan_fecha_idx on public.mensaje(id_plan,fecha_hora,id_mensaje);

-- Reutiliza la membresía real; invoker mantiene las RLS del Sprint 2.
create function public.puede_acceder_chat(p_plan_id uuid)
returns boolean language sql stable security invoker set search_path = '' as $$
  select auth.uid() is not null and (
    exists (select 1 from public.plan p where p.id_plan = p_plan_id and p.id_organizador = auth.uid())
    or exists (select 1 from public.inscripcion i where i.id_plan = p_plan_id
      and i.id_usuario = auth.uid() and i.estado = 'confirmada')
  );
$$;
revoke all on function public.puede_acceder_chat(uuid) from public, anon, authenticated;
grant execute on function public.puede_acceder_chat(uuid) to authenticated;
alter table public.mensaje enable row level security;
revoke all on public.mensaje from public, anon, authenticated;
grant select on public.mensaje to authenticated;
grant insert (id_plan,id_usuario,contenido) on public.mensaje to authenticated;
create policy mensaje_leer_miembros on public.mensaje for select to authenticated
  using (public.puede_acceder_chat(id_plan));
create policy mensaje_insertar_miembros on public.mensaje for insert to authenticated
  with check (id_usuario = (select auth.uid()) and public.puede_acceder_chat(id_plan));

-- Auth solo permite leer el perfil propio. Esta RPC expone únicamente el
-- nombre del remitente de mensajes de un chat autorizado, no su perfil privado.
create function public.consultar_mensajes_plan(p_plan_id uuid)
returns table (id_mensaje uuid,id_plan uuid,id_usuario uuid,contenido text,
  fecha_hora timestamptz,nombre_remitente varchar(100))
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.puede_acceder_chat(p_plan_id) then raise exception 'Chat no autorizado'; end if;
  return query select m.id_mensaje,m.id_plan,m.id_usuario,m.contenido,m.fecha_hora,u.nombre
    from public.mensaje m join public.usuario u on u.id_usuario = m.id_usuario
    where m.id_plan = p_plan_id order by m.fecha_hora,m.id_mensaje;
end;
$$;
revoke all on function public.consultar_mensajes_plan(uuid) from public, anon, authenticated;
grant execute on function public.consultar_mensajes_plan(uuid) to authenticated;
