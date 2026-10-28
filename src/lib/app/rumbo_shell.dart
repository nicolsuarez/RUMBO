import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/domain/entities/rumbo_user.dart';
import '../features/auth/domain/usecases/auth_usecases.dart';
import '../features/auth/data/datasources/supabase_auth_data_source.dart';
import '../features/auth/data/repositories/supabase_auth_repository.dart';

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
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/routes/presentation/screens/route_simulation_screen.dart';

class RumboShell extends StatefulWidget {
  const RumboShell({super.key});

  @override
  State<RumboShell> createState() => _RumboShellState();
}

class _RumboShellState extends State<RumboShell> {
  late final SupabaseAuthRepository _auth;
  StreamSubscription<void>? _authListener;
  RumboUser? _user;
  bool _loadingProfile = false;
  String? _profileError;

  // Estado temporal del prototipo.
  // Hasta integrar Supabase, no se concede ninguna sesión real.
  // Vista previa de las pantallas internas: solo se habilitará para desarrollo.
  _EntryPage entryPage = _EntryPage.welcome;
  UserRole selectedRole = UserRole.participante;
  bool organizerAuthorizedPreview = false;

  RootTab tab = RootTab.inicio;

  late final List<Plan> plans;

  final Set<String> joined = <String>{};
  final Set<String> createdPlanIds = <String>{};

  String? activeRouteId;

  @override
  void initState() {
    super.initState();
    _auth = SupabaseAuthRepository(SupabaseAuthDataSource(Supabase.instance.client));
    _authListener = _auth.sessionChanges.listen((_) => _refreshSession());
    _refreshSession();

    // Crear copias de los planes originales.
    plans = initialPlans.map(_copyPlan).toList();
  }

  Future<void> _refreshSession() async {
    if (!_auth.hasSession) {
      if (mounted) setState(() { _user = null; _profileError = null;
        if (entryPage == _EntryPage.authenticated) entryPage = _EntryPage.login; });
      return;
    }
    if (mounted) setState(() { _loadingProfile = true; _profileError = null; });
    try {
      final profile = await GetCurrentProfileUseCase(_auth)();
      if (!mounted) return;
      setState(() {
        _user = profile;
        organizerAuthorizedPreview = profile?.isOrganizer ?? false;
        selectedRole = profile?.isOrganizer == true ? UserRole.organizador : UserRole.participante;
        entryPage = _EntryPage.authenticated;
        tab = RootTab.perfil;
      });
    } catch (e) {
      if (mounted) setState(() => _profileError = 'No se pudo cargar tu perfil: $e');
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  @override void dispose() { _authListener?.cancel(); super.dispose(); }

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
    if (!organizerAuthorizedPreview) return;
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
          'Esta acción no cambia tu rol ni concede permisos.'
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido'))],
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
    if (_user == null || !_user!.isOrganizer || selectedRole != UserRole.organizador) {
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
    if (_loadingProfile) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_profileError != null) return Scaffold(body: Center(child: Column(
      mainAxisSize: MainAxisSize.min, children: [Text(_profileError!),
      FilledButton(onPressed: _refreshSession,child: const Text('Reintentar'))])));
    // El acceso a la aplicación requiere sesión válida, excepto preview debug.
    if (entryPage == _EntryPage.welcome) {
      return SplashScreen(
        onRegister: () => setState(() => entryPage = _EntryPage.register),
        onLogin: () => setState(() => entryPage = _EntryPage.login),
        onPreview: () {
          if (!kDebugMode) return;
          setState(() {
            entryPage = _EntryPage.preview;
            organizerAuthorizedPreview = false;
            selectedRole = UserRole.participante;
          });
        },
      );
    }
    if (entryPage == _EntryPage.login) {
      return LoginScreen(
        signIn: SignInUseCase(_auth),
        onRegister: () => setState(() => entryPage = _EntryPage.register),
      );
    }
    if (entryPage == _EntryPage.register) {
      return RegisterScreen(
        signUp: SignUpUseCase(_auth),
        onLogin: () => setState(() => entryPage = _EntryPage.login),
      );
    }

    if (entryPage != _EntryPage.preview && _user == null) {
      return const Scaffold(body: Center(child: Text('Inicia sesión para continuar.')));
    }
    return Scaffold(
      appBar: kDebugMode && entryPage == _EntryPage.preview
          ? AppBar(
              title: const Text('Vista previa (sin autenticación)'),
              actions: [
                TextButton(
                  onPressed: () => setState(() {
                    organizerAuthorizedPreview = !organizerAuthorizedPreview;
                    selectedRole = organizerAuthorizedPreview
                        ? UserRole.organizador : UserRole.participante;
                    tab = RootTab.inicio;
                  }),
                  child: Text(organizerAuthorizedPreview
                      ? 'Restablecer participante' : 'Cuenta organizadora de prueba'),
                ),
              ],
            )
          : null,
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
              isOrganizerAuthorized: organizerAuthorizedPreview,
              onToggleRole: toggleViewMode,
              onRequestOrganizer: showOrganizerRequest,
              user: _user,
              onSignOut: _user == null ? null : () async { await _auth.signOut(); },
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

// preview se reserva para el futuro enlace de Supabase; no hay login simulado.
enum _EntryPage { welcome, register, login, preview, authenticated }
