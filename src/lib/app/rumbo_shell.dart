import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/auth/domain/entities/rumbo_user.dart';
import '../features/auth/domain/usecases/auth_usecases.dart';
import '../features/auth/presentation/bloc/login/login_bloc.dart';
import '../features/auth/presentation/bloc/register/register_bloc.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/presentation/bloc/auth/auth_bloc.dart';

import 'models/root_tab.dart';

import '../features/chat/presentation/screens/chat_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/home/presentation/screens/organizer_panel.dart';
import '../features/onboarding/presentation/screens/splash_screen.dart';
import '../features/plans/presentation/mocks/plan_mock_data.dart';
import '../features/plans/presentation/models/plan.dart';
import '../features/plans/presentation/screens/create_plan_screen.dart';
import '../features/plans/presentation/screens/explore_screen.dart';
import '../features/plans/presentation/screens/my_plans_screen.dart';
import '../features/plans/presentation/screens/plan_detail_screen.dart';
import '../features/profile/presentation/models/user_role.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/profile_summary_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/routes/presentation/screens/route_simulation_screen.dart';
import '../features/auth/domain/usecases/check_username_availability_usecase.dart';

class RumboShell extends StatefulWidget {
  const RumboShell({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<RumboShell> createState() => _RumboShellState();
}

class _RumboShellState extends State<RumboShell> {
  // El estado de sesión se consulta desde AuthBloc, no desde Supabase.
  RumboUser? get _user {
    final state = context.read<AuthBloc>().state;
    return state is AuthAuthenticated ? state.user : null;
  }

  // Estado visual de navegación; los permisos reales vienen de AuthBloc.
  _EntryPage entryPage = _EntryPage.welcome;
  UserRole selectedRole = UserRole.participante;
  String? _lastAuthenticatedUserId;
  bool _registrationInProgress = false;

  RootTab tab = RootTab.inicio;

  late final List<Plan> plans;

  final Set<String> joined = <String>{};
  final Set<String> createdPlanIds = <String>{};

  String? activeRouteId;

  @override
  void initState() {
    super.initState();
    // Crear copias de los planes originales.
    plans = initialPlans.map(_copyPlan).toList();
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state is AuthAuthenticated) {
      if (_lastAuthenticatedUserId == state.user.id) return;
      _lastAuthenticatedUserId = state.user.id;
      setState(() {
        selectedRole = state.user.isOrganizer
            ? UserRole.organizador
            : UserRole.participante;
        entryPage = _registrationInProgress
            ? _EntryPage.registrationSummary
            : _EntryPage.authenticated;
        tab = RootTab.inicio;
      });
    } else if (state is AuthUnauthenticated) {
      _lastAuthenticatedUserId = null;
      setState(() {
        selectedRole = UserRole.participante;
        _registrationInProgress = false;
        // Se conserva el formulario de registro si el usuario estaba registrándose.
        if (entryPage == _EntryPage.authenticated ||
            entryPage == _EntryPage.registrationSummary) {
          entryPage = _EntryPage.login;
        }
      });
    }
  }

  Plan _copyPlan(Plan p) {
    return Plan(
      id: p.id,
      titulo: p.titulo,
      lugar: p.lugar,
      fecha: p.fecha,
      dificultad: p.dificultad,
      distancia: p.distancia,
      desnivel: p.desnivel,
      cupos: p.cupos,
      van: p.van,
      precio: p.precio,
      organizador: p.organizador,
      rolOrganizador: p.rolOrganizador,
      tags: List.of(p.tags),
      color1: p.color1,
      color2: p.color2,
      elevacion: List.of(p.elevacion),
      descripcion: p.descripcion,
      llevar: List.of(p.llevar),
      imageAsset: p.imageAsset,
    );
  }

  // Pestañas disponibles según el rol.
  List<RootTab> get visibleTabs => [
    RootTab.inicio,
    RootTab.explorar,
    if (selectedRole == UserRole.organizador) RootTab.crear,
    RootTab.planes,
    RootTab.perfil,
  ];

  void selectTab(RootTab next) {
    if (!visibleTabs.contains(next)) return;

    setState(() {
      tab = next;
    });
  }

  void toggleViewMode() {
    if (_user?.isOrganizer != true) return;
    setState(() {
      selectedRole = selectedRole == UserRole.organizador
          ? UserRole.participante
          : UserRole.organizador;
      tab = RootTab.inicio;
    });
  }

  void showOrganizerRequest() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiero ser organizador'),
        content: const Text(
          'Formulario simulado. En una versión futura podrás enviar '
          'tu experiencia y solicitar autorización. '
          'Esta acción no cambia tu rol ni concede permisos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // Inscripciones simuladas.
  bool toggleJoin(Plan plan) {
    if (joined.contains(plan.id)) {
      setState(() {
        joined.remove(plan.id);

        if (plan.van > 0) {
          plan.van--;
        }

        if (activeRouteId == plan.id) {
          activeRouteId = null;
        }
      });

      return true;
    }

    if (plan.van >= plan.cupos) {
      return false;
    }

    setState(() {
      joined.add(plan.id);
      plan.van++;
    });

    return true;
  }

  // Creación temporal de planes.
  void addPlan(Plan plan) {
    if (_user == null ||
        !_user!.isOrganizer ||
        selectedRole != UserRole.organizador) {
      return;
    }

    setState(() {
      plans.insert(0, plan);
      createdPlanIds.add(plan.id);

      // Mostrar el plan en la sección Mis planes.
      tab = RootTab.planes;
    });
  }

  bool ownsPlan(Plan plan) {
    return selectedRole == UserRole.organizador &&
        (plan.id == 'pance' ||
            plan.id == 'bosque' ||
            createdPlanIds.contains(plan.id));
  }

  // Abrir el detalle de una actividad.
  void openPlan(Plan plan) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlanDetailScreen(
          plan: plan,
          organizerOwnPlan: ownsPlan(plan),
          joined: joined.contains(plan.id),
          onJoinToggle: () => toggleJoin(plan),
          onOpenChat: () => openChat(plan),
          onStartRoute: joined.contains(plan.id)
              ? () => startRoute(plan)
              : null,
        ),
      ),
    );
  }

  void openChat(Plan plan) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ChatScreen(plan: plan)));
  }

  // Seguimiento simulado de recorridos.
  void startRoute(Plan plan) {
    setState(() {
      activeRouteId = plan.id;
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteSimulationScreen(
          plan: plan,
          onFinish: () {
            setState(() {
              activeRouteId = null;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: _onAuthStateChanged,
      builder: (context, authState) => _buildForAuthState(authState),
    );
  }

  Widget _buildForAuthState(AuthState authState) {
    if (authState is AuthInitial || authState is AuthLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (authState is AuthFailure) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(authState.message),
              FilledButton(
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthRetryRequested()),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    final isAuthenticated = authState is AuthAuthenticated;
    // El acceso a la aplicación requiere sesión válida.
    if (!isAuthenticated && entryPage == _EntryPage.welcome) {
      return SplashScreen(
        onRegister: () => setState(() => entryPage = _EntryPage.register),
        onLogin: () => setState(() => entryPage = _EntryPage.login),
      );
    }
    if (!isAuthenticated && entryPage == _EntryPage.login) {
      return BlocProvider<LoginBloc>(
        create: (_) => LoginBloc(signIn: SignInUseCase(widget.authRepository)),
        child: LoginScreen(
          onRegister: () => setState(() => entryPage = _EntryPage.register),
          onBack: () => setState(() => entryPage = _EntryPage.welcome),
        ),
      );
    }
    if (!isAuthenticated && entryPage == _EntryPage.register) {
      return BlocProvider<RegisterBloc>(
        create: (_) => RegisterBloc(
          signUp: SignUpUseCase(widget.authRepository),
          checkUsername: CheckUsernameAvailabilityUseCase(
            widget.authRepository,
          ),
        ),
        child: RegisterScreen(
          onLogin: () => setState(() {
            _registrationInProgress = false;
            entryPage = _EntryPage.login;
          }),
          onBack: () => setState(() {
            _registrationInProgress = false;
            entryPage = _EntryPage.welcome;
          }),
          onRegistrationStarted: () {
            _registrationInProgress = true;
          },
          onRegistrationFailed: () {
            _registrationInProgress = false;
          },
        ),
      );
    }
    if (!isAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('Inicia sesión para continuar.')),
      );
    }
    if (entryPage == _EntryPage.registrationSummary) {
      return ProfileSummaryScreen(
        user: authState.user,
        onContinue: () => setState(() {
          _registrationInProgress = false;
          entryPage = _EntryPage.authenticated;
          tab = RootTab.inicio;
        }),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: tab.index,
          children: [
            // 0 - Inicio
            selectedRole == UserRole.organizador
                ? OrganizerPanel(
                    plans: plans,
                    createdPlanIds: createdPlanIds,
                    onOpen: openPlan,
                    onCreate: () {
                      selectTab(RootTab.crear);
                    },
                  )
                : HomeScreen(
                    userName: _user!.name,
                    plans: plans,
                    onOpen: openPlan,
                    onExplore: () {
                      selectTab(RootTab.explorar);
                    },
                  ),

            // 1 - Explorar
            ExploreScreen(plans: plans, onOpen: openPlan),

            // 2 - Crear
            selectedRole == UserRole.organizador
                ? CreatePlanScreen(onCreate: addPlan)
                : const SizedBox.shrink(),

            // 3 - Mis planes
            MyPlansScreen(
              plans: plans,
              joined: joined,
              createdPlanIds: createdPlanIds,
              organizerMode: selectedRole == UserRole.organizador,
              activeRouteId: activeRouteId,
              onOpen: openPlan,
              onStartRoute: startRoute,
              onExplore: () {
                selectTab(RootTab.explorar);
              },
            ),

            // 4 - Perfil
            ProfileScreen(
              role: selectedRole,
              isOrganizerAuthorized: _user?.isOrganizer ?? false,
              onToggleRole: toggleViewMode,
              onRequestOrganizer: showOrganizerRequest,
              user: _user,
              onSignOut: () {
                context.read<AuthBloc>().add(const AuthSignOutRequested());
              },
            ),
          ],
        ),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: visibleTabs.indexOf(tab),

        onDestinationSelected: (index) {
          selectTab(visibleTabs[index]);
        },

        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: selectedRole == UserRole.organizador ? 'Panel' : 'Inicio',
          ),

          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explorar',
          ),

          if (selectedRole == UserRole.organizador)
            const NavigationDestination(
              icon: Icon(Icons.add_circle_outline),
              selectedIcon: Icon(Icons.add_circle),
              label: 'Crear',
            ),

          const NavigationDestination(
            icon: Icon(Icons.hiking_outlined),
            selectedIcon: Icon(Icons.hiking),
            label: 'Mis planes',
          ),

          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

enum _EntryPage { welcome, register, login, registrationSummary, authenticated }
