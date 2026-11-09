import '../../domain/entities/plan_image.dart';
import '../../domain/repositories/plan_image_repository.dart';
import '../datasources/supabase_plan_image_data_source.dart';

class SupabasePlanImageRepository implements PlanImageRepository {
  const SupabasePlanImageRepository(this.source);
  final SupabasePlanImageDataSource source;

  @override
  Future<String> upload(PlanImage image) => source.upload(image);

  @override
  Future<void> delete(String path) => source.delete(path);

  @override
  String publicUrl(String path) => source.publicUrl(path);
}
