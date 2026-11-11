-- RUMBO / Sprint 2 / Persona 1 / Plans
-- Base: migraciones de Auth (usuario.id_usuario UUID y rol en public.usuario).
-- NO ejecutar sin revisión del equipo: Supabase remoto es compartido.
-- Los borradores requieren titulo, descripcion y lugar. Publicar exige los demás
-- campos básicos. La cancelación por falta de cupos se integrará con Enrollments.

-- 1) Catálogo: exactamente un tipo principal de actividad por plan.
-- Se mantiene separado de INTERES (preferencias de usuario ≠ actividad del plan).
create table public.tipo_actividad (
  id_tipo_actividad bigint generated always as identity primary key,
  nombre varchar(80) not null unique
    check (length(btrim(nombre)) > 0)
);

insert into public.tipo_actividad (nombre) values
  ('Senderismo'),
  ('Ciclismo'),
  ('Camping'),
  ('Avistamiento de aves'),
  ('Fotografía'),
  ('Picnic'),
  ('Caminata ecológica'),
  ('Otra actividad');

-- 2) Entidad PLAN.
create table public.plan (
  id_plan uuid primary key default gen_random_uuid(),
  id_organizador uuid not null
    references public.usuario(id_usuario) on delete restrict,

  -- Obligatorios también para guardar un borrador.
  titulo varchar(120) not null,
  descripcion text not null,
  lugar varchar(150) not null,

  -- Pueden quedar pendientes mientras el plan está en borrador.
  fecha_inicio timestamptz,
  id_tipo_actividad bigint
    references public.tipo_actividad(id_tipo_actividad),
  modalidad varchar(20),
  cupos_minimos integer,
  cupos_maximos integer,
  presupuesto numeric(10,2),  -- estimado POR PARTICIPANTE, en COP; 0 = gratis

  -- Información opcional para cualquier tipo de actividad.
  distancia_km numeric(6,2),
  dificultad varchar(20),
  imagen text,

  estado varchar(20) not null default 'borrador',
  motivo_cancelacion varchar(60),
  cancelado_en timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint plan_titulo_no_vacio check (length(btrim(titulo)) > 0),
  constraint plan_descripcion_no_vacia check (length(btrim(descripcion)) > 0),
  constraint plan_lugar_no_vacio check (length(btrim(lugar)) > 0),
  constraint plan_estado_valido
    check (estado in ('borrador','publicado','cancelado','finalizado')),
  constraint plan_modalidad_valida
    check (modalidad is null or modalidad in ('publico','privado')),
  constraint plan_dificultad_valida
    check (dificultad is null or dificultad in ('suave','media','exigente')),
  constraint plan_cupos_minimos_validos
    check (cupos_minimos is null or cupos_minimos > 0),
  constraint plan_cupos_maximos_validos
    check (cupos_maximos is null or cupos_maximos > 0),
  constraint plan_relacion_cupos_valida
    check (cupos_minimos is null or cupos_maximos is null
           or cupos_minimos <= cupos_maximos),
  constraint plan_presupuesto_no_negativo
    check (presupuesto is null or presupuesto >= 0),
  constraint plan_distancia_no_negativa
    check (distancia_km is null or distancia_km >= 0),

  -- CHECK no consulta otras tablas: valida solo la integridad de PLAN.
  -- La condición de organizador se verifica por RLS + trigger.
  constraint plan_campos_requeridos_al_publicar check (
    estado = 'borrador'
    or (
      fecha_inicio is not null
      and id_tipo_actividad is not null
      and modalidad is not null
      and cupos_minimos is not null
      and cupos_maximos is not null
      and presupuesto is not null
    )
  )
);

create index plan_estado_fecha_idx on public.plan (estado, fecha_inicio);
create index plan_organizador_fecha_idx on public.plan (id_organizador, fecha_inicio);
create index plan_tipo_actividad_idx on public.plan (id_tipo_actividad);

