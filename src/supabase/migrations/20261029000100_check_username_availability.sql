
-- Comprueba disponibilidad del username sin exponer
-- información privada de los usuarios.

create or replace function public.is_username_available(
  requested_username text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    requested_username is not null
    and requested_username ~ '^[a-z0-9_]{3,20}$'
    and not exists (
      select 1
      from public.usuario
      where username = requested_username
    );
$$;

-- No conceder acceso automático a todos los roles.
revoke all on function
  public.is_username_available(text)
from public;

-- Puede consultarse antes de iniciar sesión.
grant execute on function
  public.is_username_available(text)
to anon, authenticated;
