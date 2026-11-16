-- RUMBO / Sprint 2 / Persona 2 / Enrollments (US-05 a US-08).
-- Depende de 20261105000100_create_plans.sql y las migraciones de Auth.
-- Aplicar con el equipo en orden. Nunca ejecutar db reset --linked.

create table public.inscripcion (
  id_inscripcion uuid primary key default gen_random_uuid(),
  id_usuario uuid not null references public.usuario(id_usuario) on delete cascade,
  id_plan uuid not null references public.plan(id_plan) on delete cascade,
  fecha_inscripcion timestamptz not null default now(),
  estado varchar(20) not null,
  updated_at timestamptz not null default now(),
  constraint inscripcion_estado_valido check (
    estado in ('pendiente', 'confirmada', 'cancelada', 'rechazada')
  ),
  constraint inscripcion_usuario_plan_unico unique (id_usuario, id_plan)
);

create index inscripcion_plan_estado_idx on public.inscripcion (id_plan, estado);
create index inscripcion_usuario_fecha_idx on public.inscripcion (id_usuario, fecha_inscripcion desc);

alter table public.inscripcion enable row level security;
revoke all on public.inscripcion from public, anon, authenticated;
grant select on public.inscripcion to authenticated;

-- La consulta está restringida al inscrito y al organizador propietario.
-- Las escrituras se realizan ÚNICAMENTE a través de funciones RPC autorizadas.
create policy inscripcion_leer_propia_o_como_organizador
on public.inscripcion for select to authenticated
using (
  id_usuario = (select auth.uid())
  or exists (
    select 1 from public.plan p
    where p.id_plan = inscripcion.id_plan
      and p.id_organizador = (select auth.uid())
  )
);

-- Inscripción atómica: bloquear PLAN serializa las reservas del último cupo.
-- El organizador puede participar en planes de otros, pero no en el propio.
create function public.inscribirse_en_plan(p_plan_id uuid)
returns public.inscripcion
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := (select auth.uid());
  v_plan public.plan%rowtype;
  v_actual public.inscripcion%rowtype;
  v_confirmados integer;
  v_estado text;
  v_resultado public.inscripcion%rowtype;
begin
  if v_usuario is null then
    raise exception 'Debes iniciar sesión para inscribirte';
  end if;

  select * into v_plan from public.plan where id_plan = p_plan_id for update;
  if not found then raise exception 'No se encontró el plan'; end if;
  if v_plan.estado <> 'publicado' or v_plan.fecha_inicio <= now() then
    raise exception 'Este plan no admite nuevas inscripciones';
  end if;
  if v_plan.id_organizador = v_usuario then
    raise exception 'No puedes inscribirte a tu propio plan';
  end if;

  select * into v_actual from public.inscripcion
  where id_plan = p_plan_id and id_usuario = v_usuario for update;
  if found and v_actual.estado in ('pendiente', 'confirmada') then
    raise exception 'Ya tienes una inscripción activa en este plan';
  end if;

  select count(*)::integer into v_confirmados from public.inscripcion
  where id_plan = p_plan_id and estado = 'confirmada';
  if v_confirmados >= v_plan.cupos_maximos then
    raise exception 'No quedan cupos disponibles';
  end if;

  v_estado := case when v_plan.modalidad = 'privado'
    then 'pendiente' else 'confirmada' end;

  insert into public.inscripcion (id_usuario, id_plan, estado)
  values (v_usuario, p_plan_id, v_estado)
  on conflict (id_usuario, id_plan) do update set
    estado = excluded.estado,
    fecha_inscripcion = now(),
    updated_at = now()
  returning * into v_resultado;

  return v_resultado;
end;
$$;

