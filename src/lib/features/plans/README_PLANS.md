# RUMBO — Plans (Sprint 2)

**Responsable:** Persona 1 · **Rama:** `feature/plans` · **Backend:** Supabase/PostgreSQL.

## Decisiones de diseño

- **Estados:** `borrador`, `publicado`, `cancelado`, `finalizado`. Un borrador puede eliminarse; un cancelado no se restaura. La finalización la registra el organizador.
- **Borrador:** requiere solamente `titulo`, `descripcion` y `lugar`. Los demás datos pueden estar en `NULL`. La restricción `CHECK` exige los campos de publicación cuando el estado deja de ser `borrador`.
- **Publicar:** requiere fecha/hora, un tipo de actividad, modalidad, cupos mínimos/máximos y presupuesto; los campos mínimos del borrador siguen siendo obligatorios. `presupuesto` es el **estimado por participante en COP**, y `0` significa gratis.
- **Opcionales siempre:** distancia, dificultad e imagen. No se requiere desnivel ni gráfico de elevación.
- **Actividad:** un único tipo principal por plan, mediante `tipo_actividad` y su referencia en `plan`; no se usa `plan_etiqueta` por ahora. El catálogo es distinto de los intereses del perfil.
- **Modalidad:** `publico` permite inscribirse directamente; `privado` es **visible** pero requiere aprobación. No puede cambiarse después de publicar. La dificultad `exigente` muestra una recomendación de usar aprobación, sin imponerla.
- **Seguridad:** `id_organizador` referencia a `usuario` (UUID). RLS y un trigger restringen creación y cambios al organizador autorizado y propietario. La cuenta de pruebas autorizada es `dummy`.
- **Inscripciones y chat:** los desarrolla Persona 2. Las inscripciones confirmadas determinan cupos ocupados; los mensajes se asociarán al plan mediante `id_plan`, sin añadir `id_chat` a `plan`.
- **Cupos mínimos:** se acordó cancelar automáticamente cuando falten participantes confirmados a partir de las 24 h previas al inicio, incluida una caída posterior del conteo. **Pendiente implementar** con Enrollments y un job `pg_cron`; no está en esta migración.
- **Home:** consumirá las consultas reales de Plans; los detalles finales del panel quedan por definir.

## Cambios frente al modelo conceptual

UUID para identificadores, `descripcion` de tipo `text`, fecha y hora unificadas en `fecha_inicio timestamptz`; se elimina `desnivel_m` y se agregan `modalidad`, `tipo_actividad` (por referencia), auditoría y motivo de cancelación. Se ajustan las restricciones y RLS a PostgreSQL.

## Migración y coordinación

**Archivo:** `src/supabase/migrations/20261105000100_create_plans.sql`. Requiere que las migraciones de Auth ya estén aplicadas.

1. Revisar la migración en `feature/plans` y compartir el contrato `id_plan`/`id_organizador`/estado/modalidad/cupos con Persona 2.
2. Confirmar con el equipo que se puede actualizar la **única base remota compartida**.
3. Desde `src/`: `npx supabase migration list` y `npx supabase db push --dry-run`; verificar que aparezca **solo la migración esperada**.
4. **Solo la persona coordinada** ejecuta `npx supabase db push` y avisa al equipo. No usar `db reset --linked` ni modificar el esquema desde el Dashboard por fuera de migraciones.

**Estado:** migración preparada; aplicación en remoto y pruebas de RLS pendientes. Este README registra decisiones, no certifica que se haya desplegado ni probado en Supabase.