-- 3) Reglas de transición y autorización adicional, incluso ante escrituras
-- administrativas que puedan saltarse RLS. No se confía en ocultar botones.
create function public.plan_validar_cambios()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  rol_propietario text;
begin
  if tg_op = 'INSERT' then
    select u.rol into rol_propietario
    from public.usuario u
    where u.id_usuario = new.id_organizador;

    if rol_propietario is distinct from 'organizador' then
      raise exception 'Solo un organizador autorizado puede crear planes';
    end if;

    if new.estado not in ('borrador', 'publicado') then
      raise exception 'Un plan nuevo solo puede iniciar como borrador o publicado';
    end if;

    if new.estado = 'publicado' and new.fecha_inicio <= now() then
      raise exception 'No se puede publicar una actividad con fecha pasada';
    end if;

    -- Las marcas de auditoría y cancelación no las fija el cliente.
    new.created_at := now();
    new.updated_at := now();
    new.cancelado_en := null;
    new.motivo_cancelacion := null;
    return new;
  end if;

  if new.id_organizador is distinct from old.id_organizador then
    raise exception 'No se puede transferir el organizador de un plan';
  end if;

  if old.estado in ('cancelado', 'finalizado') then
    raise exception 'Un plan cancelado o finalizado no puede modificarse';
  end if;

  if old.estado = 'borrador' then
    if new.estado not in ('borrador', 'publicado') then
      raise exception 'El borrador debe publicarse o eliminarse';
    end if;
  elsif old.estado = 'publicado' then
    if new.estado not in ('publicado', 'cancelado', 'finalizado') then
      raise exception 'Transición de estado no permitida';
    end if;
    if new.modalidad is distinct from old.modalidad then
      raise exception 'No se puede modificar la modalidad después de publicar';
    end if;
  end if;

  if new.estado = 'publicado'
     and (old.estado <> 'publicado'
          or new.fecha_inicio is distinct from old.fecha_inicio)
     and new.fecha_inicio <= now() then
    raise exception 'La fecha de un plan publicado debe estar en el futuro';
  end if;

  if new.estado = 'finalizado' and new.fecha_inicio > now() then
    raise exception 'No se puede finalizar un plan antes de su fecha de inicio';
  end if;

  if new.estado = 'cancelado' and old.estado <> 'cancelado' then
    new.motivo_cancelacion := coalesce(
      nullif(btrim(new.motivo_cancelacion), ''),
      'cancelacion_organizador'
    );
    new.cancelado_en := now();
  else
    new.motivo_cancelacion := null;
    new.cancelado_en := null;
  end if;

  new.created_at := old.created_at;
  new.updated_at := now();
  return new;
end;
$$;

revoke all on function public.plan_validar_cambios() from public;
revoke all on function public.plan_validar_cambios() from anon, authenticated;

create trigger rumbo_plan_validar_cambios
before insert or update on public.plan
for each row execute function public.plan_validar_cambios();

-- 4) RLS y permisos. Auth ya controla quién puede editar su propio rol.
alter table public.tipo_actividad enable row level security;
alter table public.plan enable row level security;

revoke all on public.tipo_actividad from anon, authenticated;
revoke all on public.plan from anon, authenticated;

grant select on public.tipo_actividad to authenticated;
grant select, insert, delete on public.plan to authenticated;
-- No permitimos cambiar id_plan, id_organizador ni timestamps desde el cliente.
grant update (
  titulo, descripcion, lugar, fecha_inicio, id_tipo_actividad,
  modalidad, cupos_minimos, cupos_maximos, presupuesto,
  distancia_km, dificultad, imagen, estado, motivo_cancelacion
) on public.plan to authenticated;

create policy tipo_actividad_catalogo_leer
on public.tipo_actividad for select to authenticated
using (true);

create policy plan_leer_publicados_y_propios
on public.plan for select to authenticated
using (
  estado in ('publicado', 'cancelado', 'finalizado')
  or id_organizador = (select auth.uid())
);

create policy plan_crear_solo_organizador
on public.plan for insert to authenticated
with check (
  id_organizador = (select auth.uid())
  and exists (
    select 1 from public.usuario u
    where u.id_usuario = (select auth.uid())
      and u.rol = 'organizador'
  )
);

create policy plan_editar_solo_organizador_propietario
on public.plan for update to authenticated
using (
  id_organizador = (select auth.uid())
  and estado in ('borrador', 'publicado')
  and exists (
    select 1 from public.usuario u
    where u.id_usuario = (select auth.uid())
      and u.rol = 'organizador'
  )
)
with check (
  id_organizador = (select auth.uid())
  and exists (
    select 1 from public.usuario u
    where u.id_usuario = (select auth.uid())
      and u.rol = 'organizador'
  )
);

-- Solo se eliminan borradores propios. Los publicados se cancelan,
-- y sus registros se conservan para historia y futuras inscripciones.
create policy plan_borrar_solo_borrador_propio
on public.plan for delete to authenticated
using (
  id_organizador = (select auth.uid())
  and estado = 'borrador'
  and exists (
    select 1 from public.usuario u
    where u.id_usuario = (select auth.uid())
      and u.rol = 'organizador'
  )
);

-- No se crea aún el job pg_cron: necesita la tabla INSCRIPCION de Persona 2.
-- En esa integración se implementará la verificación continua de cupos desde
-- T-24h hasta la hora de inicio, contando solo inscritos CONFIRMADOS.
