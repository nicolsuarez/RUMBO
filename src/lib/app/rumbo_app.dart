import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/presentation/bloc/auth/auth_bloc.dart';
import '../shared/theme/app_theme.dart';
import '../features/plans/presentation/bloc/plans_bloc.dart';
import '../core/di/injection_container.dart';
import 'rumbo_shell.dart';
import '../features/enrollments/presentation/bloc/enrollments_bloc.dart';

class RumboApp extends StatelessWidget {
  const RumboApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => locator<AuthBloc>()),
        BlocProvider<PlansBloc>(create: (_) => locator<PlansBloc>()),
        BlocProvider<EnrollmentsBloc>(
          create: (_) => locator<EnrollmentsBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'RUMBO',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const RumboShell(),
      ),
    );
  }
}
