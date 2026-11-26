-- RUMBO Sprint 3 / PB-29, PB-30. Base de datos coordinada por Persona 1.
-- La clave compuesta permite garantizar la correspondencia de la inscripción
-- sin cambiar columnas, políticas ni operaciones existentes de Enrollments.
alter table public.inscripcion add constraint inscripcion_identidad_compuesta
  unique (id_inscripcion, id_usuario, id_plan);

create table public.recorrido (
  id_recorrido uuid primary key default gen_random_uuid(),
  id_inscripcion uuid not null,
  id_usuario uuid not null references public.usuario(id_usuario) on delete cascade,
  id_plan uuid not null references public.plan(id_plan) on delete cascade,
  inicio timestamptz not null default now(),
  fin timestamptz,
  distancia_recorrida numeric(6,2) not null default 0 check (distancia_recorrida >= 0),
  porcentaje_avance numeric(5,2) not null default 0 check (porcentaje_avance between 0 and 100),
  estado varchar(20) not null default 'activo' check (estado in ('activo','pausado','finalizado')),
  constraint recorrido_inscripcion_coherente foreign key (id_inscripcion,id_usuario,id_plan)
    references public.inscripcion(id_inscripcion,id_usuario,id_plan) on delete cascade,
  constraint recorrido_usuario_plan_unico unique (id_usuario,id_plan),
  constraint recorrido_fin_coherente check (
    (estado = 'finalizado' and fin is not null and fin >= inicio)
    or (estado <> 'finalizado' and fin is null)
  )
);
create unique index recorrido_uno_en_curso_por_usuario
  on public.recorrido(id_usuario) where estado in ('activo','pausado');
create index recorrido_plan_idx on public.recorrido(id_plan);
alter table public.recorrido enable row level security;
revoke all on public.recorrido from public, anon, authenticated;
grant select on public.recorrido to authenticated;
create policy recorrido_leer_propio on public.recorrido for select to authenticated
  using (id_usuario = (select auth.uid()));

-- El usuario y la inscripción se resuelven en servidor. Se bloquea PLAN antes
-- de INSCRIPCION, igual que las RPC del Sprint 2. El índice parcial protege
-- también frente a dos inicios simultáneos en planes distintos.
create function public.iniciar_recorrido(p_plan_id uuid)
returns public.recorrido language plpgsql security definer set search_path = '' as $$
declare
  v_usuario uuid := auth.uid();
  v_plan public.plan%rowtype;
  v_inscripcion public.inscripcion%rowtype;
  v_recorrido public.recorrido%rowtype;
begin
  if v_usuario is null then raise exception 'Debes iniciar sesión'; end if;
  select * into v_plan from public.plan where id_plan = p_plan_id for update;
  if not found or v_plan.estado <> 'publicado' then
    raise exception 'El plan no está disponible para iniciar un recorrido';
  end if;
  select * into v_inscripcion from public.inscripcion
    where id_plan = p_plan_id and id_usuario = v_usuario for update;
  if not found or v_inscripcion.estado <> 'confirmada' then
    raise exception 'Necesitas una inscripción confirmada';
  end if;
  if exists (select 1 from public.recorrido where id_usuario = v_usuario and id_plan = p_plan_id) then
    raise exception 'Ya existe un recorrido para este plan';
  end if;
  if exists (select 1 from public.recorrido where id_usuario = v_usuario and estado in ('activo','pausado')) then
    raise exception 'Ya tienes un recorrido en curso';
  end if;
  insert into public.recorrido(id_inscripcion,id_usuario,id_plan)
    values(v_inscripcion.id_inscripcion,v_usuario,p_plan_id) returning * into v_recorrido;
  return v_recorrido;
exception when unique_violation then
  raise exception 'Ya existe un recorrido para este plan o tienes otro en curso';
end;
$$;

