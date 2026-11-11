# RUMBO — Plans | Sprint 2

**Responsable:** Persona 1 · **Rama:** `feature/plans`  
**Tecnologías:** Flutter, BLoC, Clean Architecture + Feature First, `get_it` y Supabase.

## ¿Qué incluye?

- Crear planes como **borrador** o **publicados**, editar los propios, cancelar, finalizar y eliminar borradores.
- Explorar planes publicados con fecha futura, filtrar y consultar detalles.
- Home y panel del organizador conectados a `PlansBloc`.
- Fotografías opcionales: selección con `image_picker`, subida a Supabase Storage y visualización en las tarjetas.

Las inscripciones, solicitudes de aprobación y cupos ocupados reales corresponden a **Enrollments (Persona 2)**. Los mocks restantes solo respaldan flujos de participantes, Chat y Routes pendientes de integración; no alimentan Home ni Explorar.

## Arquitectura

Código principal: `src/lib/features/plans/`.

```text
presentation/  Pantallas, tarjetas y PlansBloc (eventos/estados)
     ↓
domain/        PlanEntity, PlanInput, casos de uso y contratos
     ↓
data/          Repositorios y datasources para Supabase
     ↓
Supabase       PostgreSQL + Storage
```

`src/lib/core/di/injection_container.dart` registra las dependencias de Plans mediante `get_it`. **Home reutiliza `PlansBloc`**; no tiene repositorio de planes duplicado. La autorización real está en PostgreSQL/RLS, no en los botones de la interfaz.

## Contratos de Plans

Entidad: `domain/entities/plan_entity.dart` (`PlanEntity`). Campos que otras features necesitan:

| Dart | Columna PostgreSQL | Uso |
| --- | --- | --- |
| `id` | `plan.id_plan` | UUID del plan (String en Dart) |
| `organizerId` | `plan.id_organizador` | UUID del organizador |
| `status` | `plan.estado` | `borrador`, `publicado`, `cancelado`, `finalizado` |
| `mode` | `plan.modalidad` | `publico` o `privado` |
| `startsAt` | `plan.fecha_inicio` | Inicio de la actividad |
| `minParticipants`, `maxParticipants` | `cupos_minimos`, `cupos_maximos` | Límites de asistencia |
| `budgetPerPerson` | `plan.presupuesto` | Estimado por persona en COP; 0 = gratis |

En Dart se usan enums (`PlanStatus.draft/published/cancelled/finished` y `PlanMode.public/private`); **no guardar sus nombres directamente en SQL**. Usar los conversores de `plan_entity.dart`.

`PlansBloc` expone `state.published` (publicados con fecha futura), `state.mine` (planes del organizador), `state.activities` (catálogo) y estados `loading/saving/error/message`. Los datos se consultan mediante los casos de uso y `PlanRepository`, no desde widgets con consultas directas.

**Reglas principales:** título, descripción y lugar incluso en borradores; para publicar se exigen fecha futura, actividad, modalidad, cupos y presupuesto. La modalidad no cambia después de publicar. Un plan cancelado o finalizado no vuelve a editarse. Solo su organizador puede gestionarlo.

## Supabase

Migraciones **versionadas en `src/supabase/migrations/`**:

- `20261105000100_create_plans.sql`: tablas `plan` y `tipo_actividad`, restricciones, triggers y RLS.
- `20261108000100_plan_images_storage.sql`: bucket `plan-images`, políticas de Storage y validación de propiedad de las imágenes.

La rama incluye **ambos archivos**. Antes de ejecutar `npx supabase db push`, coordinar con el equipo: todos utilizan el mismo proyecto remoto y hay que verificar el historial de migraciones.

La columna `plan.imagen` guarda una **ruta relativa** en el bucket `plan-images` (`<uuid-organizador>/<archivo>`); no guarda una URL completa. El bucket permite lectura pública; **solo los organizadores autorizados pueden subir y gestionar archivos en su carpeta**. Se admiten JPG, PNG y WebP de hasta 5 MiB. *Una fotografía de borrador no es privada si alguien conoce su URL pública.*

## Integración con Enrollments — Persona 2

- Referenciar `plan.id_plan` (UUID) como clave del plan inscrito; no utilizar los IDs del modelo simulado.
- Permitir inscripciones únicamente a planes `publicado` dentro del periodo de inscripción acordado. **Público:** ingreso directo; **privado:** solicitud y aprobación.
- Calcular los cupos ocupados desde las **inscripciones confirmadas**, no desde los valores visuales simulados. Impedir superar `cupos_maximos` y acordar qué ocurre si se reducen los cupos de un plan con inscritos.
- Entregar al panel del organizador el número de inscritos y las solicitudes pendientes.
- **Pendiente compartido:** cancelación automática por no llegar a `cupos_minimos` desde 24 horas antes del inicio hasta la hora de inicio. Requiere los estados definitivos de Enrollments y una función SQL programada (`pg_cron`); **no está implementada todavía**.

## Validación antes del merge

Desde `src/`:

```bash
flutter pub get
flutter analyze
flutter test
npx supabase migration list
```

Probar con organizador y participante: crear borrador, publicar, consultar desde Home/Explorar, editar, cancelar/finalizar y subir/reemplazar/quitar imágenes. Confirmar que un participante **no** pueda modificar planes ajenos ni subir fotos. Estas pruebas funcionales deben registrarse en el Pull Request hacia `develop`.
