import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/data/datasources/supabase_auth_data_source.dart';
import '../features/auth/data/repositories/supabase_auth_repository.dart';
import '../features/auth/domain/usecases/auth_usecases.dart';
import '../features/auth/domain/usecases/session_usecases.dart';
import '../features/auth/presentation/bloc/auth/auth_bloc.dart';
import '../shared/theme/app_theme.dart';
import 'rumbo_shell.dart';

class RumboApp extends StatelessWidget {
  const RumboApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Construcción manual para Sprint 1. Sin contenedor ni framework de DI.
    final repository = SupabaseAuthRepository(
      SupabaseAuthDataSource(Supabase.instance.client),
    );

    return BlocProvider<AuthBloc>(
      create: (_) => AuthBloc(
        hasSession: HasSessionUseCase(repository),
        observeSession: ObserveSessionUseCase(repository),
        getCurrentProfile: GetCurrentProfileUseCase(repository),
        signOut: SignOutUseCase(repository),
      ),
      child: MaterialApp(
        title: 'RUMBO',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: RumboShell(authRepository: repository),
      ),
    );
  }
}
