class ItemImportacion {
  final String? parteId;
  final String parteNombre;
  final double cantidad;
  final double precioUsFabrica;

  const ItemImportacion({
    this.parteId,
    required this.parteNombre,
    required this.cantidad,
    required this.precioUsFabrica,
  });

  factory ItemImportacion.fromJson(Map<String, dynamic> json) {
    return ItemImportacion(
      parteId: json['parte_id']?.toString(),
      parteNombre: json['parte_nombre']?.toString() ?? '',
      cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0,
      precioUsFabrica:
          (json['precio_us_fabrica'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'parte_id': parteId,
        'parte_nombre': parteNombre,
        'cantidad': cantidad,
        'precio_us_fabrica': precioUsFabrica,
      };
}

class Importacion {
  final String? id;
  final List<ItemImportacion> items;
  final double porcentajeGA;
  final double porcentajeIVA;
  final double tipoCambio;
  final double costoFlete;
  final double costoDespachante;
  final double otrosCostos;
  final DateTime fecha;
  final String? notas;
  final String? usuarioId;

  const Importacion({
    this.id,
    required this.items,
    required this.porcentajeGA,
    required this.porcentajeIVA,
    required this.tipoCambio,
    required this.costoFlete,
    required this.costoDespachante,
    required this.otrosCostos,
    required this.fecha,
    this.notas,
    this.usuarioId,
  });

  double get subtotalUsFabrica => items.fold(
        0,
        (sum, item) => sum + (item.cantidad * item.precioUsFabrica),
      );

  double get costoGA => subtotalUsFabrica * (porcentajeGA / 100);
  double get costoIVA =>
      (subtotalUsFabrica + costoGA) * (porcentajeIVA / 100);
  double get subtotalBolivianos =>
      (subtotalUsFabrica + costoGA + costoIVA) * tipoCambio;

  double get costoTotal =>
      subtotalBolivianos +
      costoFlete +
      costoDespachante +
      otrosCostos;

  factory Importacion.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return Importacion(
      id: json['id']?.toString(),
      items: itemsJson
          .map((e) =>
              ItemImportacion.fromJson(e as Map<String, dynamic>))
          .toList(),
      porcentajeGA: (json['porcentaje_ga'] as num?)?.toDouble() ?? 0,
      porcentajeIVA: (json['porcentaje_iva'] as num?)?.toDouble() ?? 0,
      tipoCambio: (json['tipo_cambio'] as num?)?.toDouble() ?? 6.96,
      costoFlete: (json['costo_flete'] as num?)?.toDouble() ?? 0,
      costoDespachante:
          (json['costo_despachante'] as num?)?.toDouble() ?? 0,
      otrosCostos: (json['otros_costos'] as num?)?.toDouble() ?? 0,
      fecha: json['fecha'] != null
          ? DateTime.parse(json['fecha'].toString())
          : DateTime.now(),
      notas: json['notas']?.toString(),
      usuarioId: json['usuario_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'items': items.map((e) => e.toJson()).toList(),
        'porcentaje_ga': porcentajeGA,
        'porcentaje_iva': porcentajeIVA,
        'tipo_cambio': tipoCambio,
        'costo_flete': costoFlete,
        'costo_despachante': costoDespachante,
        'otros_costos': otrosCostos,
        'costo_total': costoTotal,
        'fecha': fecha.toIso8601String(),
        'notas': notas,
        'usuario_id': usuarioId,
      };
}
