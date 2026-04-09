class Ingreso {
  final String? id;
  final String detalle;
  final String? descripcion;
  final double precio;
  final String metodoPago;
  final bool facturado;
  final DateTime fecha;

  const Ingreso({
    this.id,
    required this.detalle,
    this.descripcion,
    required this.precio,
    required this.metodoPago,
    this.facturado = false,
    required this.fecha,
  });

  factory Ingreso.fromJson(Map<String, dynamic> json) {
    return Ingreso(
      id: json['id']?.toString(),
      detalle: json['detalle']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      precio: (json['precio'] as num?)?.toDouble() ?? 0,
      metodoPago: json['metodo_pago']?.toString() ?? 'Efectivo',
      facturado: json['facturado'] == true,
      fecha: json['fecha'] != null ? DateTime.parse(json['fecha'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'detalle': detalle,
        'descripcion': descripcion,
        'precio': precio,
        'metodo_pago': metodoPago,
        'facturado': facturado,
        'fecha': fecha.toIso8601String(),
      };
}