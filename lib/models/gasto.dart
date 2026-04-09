enum TipoGasto { fijo, variable, sueldo }

class Gasto {
  final String? id;
  final String descripcion;
  final double monto;
  final TipoGasto tipo;
  final bool facturado; // <--- NUEVO
  final DateTime fecha;
  final String? notas;
  final String? usuarioId;

  const Gasto({
    this.id,
    required this.descripcion,
    required this.monto,
    required this.tipo,
    this.facturado = false, // <--- NUEVO
    required this.fecha,
    this.notas,
    this.usuarioId,
  });

  String get tipoLabel {
    switch (tipo) {
      case TipoGasto.fijo: return 'Fijo';
      case TipoGasto.variable: return 'Variable';
      case TipoGasto.sueldo: return 'Sueldo';
    }
  }

  factory Gasto.fromJson(Map<String, dynamic> json) {
    TipoGasto tipoGasto;
    switch (json['tipo']?.toString()) {
      case 'variable': tipoGasto = TipoGasto.variable; break;
      case 'sueldo': tipoGasto = TipoGasto.sueldo; break;
      default: tipoGasto = TipoGasto.fijo;
    }
    return Gasto(
      id: json['id']?.toString(),
      descripcion: json['descripcion']?.toString() ?? '',
      monto: (json['monto'] as num?)?.toDouble() ?? 0,
      tipo: tipoGasto,
      facturado: json['facturado'] == true, // <--- NUEVO
      fecha: json['fecha'] != null ? DateTime.parse(json['fecha'].toString()) : DateTime.now(),
      notas: json['notas']?.toString(),
      usuarioId: json['usuario_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'descripcion': descripcion,
        'monto': monto,
        'tipo': tipo.name,
        'facturado': facturado, // <--- NUEVO
        'fecha': fecha.toIso8601String(),
        'notas': notas,
        'usuario_id': usuarioId,
      };
}