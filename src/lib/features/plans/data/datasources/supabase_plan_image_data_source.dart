import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/plan_image.dart';

/// Un bucket público para las imágenes de planes; solo un organizador
/// autenticado puede escribir o eliminar objetos en su propia carpeta.
class SupabasePlanImageDataSource {
  const SupabasePlanImageDataSource(this.client);

  static const bucket = 'plan-images';
  final SupabaseClient client;

  Future<String> upload(PlanImage image) async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw StateError('Debes iniciar sesión.');

    // Path inmutable: evitar upsert, caché obsoleta y sobreescritura accidental.
    final random = Random.secure();
    final filename = List.generate(
      16,
      (_) => random.nextInt(256),
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    final path = '$uid/$filename.${image.extension}';

    await client.storage
        .from(bucket)
        .uploadBinary(
          path,
          image.bytes,
          fileOptions: FileOptions(
            contentType: image.mimeType,
            cacheControl: '3600',
            upsert: false,
          ),
        );
    return path;
  }

  Future<void> delete(String path) async {
    await client.storage.from(bucket).remove([path]);
  }

  String publicUrl(String path) =>
      client.storage.from(bucket).getPublicUrl(path);
}
