## Estructura del repositorio

```text
RUMBO/
├── Documentacion/
├── Prototipo/
├── src/
│   ├── assets/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app/
│   │   ├── core/
│   │   ├── shared/
│   │   └── features/
│   ├── pubspec.yaml
│   └── ...
├── .gitignore
└── README.md
```

### Organización del código Flutter

El código de sigue una organización **Feature-First**, donde los archivos se agrupan según la funcionalidad a la que pertenecen.

- `app/`: es la configuración principal y navegación general de RUMBO.
- `core/`: son componentes tecnicos que son utilizados por varias funcionalidades, en el futuro se implementarían cosas como clientes de red, almacenamiento y manejo de errores y excepciones. 
- `shared/`: temas, componentes visuales, pintores y utilidades reutilizables.
- `features/`: funcionalidades de la aplicación, organizadas de manera independiente.

Las principales features son:

| Feature | Responsabilidad |
|---|---|
| `onboarding` | Pantallas de bienvenida. |
| `home` | Pantallas principales del participante y organizador. |
| `auth` | Autenticación y estado global de sesión (pendiente para el sprint 1). |
| `plans` | Exploración, creación, detalles y administración de planes. |
| `enrollments` | Solicitudes, inscripciones y administración de participantes. |
| `profile` | Perfil del usuario e intereses. |
| `chat` | Comunicación entre participantes. |
| `routes` | Seguimiento de rutas y recorridos. |
| `safety` | Alertas y funcionalidades de seguridad (pendiente). |

## Arquitectura

El proyecto utiliza una estructura **Feature-First** y se le va a ir agregando la adaptacion del patron Clean Architecture.

En el prototipo, las funcionalidades se organizan inicialmente en la capa `presentation`, con componentes, pantallas y datos simulados, pero a medida que se implementa la lógica real, cada feature debe o puede incorporar:

```text
feature/
├── presentation/
│   ├── screens/
│   ├── components/
│   └── bloc/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── data/
    ├── models/
    ├── datasources/
    └── repositories/
```

### Responsabilidades de las capas

**Presentation:** construye la interfaz, representa estados y procesa interacciones del usuario. Cuando corresponda, utiliza BLoC.

**Domain:** define entidades, contratos y casos de uso independientes de Flutter y de los detalles de almacenamiento.

**Data:** implementa el acceso a fuentes de información y los contratos definidos en el dominio.

No todas las features tendrán las tres capas desde el inicio. Se incorporarán según las necesidades de su implementación.


### Gestión de estado

La autenticación utilizará un `AuthBloc` compartido a nivel de aplicación para representar el estado de sesión.

Las demás features administrarán sus propios estados y eventos mediante los BLoCs correspondientes.

Durante la etapa actual, algunas interacciones del prototipo utilizan `setState()` y datos temporales en memoria.


## Estrategia de ramas

El repositorio sigue este flujo de trabajo:

| Rama | Propósito |
|---|---|
| `main` | Versiones estables del proyecto. |
| `develop` | Integración del desarrollo en curso. |
| `feature/*` | Desarrollo de funcionalidades específicas. |

### Responsabilidad de cada integrante

1. Crear una rama `feature/*` a partir de `develop`.
2. Implementar la funcionalidad en su rama.
3. Realizar commits con cambios relacionados.
4. Crear un Pull Request hacia `develop`.
5. Revisar e integrar los cambios.
6. Incorporar a `main` versiones estables y verificadas.



### Convención de commits

En los commits pueden utiliz mensajes descriptivos siguiendo una convención basada en Conventional Commits:

- `feat:` nueva funcionalidad.
- `fix:` corrección de errores.
- `refactor:` reorganización interna sin cambios funcionales.
- `docs:` documentación.
- `chore:` configuración o mantenimiento.
- `test:` incorporación o modificación de pruebas.


## Estado actual del proyecto

El proyecto cuenta con una primera migración del prototipo a Flutter y una estructura modular por funcionalidades.

Las pantallas y algunas interacciones utilizan datos simulados, sin persistencia definitiva.

El seguimiento de rutas, la detección de desviaciones y las alertas SOS son demostraciones visuales. **No utilizan GPS real ni envían alertas a contactos o servicios de emergencia.**

La autenticación, los permisos, la gestión definitiva de inscripciones, la persistencia y los servicios de seguridad se implementarán en etapas posteriores.


## Para ejecutar el proyecto se hace el flutter pub get y el flutter run desde la carpeta src/

## Desarrollo de funcionalidades y documentación del flujo

### Desarrollo por ramas

Cada nueva funcionalidad (*feature*) deberá desarrollarse en una rama independiente, creada a partir de `develop`.

Las ramas seguirán la convención `feature/nombre-funcionalidad`, por ejemplo:

- `feature/auth`: autenticación y gestión de sesiones.
- `feature/plans`: creación y administración de planes.
- `feature/enrollments`: inscripciones y participantes.
- `feature/chat`: comunicación entre usuarios.

Esto permitirá desarrollar, probar y revisar cada funcionalidad de manera independiente, evitando modificaciones directas sobre `develop`.

Una vez finalizada y validada la funcionalidad, se integrará a `develop` mediante un **Pull Request**.

### Documentación del flujo de cada feature

Cada vez que se termine de implementar una nueva feature, en lo posible que se actualice la Documentacion/, que se incluya un diagrama muy sencillo del flujo de funcionamiento. Esto para facilitar que los demás comprendan como interactúan los componentes, como se procesa la info y donde estan las responsabilidades etc.
