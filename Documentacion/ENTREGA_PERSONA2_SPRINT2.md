# Evidencia de entrega — Sprint 2 / Persona 2

**Cierre de la rúbrica:** lunes 16 de noviembre de 2026, 23:59 (hora local de la materia).

## Lista de verificación

- [ ] Migraciones Auth y Plans aplicadas en el proyecto Supabase compartido.
- [ ] Migración `20261115000100_enrollments.sql` aplicada con acuerdo del equipo.
- [ ] `flutter pub get`, `flutter analyze` y `flutter test` ejecutados y resultados guardados.
- [ ] Validación real de RLS, duplicados y carrera por el último cupo con 2 sesiones.
- [ ] Video de pantalla (máximo 5 minutos) demostrando los flujos.
- [ ] README con instrucciones básicas (incluido) y credenciales de prueba compartidas **por canal privado**, sin subir contraseñas a GitHub.
- [ ] Commit creado y empujado a GitHub con el código probado.
- [ ] Etiqueta `sprint2-persona2-v1` empujada para identificar el commit de entrega.
- [ ] En la plataforma de clase: URL del commit + enlace al video.

## Guion sugerido para el video (aprox. 4 minutos)

1. **0:00–0:30** — Mostrar rama, commit, etiqueta y estructura `enrollments` (domain/data/presentation).
2. **0:30–1:15** — Desde organizador: mostrar un plan público publicado y su cupo máximo.
3. **1:15–2:15** — Desde participante: Explorar → Detalle → Unirme → Mis planes; comprobar estado confirmada y contador.
4. **2:15–3:10** — Mostrar segundo intento/último cupo; cancelar y verificar que se libera.
5. **3:10–3:45** — En plan privado: solicitar; en cuenta organizador: aprobar/rechazar una solicitud.
6. **3:45–4:15** — Mostrar migración SQL (RLS, UNIQUE, `FOR UPDATE`) y tests; mencionar límite de pruebas si no se ejecutaron en remoto.

## Git: entrega reproducible

La rama que contiene el trabajo es `feature/enrollments-persona2`. Tras verificar que estás en el repo y que nadie ha subido cambios conflictivos:

```bash
git status
git log -1 --oneline
git push -u origin feature/enrollments-persona2
git push origin sprint2-persona2-v1
```

Formato del enlace a entregar (reemplaza `<SHA>` por el hash publicado):

```text
https://github.com/nicolsuarez/RUMBO/commit/<SHA>
```

No se ha publicado nada en GitHub ni se ha grabado un video automáticamente. La etiqueta y el commit pueden existir localmente, pero solo funcionarán como enlace público después del `push` autorizado.

## Notas de integración

- Si Persona 1 actualiza Plans, integrar sus cambios antes de etiquetar la versión final.
- La cancelación automática por mínimo de participantes desde T-24 h se mantiene pendiente de coordinación con Persona 1; no marcarla como terminada.
- Las pantallas temporales de Chat y Routes no hacen parte del Sprint 2.
