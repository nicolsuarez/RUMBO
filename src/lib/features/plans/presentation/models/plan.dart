import 'package:flutter/material.dart';

class Plan {
  final String id;
  final String titulo;
  final String lugar;
  final String fecha;
  final String dificultad;
  final String distancia;
  final String desnivel;

  final int cupos;
  int van;

  final String precio;
  final String organizador;
  final String rolOrganizador;

  final List<String> tags;
  final Color color1;
  final Color color2;
  final List<double> elevacion;

  final String descripcion;
  final List<String> llevar;
  final String imageAsset;

  Plan({
    required this.id,
    required this.titulo,
    required this.lugar,
    required this.fecha,
    required this.dificultad,
    required this.distancia,
    required this.desnivel,
    required this.cupos,
    required this.van,
    required this.precio,
    required this.organizador,
    required this.rolOrganizador,
    required this.tags,
    required this.color1,
    required this.color2,
    required this.elevacion,
    required this.descripcion,
    required this.llevar,
    required this.imageAsset,
  });
}
