-- RUMBO Sprint 3 / PB-32. SOS manual y desvío: solo registros simulados.
create table public.alerta_sos (
  id_alerta uuid primary key default gen_random_uuid(),
  id_recorrido uuid not null references public.recorrido(id_recorrido) on delete cascade,
  fecha_hora timestamptz not null default now(),
  tipo varchar(40) not null check (tipo in ('manual','desvio')),
  estado varchar(20) not null default 'simulada' check (estado = 'simulada'),
  latitud numeric(10,7) check (latitud between -90 and 90),
  longitud numeric(10,7) check (longitud between -180 and 180),
  constraint alerta_sos_sin_gps check (latitud is null and longitud is null)
);
create index alerta_sos_recorrido_fecha_idx on public.alerta_sos(id_recorrido,fecha_hora,id_alerta);
alter table public.alerta_sos enable row level security;
revoke all on public.alerta_sos from public, anon, authenticated;
grant select on public.alerta_sos to authenticated;
create policy alerta_sos_leer_propia on public.alerta_sos for select to authenticated
  using (exists (select 1 from public.recorrido r where r.id_recorrido = alerta_sos.id_recorrido
    and r.id_usuario = (select auth.uid())));

-- Bloquear la fila evita crear una alerta después de una finalización concurrente.
-- La confirmación debe pedirse explícitamente también en la interfaz.
create function public.registrar_alerta_sos(p_recorrido_id uuid,p_tipo text,p_confirmado boolean)
returns public.alerta_sos language plpgsql security definer set search_path = '' as $$
declare
  v_usuario uuid := auth.uid();
  v_recorrido public.recorrido%rowtype;
  v_alerta public.alerta_sos%rowtype;
begin
  if v_usuario is null then raise exception 'Debes iniciar sesión'; end if;
  if p_confirmado is distinct from true then raise exception 'Debes confirmar la alerta simulada'; end if;
  if p_tipo is null or p_tipo not in ('manual','desvio') then raise exception 'Tipo de alerta inválido'; end if;
  select * into v_recorrido from public.recorrido
    where id_recorrido = p_recorrido_id and id_usuario = v_usuario for update;
  if not found or v_recorrido.estado not in ('activo','pausado') then
    raise exception 'No tienes un recorrido en curso para esta alerta';
  end if;
  insert into public.alerta_sos(id_recorrido,tipo) values(p_recorrido_id,p_tipo) returning * into v_alerta;
  return v_alerta;
end;
$$;
revoke all on function public.registrar_alerta_sos(uuid,text,boolean) from public, anon, authenticated;
grant execute on function public.registrar_alerta_sos(uuid,text,boolean) to authenticated;
