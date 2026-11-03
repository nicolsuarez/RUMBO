-- Sprint 1 RUMBO: USUARIO, INTERES y USUARIO_INTERES del modelo conceptual.
-- La aprobación de organizadores NO está implementada aun.
create table public.usuario (
 id_usuario uuid primary key references auth.users(id) on delete cascade,
 nombre varchar(100) not null check (length(trim(nombre)) >= 3),
 correo varchar(120) not null,
 telefono varchar(20) not null,
 username varchar(20) not null unique check (username ~ '^[a-z0-9_]{3,20}$'),
 fecha_nacimiento date not null,
 rol varchar(20) not null default 'participante' check (rol in ('participante', 'organizador')),
 foto varchar(255),
 fecha_registro timestamptz not null default now(),
 constraint usuario_mayor_edad check (fecha_nacimiento <= (current_date - interval '18 years')::date),
 constraint usuario_fecha_razonable check (fecha_nacimiento >= date '1900-01-01')
);
create unique index usuario_correo_ci on public.usuario(lower(correo));
create table public.interes (
 id_interes bigint generated always as identity primary key,
 nombre varchar(60) not null unique
);
create table public.usuario_interes (
 id_usuario uuid not null references public.usuario(id_usuario) on delete cascade,
 id_interes bigint not null references public.interes(id_interes),
 primary key (id_usuario, id_interes)
);
insert into public.interes(nombre) values
 ('Senderismo'),('Avistamiento de aves'),('Ciclismo'),('Camping'),
 ('Fotografía'),('Amaneceres'),('Atardeceres'),('Ríos'),('Cascadas'),
 ('Montañismo'),('Trekking'),('Naturaleza'),('Ecoturismo'),
 ('Trail running'),('Caminatas ecológicas'),('Observación de fauna'),
 ('Flora'),('Paisajismo'),('Picnic'),('Astronomía'),('Aventura'),
 ('Viajes'),('Bienestar'),('Actividades en grupo');

-- La creación de perfil y relaciones es atómica con el alta en auth.users.
-- Un error en la metadata impide el registro y debe tratarse en la UI.
create or replace function public.handle_rumbo_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
 requested jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
 selected_interest text;
 raw_birth text;
begin
 raw_birth := requested ->> 'fecha_nacimiento';
 if raw_birth is null or length(raw_birth) <> 10 then
   raise exception 'Falta fecha de nacimiento';
 end if;
 if raw_birth::date > (current_date - interval '18 years')::date then
   raise exception 'Debes tener al menos 18 años';
 end if;
 if jsonb_typeof(requested -> 'intereses') is distinct from 'array'
    or jsonb_array_length(requested -> 'intereses') = 0 then
   raise exception 'Selecciona al menos un interés';
 end if;
 insert into public.usuario (id_usuario,nombre,correo,telefono,username,fecha_nacimiento,rol)
 values (new.id, trim(requested ->> 'nombre'), new.email,
         trim(requested ->> 'telefono'), lower(trim(requested ->> 'username')),
         raw_birth::date, 'participante');
 for selected_interest in select jsonb_array_elements_text(requested -> 'intereses') loop
   insert into public.usuario_interes(id_usuario,id_interes)
   select new.id, i.id_interes from public.interes i where i.nombre = selected_interest
   on conflict do nothing;
 end loop;
 if not exists(select 1 from public.usuario_interes where id_usuario = new.id) then
   raise exception 'No se encontraron intereses válidos';
 end if;
 return new;
end;
$$;
create trigger rumbo_on_auth_user_created after insert on auth.users
for each row execute function public.handle_rumbo_new_user();

alter table public.usuario enable row level security;
alter table public.interes enable row level security;
alter table public.usuario_interes enable row level security;

revoke all on public.usuario from anon, authenticated;
revoke all on public.interes from anon, authenticated;
revoke all on public.usuario_interes from anon, authenticated;
grant select on public.usuario to authenticated;
-- Las columnas 'rol' e 'id_usuario' nunca son editables por el cliente.
grant update(nombre,telefono,foto) on public.usuario to authenticated;
grant select on public.interes to authenticated;
grant select on public.usuario_interes to authenticated;
create policy usuario_ver_propio on public.usuario for select to authenticated
 using ((select auth.uid()) = id_usuario);
create policy usuario_editar_propio on public.usuario for update to authenticated
 using ((select auth.uid()) = id_usuario) with check ((select auth.uid()) = id_usuario);
create policy interes_catalogo on public.interes for select to authenticated using (true);
create policy usuario_interes_ver_propio on public.usuario_interes for select to authenticated
 using ((select auth.uid()) = id_usuario);

-- Sin permiso de inserción/actualización de rol desde Flutter.
-- La elevación futura a organizador requerirá backend administrativo seguro.