create function public.cancelar_inscripcion(p_plan_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := (select auth.uid());
  v_plan_id uuid;
begin
  if v_usuario is null then raise exception 'Debes iniciar sesión'; end if;
  -- Bloquear el plan mantiene el mismo orden de locks para toda operación.
  select id_plan into v_plan_id from public.plan
    where id_plan = p_plan_id for update;
  if not found then raise exception 'No se encontró el plan'; end if;

  update public.inscripcion
  set estado = 'cancelada', updated_at = now()
  where id_plan = p_plan_id and id_usuario = v_usuario
    and estado in ('pendiente', 'confirmada');
  if not found then raise exception 'No tienes una inscripción activa'; end if;
end;
$$;

-- Implementación adicional: solicitudes de planes privados.
create function public.resolver_solicitud_inscripcion(
  p_inscripcion_id uuid, p_aprobar boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := (select auth.uid());
  v_plan public.plan%rowtype;
  v_inscripcion public.inscripcion%rowtype;
  v_confirmados integer;
begin
  if v_usuario is null then raise exception 'Debes iniciar sesión'; end if;
  -- Consultar el identificador primero, bloquear PLAN antes de INSCRIPCION.
  select p.* into v_plan
  from public.plan p
  where p.id_plan = (
    select i.id_plan from public.inscripcion i
    where i.id_inscripcion = p_inscripcion_id
  ) for update;
  if not found then raise exception 'Solicitud no encontrada'; end if;
  if v_plan.id_organizador <> v_usuario then
    raise exception 'Solo el organizador puede gestionar solicitudes';
  end if;
  select * into v_inscripcion from public.inscripcion
    where id_inscripcion = p_inscripcion_id for update;
  if not found or v_inscripcion.estado <> 'pendiente' then
    raise exception 'La solicitud ya no está pendiente';
  end if;
  if p_aprobar then
    if v_plan.estado <> 'publicado' or v_plan.fecha_inicio <= now() then
      raise exception 'Este plan ya no admite confirmaciones';
    end if;
    select count(*)::integer into v_confirmados from public.inscripcion
      where id_plan = v_plan.id_plan and estado = 'confirmada';
    if v_confirmados >= v_plan.cupos_maximos then
      raise exception 'No quedan cupos disponibles';
    end if;
  end if;
  update public.inscripcion set
    estado = case when p_aprobar then 'confirmada' else 'rechazada' end,
    updated_at = now()
  where id_inscripcion = p_inscripcion_id;
end;
$$;

-- Agregado seguro que no expone identidades de otros participantes.
create function public.consultar_cupos_plan(p_plan_id uuid)
returns table (
  cupos_ocupados integer, cupos_maximos integer, solicitudes_pendientes integer
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := (select auth.uid());
  v_plan public.plan%rowtype;
begin
  if v_usuario is null then raise exception 'Debes iniciar sesión'; end if;
  select * into v_plan from public.plan where id_plan = p_plan_id;
  if not found or (
    v_plan.estado = 'borrador' and v_plan.id_organizador <> v_usuario
  ) then
    raise exception 'Plan no disponible';
  end if;

  return query
    select count(*) filter (where i.estado = 'confirmada')::integer,
      v_plan.cupos_maximos,
      case when v_plan.id_organizador = v_usuario
        then count(*) filter (where i.estado = 'pendiente')::integer
        else 0::integer end
    from public.inscripcion i where i.id_plan = p_plan_id;
end;
$$;

-- El organizador no puede reducir cupos por debajo de los ya confirmados.
create function public.inscripcion_validar_reduccion_cupos()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_confirmados integer;
begin
  if new.cupos_maximos is distinct from old.cupos_maximos
      and new.cupos_maximos is not null then
    select count(*)::integer into v_confirmados
    from public.inscripcion where id_plan = new.id_plan
      and estado = 'confirmada';
    if v_confirmados > new.cupos_maximos then
      raise exception 'No puedes reducir cupos por debajo de los inscritos confirmados';
    end if;
  end if;
  return new;
end;
$$;

create trigger rumbo_inscripcion_validar_reduccion_cupos
before update of cupos_maximos on public.plan
for each row execute function public.inscripcion_validar_reduccion_cupos();

-- La ejecución de SECURITY DEFINER se restringe a usuarios autenticados.
revoke all on function public.inscribirse_en_plan(uuid) from public, anon, authenticated;
revoke all on function public.cancelar_inscripcion(uuid) from public, anon, authenticated;
revoke all on function public.resolver_solicitud_inscripcion(uuid, boolean) from public, anon, authenticated;
revoke all on function public.consultar_cupos_plan(uuid) from public, anon, authenticated;
revoke all on function public.inscripcion_validar_reduccion_cupos() from public, anon, authenticated;
grant execute on function public.inscribirse_en_plan(uuid) to authenticated;
grant execute on function public.cancelar_inscripcion(uuid) to authenticated;
grant execute on function public.resolver_solicitud_inscripcion(uuid, boolean) to authenticated;
grant execute on function public.consultar_cupos_plan(uuid) to authenticated;
