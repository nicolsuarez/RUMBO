import 'package:supabase_flutter/supabase_flutter.dart';

/// Única clase de Routes que conoce el esquema y las RPC de Supabase.
class SupabaseRouteDataSource {
  const SupabaseRouteDataSource(this._client);
  final SupabaseClient _client;

  static const _columns =
      'id_recorrido,id_inscripcion,id_usuario,id_plan,inicio,fin,'
      'distancia_recorrida,porcentaje_avance,estado';

  String get _currentUserId {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Debes iniciar sesión.');
    return user.id;
  }

  Future<Map<String, dynamic>?> myRouteForPlan(String planId) async =>
      await _client
          .from('recorrido')
          .select(_columns)
          .eq('id_usuario', _currentUserId)
          .eq('id_plan', planId)
          .maybeSingle();

  Future<Map<String, dynamic>?> myActiveRoute() async => await _client
      .from('recorrido')
      .select(_columns)
      .eq('id_usuario', _currentUserId)
      .inFilter('estado', ['activo', 'pausado'])
      .maybeSingle();

  Future<Map<String, dynamic>> start(String planId) async {
    final data = await _client.rpc(
      'iniciar_recorrido',
      params: {'p_plan_id': planId},
    );
    return _singleRow(data);
  }

  Future<Map<String, dynamic>> updateProgress(
    String routeId,
    double progress,
  ) => _update(routeId, 'avanzar', progress: progress);

  Future<Map<String, dynamic>> pause(String routeId) =>
      _update(routeId, 'pausar');

  Future<Map<String, dynamic>> resume(String routeId) =>
      _update(routeId, 'reanudar');

  Future<Map<String, dynamic>> finish(String routeId) =>
      _update(routeId, 'finalizar');

  Future<Map<String, dynamic>> _update(
    String routeId,
    String action, {
    double? progress,
  }) async {
    final data = await _client.rpc(
      'actualizar_recorrido',
      params: {
        'p_recorrido_id': routeId,
        'p_accion': action,
        if (progress != null) 'p_porcentaje_avance': progress,
      },
    );
    return _singleRow(data);
  }

  // Acepta una fila compuesta o su representación como lista de una fila.
  // Nunca sustituye una respuesta inválida por progreso inventado.
  Map<String, dynamic> _singleRow(Object? data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List && data.length == 1 && data.first is Map) {
      return Map<String, dynamic>.from(data.first as Map);
    }
    throw const FormatException('Respuesta de recorrido inválida');
  }
}
