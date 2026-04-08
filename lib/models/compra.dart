class Compra {
  final String? id;
  final String? parteId;
  final String? parteNombre;
  final double cantidad;
  final double precio;
  final bool facturado;
  final String proveedor;
  final String metodoPago;
  final DateTime fecha;
  final String? notas;
  final String? usuarioId;

  const Compra({
    this.id,
    this.parteId,
    this.parteNombre,
    required this.cantidad,
    required this.precio,
    required this.facturado,
    required this.proveedor,
    required this.metodoPago,
    required this.fecha,
    this.notas,
    this.usuarioId,
  });

  double get total => cantidad * precio;

  factory Compra.fromJson(Map<String, dynamic> json) {
    return Compra(
      id: json['id']?.toString(),
      parteId: json['parte_id']?.toString(),
      parteNombre: json['parte_nombre']?.toString(),
      cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0,
      precio: (json['precio'] as num?)?.toDouble() ?? 0,
      facturado: json['facturado'] as bool? ?? false,
      proveedor: json['proveedor']?.toString() ?? '',
      metodoPago: json['metodo_pago']?.toString() ?? '',
      fecha: json['fecha'] != null
          ? DateTime.parse(json['fecha'].toString())
          : DateTime.now(),
      notas: json['notas']?.toString(),
      usuarioId: json['usuario_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'parte_id': parteId,
      'parte_nombre': parteNombre,
      'cantidad': cantidad,
      'precio': precio,
      'facturado': facturado,
      'proveedor': proveedor,
      'metodo_pago': metodoPago,
      'fecha': fecha.toIso8601String(),
      'notas': notas,
      'usuario_id': usuarioId,
    };
  }

  Compra copyWith({
    String? id,
    String? parteId,
    String? parteNombre,
    double? cantidad,
    double? precio,
    bool? facturado,
    String? proveedor,
    String? metodoPago,
    DateTime? fecha,
    String? notas,
    String? usuarioId,
  }) {
    return Compra(
      id: id ?? this.id,
      parteId: parteId ?? this.parteId,
      parteNombre: parteNombre ?? this.parteNombre,
      cantidad: cantidad ?? this.cantidad,
      precio: precio ?? this.precio,
      facturado: facturado ?? this.facturado,
      proveedor: proveedor ?? this.proveedor,
      metodoPago: metodoPago ?? this.metodoPago,
      fecha: fecha ?? this.fecha,
      notas: notas ?? this.notas,
      usuarioId: usuarioId ?? this.usuarioId,
    );
  }
}
