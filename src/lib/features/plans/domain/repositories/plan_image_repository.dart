import '../entities/plan_image.dart';

/// Contrato de almacenamiento de imágenes. El dominio no conoce Supabase.
abstract class PlanImageRepository {
  /// Devuelve el path relativo dentro del bucket (nunca una URL pública).
  Future<String> upload(PlanImage image);
  Future<void> delete(String path);
  String publicUrl(String path);
}
