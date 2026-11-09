import 'package:supabase_flutter/supabase_flutter.dart';

/// Solo acceso a base de datos. Nunca se invoca directamente desde BLoC.
class SupabasePlanDataSource {
  const SupabasePlanDataSource(this.client);
  final SupabaseClient client;

  String get currentUserId {
    final id = client.auth.currentUser?.id;
    if (id == null) throw StateError('Debes iniciar sesión.');
    return id;
  }

  Future<List<Map<String, dynamic>>> publishedPlans() async {
    final data = await client.from('plan').select()
        .eq('estado', 'publicado')
        .gte('fecha_inicio', DateTime.now().toUtc().toIso8601String())
        .order('fecha_inicio', ascending: true);
    return data;
  }

  Future<List<Map<String, dynamic>>> organizerPlans(String id) => client
      .from('plan').select().eq('id_organizador', id)
      .order('created_at', ascending: false);

  Future<Map<String, dynamic>> planById(String id) => client
      .from('plan').select().eq('id_plan', id).single();

  Future<List<Map<String, dynamic>>> activities() => client
      .from('tipo_actividad').select('id_tipo_actividad,nombre')
      .order('nombre');

  Future<Map<String, dynamic>> insert(Map<String, dynamic> values) => client
      .from('plan').insert({...values, 'id_organizador': currentUserId})
      .select().single();

  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> values) => client
      .from('plan').update(values).eq('id_plan', id).select().single();

  Future<void> delete(String id) async {
    await client.from('plan').delete().eq('id_plan', id);
  }
}
