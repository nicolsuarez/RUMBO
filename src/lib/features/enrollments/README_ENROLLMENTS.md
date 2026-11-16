# RUMBO — Enrollments | Persona 2 | Sprint 2

**Responsable:** Persona 2 · **Rama sugerida:** `feature/enrollments-persona2`

## Funcionalidades comprometidas

| Caso de uso | Implementación |
|---|---|
| US-05 InscribirseEnPlan | `EnrollInPlanUseCase` + RPC `inscribirse_en_plan` y botón de detalle |
| US-06 ConsultarMisInscripciones | `GetMyEnrollmentsUseCase` + pestaña **Mis planes** |
| US-07 CancelarInscripcion | `CancelEnrollmentUseCase` + diálogo de confirmación |
| US-08 VerificarCuposYDuplicados | RPC transaccional, `FOR UPDATE` de PLAN, `UNIQUE (id_usuario,id_plan)` y comprobación de cupos |
| US-11 Seguridad (compartida) | RLS SELECT propias/organizador, escrituras solo por RPC autenticadas |
| US-12 Entrega reproducible (compartida) | Migración versionada, pruebas offline, instrucciones y checklist de demo |

La migración también permite **solicitar/aprobar/rechazar** cupos en planes privados, como ampliación de US-13/US-14. El organizador abre solicitudes desde su panel; las solicitudes `pendiente` no consumen cupo hasta que se aprueban.

## Estructura

```text
features/enrollments/
  domain/entities/            EnrollmentEntity, EnrollmentStatus, PlanAvailability
  domain/repositories/        EnrollmentRepository (contrato)
  domain/usecases/            7 casos de uso
  data/datasources/           consultas PostgREST y RPC
  data/models/                mapeo columnas SQL -> dominio
  data/repositories/          implementación concreta
  presentation/bloc/          eventos, estados y EnrollmentsBloc
  presentation/screens/       Mis inscripciones y solicitudes del organizador
```

La pantalla de detalle `PlanDetailScreen.fromEntity` usa este BLoC y lee un PlanEntity real de Plans. No se usan IDs de planes simulados para persistir inscripciones. Se registra el módulo mediante `get_it` en `core/di/injection_container.dart`.

## Esquema y seguridad

- Migración: `src/supabase/migrations/20261115000100_enrollments.sql`.
- Tabla: `public.inscripcion` (UUID, usuario, plan, fecha, estado, auditoría).
- Estados SQL: `pendiente`, `confirmada`, `cancelada`, `rechazada`.
- Unicidad por usuario y plan. Cancelar conserva el registro para consultar el historial. La reinscripción vuelve a activar ese mismo registro.
- RPC `inscribirse_en_plan(uuid)` y `resolver_solicitud_inscripcion(uuid,boolean)` **bloquean la fila del plan** antes de contar confirmados: evitan sobreventa concurrente.
- La persona no puede inscribirse a su propio plan ni a borradores, planes cancelados/finalizados o iniciados.
- Solo el organizador propietario puede aprobar o rechazar sus solicitudes. El máximo no puede reducirse por debajo del número de confirmados.
- RLS solo permite SELECT propio u organizador. **No hay INSERT/UPDATE/DELETE directos** para usuarios autenticados: únicamente las RPC con validación del lado del servidor.
- `consultar_cupos_plan` devuelve cantidades agregadas, no los datos de otras personas.

**No se incluye** la cancelación automática cuando el mínimo no se alcanza entre T-24 h y el inicio del plan. En el README de Plans consta como pendiente compartido: requiere acordar con Persona 1 el scheduler `pg_cron`. Tampoco se asume chat/GPS/SOS funcionales (Sprint 3).

## Requisitos y ejecución

Desde `src/`:

```bash
flutter pub get
flutter analyze
flutter test test/enrollments/
flutter run
```

**Configurar Supabase**: el archivo `lib/core/config/supabase_config.dart` del equipo debe apuntar al proyecto Supabase compartido. Deben estar aplicadas las migraciones de Auth y Plans antes de Enrollments. Coordinar con el equipo antes de aplicar cambios remotos:

```bash
npx supabase migration list
npx supabase db push --dry-run
# Tras revisión conjunta de lo que se va a aplicar:
npx supabase db push
```

Se necesitan **2 cuentas de prueba**: una con rol `organizador` (crea planes) y otra con rol `participante` (se inscribe). Para aprobación privada conviene un tercer usuario participante. No publicar contraseñas de prueba en repositorios públicos; se pueden compartir de forma privada con el docente.

## Pruebas manuales mínimas contra Supabase

1. Organizador publica un plan público futuro con 1 cupo. Participante A lo abre en Explorar → Detalle → **Unirme al plan**. Debe quedar `confirmada` en Mis planes y aparecer 1/1 cupos.
2. El mismo usuario intenta inscribirse otra vez → no debe duplicarse; al estar confirmado el botón ofrece cancelar.
3. Participante B intenta unirse con 1/1 cupos → servidor debe rechazar la operación; comprueba que el total siga en 1.
4. A cancela desde Mis planes → estado `cancelada` y cupo disponible. B puede ocuparlo.
5. En un plan privado, A solicita un cupo → estado `pendiente`; organizador aprueba → `confirmada`. Probar también rechazo.
6. A intenta ver/editar inscripciones de B con consulta directa → RLS debe impedirlo. Un participante no puede ejecutar `resolver_solicitud_inscripcion` para un plan ajeno.
7. Dos sesiones intentan inscribir al último cupo simultáneamente → como máximo una queda `confirmada`.
8. Organizador intenta bajar `cupos_maximos` a menos de las inscripciones confirmadas → SQL debe rechazar el cambio.
9. Cerrar sesión e ingresar con otra cuenta → Mis planes no debe mostrar inscripciones ajenas.

Pruebas unitarias (`test/enrollments/enrollment_usecases_test.dart`) usan un repositorio falso, no certifican la seguridad ni el comportamiento de una base remota. Registrar capturas/logs de las pruebas reales antes de la entrega.
