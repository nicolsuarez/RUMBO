-- RUMBO Sprint 3 / PB-31. CRUD de contactos del titular.
create table public.contacto_emergencia (
  id_contacto uuid primary key default gen_random_uuid(),
  id_usuario uuid not null default auth.uid() references public.usuario(id_usuario) on delete cascade,
  nombre varchar(100) not null check (length(btrim(nombre, E' \t\n\r')) > 0),
  telefono varchar(20) not null check (
    telefono ~ '^\+?[0-9 ()-]+$'
    and length(regexp_replace(telefono,'[^0-9]','','g')) between 7 and 15
  ),
  parentesco varchar(40) check (parentesco is null or length(btrim(parentesco)) > 0)
);
create index contacto_emergencia_usuario_idx on public.contacto_emergencia(id_usuario);
alter table public.contacto_emergencia enable row level security;
revoke all on public.contacto_emergencia from public, anon, authenticated;
grant select, delete on public.contacto_emergencia to authenticated;
grant insert (id_usuario,nombre,telefono,parentesco) on public.contacto_emergencia to authenticated;
grant update (nombre,telefono,parentesco) on public.contacto_emergencia to authenticated;
create policy contacto_leer_propio on public.contacto_emergencia for select to authenticated
  using (id_usuario = (select auth.uid()));
create policy contacto_insertar_propio on public.contacto_emergencia for insert to authenticated
  with check (id_usuario = (select auth.uid()));
create policy contacto_editar_propio on public.contacto_emergencia for update to authenticated
  using (id_usuario = (select auth.uid())) with check (id_usuario = (select auth.uid()));
create policy contacto_borrar_propio on public.contacto_emergencia for delete to authenticated
  using (id_usuario = (select auth.uid()));
