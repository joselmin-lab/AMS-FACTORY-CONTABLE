class Salida {
  final String? id;
  final String detalle;
  final String? descripcion;
  final double precio;
  final String metodoPago;
  final bool facturado;
  final DateTime fecha;
  final String? usuarioId;

  const Salida({
    this.id,
    required this.detalle,
    this.descripcion,
    required this.precio,
    required this.metodoPago,
    required this.facturado,
    required this.fecha,
    this.usuarioId,
  });

  factory Salida.fromJson(Map<String, dynamic> json) {
    return Salida(
      id: json['id']?.toString(),
      detalle: json['detalle']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      precio: (json['precio'] as num?)?.toDouble() ?? 0,
      metodoPago: json['metodo_pago']?.toString() ?? '',
      facturado: json['facturado'] as bool? ?? false,
      fecha: json['fecha'] != null
          ? DateTime.parse(json['fecha'].toString())
          : DateTime.now(),
      usuarioId: json['usuario_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'detalle': detalle,
      'descripcion': descripcion,
      'precio': precio,
      'metodo_pago': metodoPago,
      'facturado': facturado,
      'fecha': fecha.toIso8601String(),
      'usuario_id': usuarioId,
    };
  }
}