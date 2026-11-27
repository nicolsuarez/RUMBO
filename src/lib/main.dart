
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/rumbo_app.dart';
import 'core/config/supabase_config.dart';
import 'core/di/injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  final supabase = Supabase.instance.client;

  // Registro de dependencias de los módulos.
  registerPlansDependencies(supabase);
  registerEnrollmentsDependencies(supabase);
  registerAuthDependencies(supabase);

  
  registerSafetyDependencies(supabase);

  runApp(const RumboApp());
}
