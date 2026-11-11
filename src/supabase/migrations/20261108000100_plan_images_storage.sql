-- RUMBO / Sprint 2 / Persona 1 / Plans: imágenes de los planes.
-- PRECONDICIÓN: 20261105000100_create_plans.sql ya aplicada.
-- Revisar con el equipo antes de ejecutar: Supabase remoto es compartido.
-- La columna public.plan.imagen ya existe: almacena el PATH relativo del objeto,
-- no su URL pública (ej.: <uuid_usuario>/<32-hex>.jpg).

-- Decisión: bucket PUBLICO porque tanto planes públicos como privados son
-- descubribles. Una fotografía de borrador también será accesible para quien
-- conozca su URL. Si se necesitan fotografías realmente privadas, se deberá
-- migrar después a bucket privado + URLs firmadas.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'plan-images',
  'plan-images',
  true,
  5242880, -- 5 MiB
  array['image/jpeg', 'image/png', 'image/webp']::text[]
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Los objetos siempre se crean con path <auth.uid>/<random-hex>.<ext>.
-- Solo un organizador puede subir archivos. Verificación de tipo/tamaño:
-- bucket + validación por firma en Flutter (defensa en profundidad).
create policy plan_images_insert_organizer
on storage.objects for insert to authenticated
with check (
  bucket_id = 'plan-images'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
  and coalesce(array_length(storage.foldername(name), 1), 0) = 1
  and storage.filename(name) ~ '^[0-9a-f]{32}\.(jpg|png|webp)$'
  and exists (
    select 1 from public.usuario u
    where u.id_usuario = (select auth.uid())
      and u.rol = 'organizador'
  )
);

-- El bucket es público para descargas por URL. Esta política de SELECT se
-- requiere para las operaciones autenticadas de Storage, como remove().
create policy plan_images_select_own
on storage.objects for select to authenticated
using (
  bucket_id = 'plan-images'
  and owner_id = (select auth.uid()::text)
);

-- Evitamos borrar fotos aún referenciadas por cualquier plan.
-- Reemplazar foto = actualizar primero public.plan.imagen y borrar después.
create policy plan_images_delete_own_unreferenced
on storage.objects for delete to authenticated
using (
  bucket_id = 'plan-images'
  and owner_id = (select auth.uid()::text)
  and not exists (
    select 1 from public.plan p where p.imagen = storage.objects.name
  )
);

-- Protección de la REFERENCIA en PostgreSQL: RLS de Storage por sí solo
-- no impide que alguien escriba una ruta ajena en public.plan.imagen.
-- Función SECURITY DEFINER para consultar metadata Storage sin depender
-- de la visibilidad de RLS del usuario que guarda el plan.
create function public.plan_verificar_imagen_propia()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.imagen is null then
    return new;
  end if;

  -- Preservar imágenes legadas previamente asociadas sin obligar a subirlas
  -- nuevamente; en cambios de foto sí exigimos propiedad y bucket correcto.
  if tg_op = 'UPDATE' then
    if new.imagen is not distinct from old.imagen then
      return new;
    end if;
  end if;

  if not exists (
    select 1
    from storage.objects o
    where o.bucket_id = 'plan-images'
      and o.name = new.imagen
      and o.owner_id = new.id_organizador::text
  ) then
    raise exception 'La imagen debe pertenecer al organizador y estar en plan-images';
  end if;
  return new;
end;
$$;

create trigger plan_verificar_imagen_propia_trigger
before insert or update of imagen on public.plan
for each row execute function public.plan_verificar_imagen_propia();

-- No alterar columnas de public.plan: imagen ya es text.
-- No escribir directamente en storage.objects: los archivos se manejan
-- exclusivamente por la API de Supabase Storage.
