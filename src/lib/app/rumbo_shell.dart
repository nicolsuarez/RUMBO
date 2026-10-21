import 'package:flutter/material.dart';

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
import '../features/profile/presentation/screens/role_screen.dart';
import '../features/routes/presentation/screens/route_simulation_screen.dart';

class RumboShell extends StatefulWidget {
  const RumboShell({super.key});

  @override
  State<RumboShell> createState() => _RumboShellState();
}

class _RumboShellState extends State<RumboShell> {
  // Estado temporal del prototipo.
  bool entered = false;
  UserRole? selectedRole;

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

  void chooseRole(UserRole role) {
    setState(() {
      selectedRole = role;
      tab = RootTab.inicio;
    });
  }

  void toggleRole() {
    setState(() {
      selectedRole = selectedRole == UserRole.organizador
          ? UserRole.participante
          : UserRole.organizador;

      tab = RootTab.inicio;
    });
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
    if (selectedRole != UserRole.organizador) {
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
    // Pantalla introductoria.
    if (!entered) {
      return SplashScreen(
        onEnter: () {
          setState(() {
            entered = true;
          });
        },
      );
    }

    // Selección inicial del rol.
    if (selectedRole == null) {
      return RoleScreen(onChoose: chooseRole);
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
            ProfileScreen(role: selectedRole!, onToggleRole: toggleRole),
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
