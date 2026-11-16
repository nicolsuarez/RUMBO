import 'package:supabase_flutter/supabase_flutter.dart';

/// La capa data es la única que conoce tablas, columnas y funciones SQL.
class SupabaseEnrollmentDataSource {
  const SupabaseEnrollmentDataSource(this.client);
  final SupabaseClient client;

  String get currentUserId {
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Debes iniciar sesión.');
    return user.id;
  }

  static const selectWithPlan =
      'id_inscripcion,id_usuario,id_plan,estado,fecha_inscripcion,'
      'plan:plan!inscripcion_id_plan_fkey(titulo,lugar,fecha_inicio)';

  Future<List<Map<String, dynamic>>> myEnrollments() async => await client
      .from('inscripcion')
      .select(selectWithPlan)
      .eq('id_usuario', currentUserId)
      .order('fecha_inscripcion', ascending: false);

  Future<Map<String, dynamic>?> myEnrollmentForPlan(String planId) async =>
      await client
          .from('inscripcion')
          .select(selectWithPlan)
          .eq('id_usuario', currentUserId)
          .eq('id_plan', planId)
          .maybeSingle();

  Future<Map<String, dynamic>> availabilityForPlan(String planId) async {
    final data = await client.rpc('consultar_cupos_plan',
        params: {'p_plan_id': planId});
    // RETURNS TABLE genera una lista con una sola fila.
    if (data is List && data.isNotEmpty) {
      return Map<String, dynamic>.from(data.first as Map);
    }
    throw StateError('No fue posible consultar los cupos.');
  }

  Future<void> enroll(String planId) async {
    await client.rpc('inscribirse_en_plan', params: {'p_plan_id': planId});
  }

  Future<void> cancel(String planId) async {
    await client.rpc('cancelar_inscripcion', params: {'p_plan_id': planId});
  }

  Future<List<Map<String, dynamic>>> pendingRequests(String planId) async =>
      await client
          .from('inscripcion')
          .select(selectWithPlan)
          .eq('id_plan', planId)
          .eq('estado', 'pendiente')
          .order('fecha_inscripcion', ascending: true);

  Future<void> resolveRequest(String enrollmentId,
      {required bool approve}) async {
    await client.rpc('resolver_solicitud_inscripcion', params: {
      'p_inscripcion_id': enrollmentId,
      'p_aprobar': approve,
    });
  }
}
