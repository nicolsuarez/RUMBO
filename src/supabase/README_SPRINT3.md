# RUMBO — contrato de base de datos Sprint 3

Estado: candidato preparado, revisado estáticamente contra el ZIP posterior a FIX-01/02. No aplicado ni ejecutado en PostgreSQL. Validar antes de desplegar. Rama propuesta: `feature/sprint3-preparar-db`.

Persona 1 administra las migraciones. Chat (Persona 2), Routes (Persona 1) y Safety (Laura) consumen este contrato. No modificar migraciones existentes ni nombres, tipos, restricciones, RLS o RPC publicadas; las extensiones compatibles deben proponerse y coordinarse con Persona 1 mediante una nueva migración. No ejecutar SQL por separado en el Supabase compartido.

## Migraciones (en orden)

- `20261126000100_create_routes.sql`: recorrido, dos reglas de unicidad, integridad con inscripción, RLS y RPC.
- `20261126000200_create_chat.sql`: mensaje, membresía, RLS y consulta autorizada de nombres.
- `20261126000300_create_emergency_contacts.sql`: contactos propios, CRUD mediante RLS.
- `20261126000400_create_sos_alerts.sql`: alertas relacionadas con recorrido, RLS y RPC.

No se sustituyen migraciones del Sprint 2. Única adición a una tabla existente: restricción UNIQUE de `(id_inscripcion,id_usuario,id_plan)` en `inscripcion`, para permitir la FK compuesta de `recorrido`.

## Routes

`recorrido`: `id_recorrido` UUID PK, `id_inscripcion`, `id_usuario`, `id_plan` UUID obligatorios y coherentes, `inicio`/`fin` timestamptz (fin nulo hasta finalizar), `distancia_recorrida` numeric(6,2), `porcentaje_avance` numeric(5,2), `estado` varchar(20): `activo`, `pausado`, `finalizado`.

- SELECT de filas propias; sin INSERT/UPDATE/DELETE directo.
- `iniciar_recorrido(p_plan_id uuid)` devuelve una fila de recorrido. Autenticado, plan publicado, inscripción confirmada. Se admite inicio anticipado; un recorrido por usuario/plan, uno en curso por usuario.
- `actualizar_recorrido(p_recorrido_id uuid,p_accion text,p_porcentaje_avance numeric DEFAULT NULL)` devuelve la fila actualizada. Acciones `avanzar` (porcentaje absoluto no decreciente, 0–100), `pausar`, `reanudar`, `finalizar` (no fuerza 100%). Solo avanzar acepta porcentaje. Plan no publicado o inscripción no confirmada bloquean avanzar/reanudar, no finalizar. Si se cancela, la pantalla debe detener el temporizador al recibir el error y ofrecer finalización.
- Para recuperar, consultar la fila propia por plan o estados activo/pausado; no reiniciar el progreso. Al llegar a 100%, la UI puede pedir finalización explícita. La distancia ilustrativa usa distancia_km disponible del plan y no decrece; si falta distancia, la UI debe indicar que no hay estimación. No es GPS.

## Chat

`mensaje`: `id_mensaje`, `id_plan`, `id_usuario` UUID, `contenido` text, `fecha_hora` timestamptz. El servidor genera ID, fecha e identidad por defecto. El cliente inserta `id_plan` y `contenido` (opcional `id_usuario` propio). Texto de 1–2000 caracteres tras quitar espacios de borde. SELECT/INSERT solo organizador propietario o inscrito confirmado; no editar/borrar mensajes desde Flutter. `puede_acceder_chat(p_plan_id uuid)` devuelve bool. `consultar_mensajes_plan(p_plan_id uuid)` devuelve lista con los cinco campos y `nombre_remitente` (únicamente nombre, no otros datos privados); orden por fecha_hora e id_mensaje. No requiere Realtime. La membresía se vuelve a verificar en cada consulta/escritura.

## Safety

`contacto_emergencia`: `id_contacto` UUID PK, `id_usuario` UUID, `nombre` varchar(100), `telefono` varchar(20), `parentesco` varchar(40) opcional. Nombre no vacío, teléfono con 7–15 dígitos y formato básico; CRUD de filas propias, sin cambiar dueño ni ID. Para insertar, omitir ID y usuario (servidor los genera).

`alerta_sos`: `id_alerta` UUID PK, `id_recorrido` UUID FK, `fecha_hora` timestamptz, `tipo` varchar(40) (`manual`/`desvio`), `estado` varchar(20) (`simulada`), `latitud`/`longitud` numeric(10,7) nulos en MVP. SELECT de alertas propias por recorrido. Crear solo mediante `registrar_alerta_sos(p_recorrido_id uuid,p_tipo text,p_confirmado boolean)`; debe ser recorrido propio activo o pausado, confirmación explícita true, devuelve fila. Los dos tipos usan la misma RPC. Desvío y SOS no se notifican a nadie; sin ubicación real. No exigir contactos de emergencia para registrar la alerta de prueba.

## Verificación y despliegue

1. Revisar `git status`, historial de migraciones remoto y esquema remoto. No continuar ante diferencias inesperadas.
2. En Supabase local/de pruebas, aplicar migraciones y ejecutar `verification/sprint3_smoke.sql` como postgres en una sola sesión; crea fixtures ficticios dentro de una transacción y termina con ROLLBACK. No ejecutarlo contra el proyecto compartido. Verificar manualmente concurrencia de inicios y finalización/SOS en dos sesiones; comprobar permisos anónimos y errores adicionales (rechazada, cancelada, plan cancelado, progreso regresivo, inicio repetido tras finalizar/reinscribirse).
3. Revisar `npx supabase db push --dry-run` en el proyecto correcto. Deben aparecer únicamente las cuatro migraciones nuevas; si aparecen otras, detenerse. Aplicación real solo tras revisión de SQL y pruebas.
4. Aplicar una vez, comprobar `npx supabase migration list`, probar con cuentas autorizadas, versionar y abrir PR hacia develop. Compartir contrato PDF actualizado con el commit y el estado real de aplicación.

Decisiones nuevas propuestas para el mínimo: RPC únicas de actualización de recorrido y de alerta; mensaje máximo 2000; parentesco opcional; estado de alerta `simulada`; coordenadas siempre nulas; lectura de nombres limitada por membresía. No se han confirmado con el equipo. El contrato se puede extender de manera compatible, pero no romper unilateralmente.