-- Una RPC para las cuatro acciones, sin UPDATE directo desde Flutter.
-- Se conserva el porcentaje confirmado por el servidor; finalizar no fuerza 100%.
-- Distancia ilustrativa calculada con la distancia disponible del plan;
-- si falta, no se inventa una distancia (se conserva el valor guardado).
create function public.actualizar_recorrido(
  p_recorrido_id uuid, p_accion text, p_porcentaje_avance numeric default null
) returns public.recorrido language plpgsql security definer set search_path = '' as $$
declare
  v_usuario uuid := auth.uid();
  v_plan_id uuid;
  v_plan public.plan%rowtype;
  v_inscripcion public.inscripcion%rowtype;
  v_recorrido public.recorrido%rowtype;
  v_porcentaje numeric(5,2);
begin
  if v_usuario is null then raise exception 'Debes iniciar sesión'; end if;
  if p_accion is null or p_accion not in ('avanzar','pausar','reanudar','finalizar') then
    raise exception 'Acción de recorrido inválida';
  end if;
  if p_accion <> 'avanzar' and p_porcentaje_avance is not null then
    raise exception 'El porcentaje solo se recibe al avanzar';
  end if;
  select id_plan into v_plan_id from public.recorrido
    where id_recorrido = p_recorrido_id and id_usuario = v_usuario;
  if not found then raise exception 'Recorrido no disponible'; end if;
  select * into v_plan from public.plan where id_plan = v_plan_id for update;
  if not found then raise exception 'Recorrido no disponible'; end if;
  select * into v_inscripcion from public.inscripcion
    where id_plan = v_plan_id and id_usuario = v_usuario for update;
  if not found then raise exception 'Recorrido no disponible'; end if;
  select * into v_recorrido from public.recorrido
    where id_recorrido = p_recorrido_id and id_usuario = v_usuario for update;
  if not found then raise exception 'Recorrido no disponible'; end if;
  if v_recorrido.estado = 'finalizado' then raise exception 'El recorrido ya finalizó'; end if;
  if p_accion in ('avanzar','reanudar') and
    (v_inscripcion.estado <> 'confirmada' or v_plan.estado <> 'publicado') then
    raise exception 'El plan o la inscripción ya no permite continuar. Puedes finalizar el recorrido';
  end if;
  case p_accion
    when 'avanzar' then
      if v_recorrido.estado <> 'activo' then raise exception 'El recorrido no está activo'; end if;
      if p_porcentaje_avance is null or not (p_porcentaje_avance between 0 and 100) then
        raise exception 'Porcentaje inválido';
      end if;
      v_porcentaje := round(p_porcentaje_avance,2);
      if v_porcentaje < v_recorrido.porcentaje_avance then raise exception 'El progreso no puede retroceder'; end if;
      update public.recorrido set porcentaje_avance = v_porcentaje,
        distancia_recorrida = case when v_plan.distancia_km is null then distancia_recorrida
          else greatest(distancia_recorrida, round(v_plan.distancia_km * v_porcentaje / 100, 2)) end
      where id_recorrido = p_recorrido_id returning * into v_recorrido;
    when 'pausar' then
      if v_recorrido.estado <> 'activo' then raise exception 'Solo se puede pausar un recorrido activo'; end if;
      update public.recorrido set estado = 'pausado'
        where id_recorrido = p_recorrido_id returning * into v_recorrido;
    when 'reanudar' then
      if v_recorrido.estado <> 'pausado' then raise exception 'Solo se puede reanudar un recorrido pausado'; end if;
      update public.recorrido set estado = 'activo'
        where id_recorrido = p_recorrido_id returning * into v_recorrido;
    when 'finalizar' then
      update public.recorrido set estado = 'finalizado', fin = greatest(now(),inicio)
        where id_recorrido = p_recorrido_id returning * into v_recorrido;
  end case;
  return v_recorrido;
end;
$$;
revoke all on function public.iniciar_recorrido(uuid) from public, anon, authenticated;
revoke all on function public.actualizar_recorrido(uuid,text,numeric) from public, anon, authenticated;
grant execute on function public.iniciar_recorrido(uuid) to authenticated;
grant execute on function public.actualizar_recorrido(uuid,text,numeric) to authenticated;
