import 'package:ams_control_contable/models/cuenta_cobrar.dart';

class CuentaPagar {
  final String? id;
  final String proveedor;
  final String? compraId;
  final double montoTotal;
  final double montoPagado;
  final EstadoCuenta estado;
  final DateTime fechaEmision;
  final DateTime? fechaVencimiento;
  final String? notas;

  const CuentaPagar({
    this.id,
    required this.proveedor,
    this.compraId,
    required this.montoTotal,
    this.montoPagado = 0,
    this.estado = EstadoCuenta.pendiente,
    required this.fechaEmision,
    this.fechaVencimiento,
    this.notas,
  });

  double get saldoPendiente => montoTotal - montoPagado;

  String get estadoLabel {
    switch (estado) {
      case EstadoCuenta.pendiente:
        return 'Pendiente';
      case EstadoCuenta.parcial:
        return 'Pago Parcial';
      case EstadoCuenta.pagado:
        return 'Pagado';
      case EstadoCuenta.vencido:
        return 'Vencido';
    }
  }

  factory CuentaPagar.fromJson(Map<String, dynamic> json) {
    EstadoCuenta estadoCuenta;
    switch (json['estado']?.toString()) {
      case 'parcial':
        estadoCuenta = EstadoCuenta.parcial;
        break;
      case 'pagado':
        estadoCuenta = EstadoCuenta.pagado;
        break;
      case 'vencido':
        estadoCuenta = EstadoCuenta.vencido;
        break;
      default:
        estadoCuenta = EstadoCuenta.pendiente;
    }
    return CuentaPagar(
      id: json['id']?.toString(),
      proveedor: json['proveedor']?.toString() ?? '',
      compraId: json['compra_id']?.toString(),
      montoTotal: (json['monto_total'] as num?)?.toDouble() ?? 0,
      montoPagado: (json['monto_pagado'] as num?)?.toDouble() ?? 0,
      estado: estadoCuenta,
      fechaEmision: json['fecha_emision'] != null
          ? DateTime.parse(json['fecha_emision'].toString())
          : DateTime.now(),
      fechaVencimiento: json['fecha_vencimiento'] != null
          ? DateTime.parse(json['fecha_vencimiento'].toString())
          : null,
      notas: json['notas']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'proveedor': proveedor,
        'compra_id': compraId,
        'monto_total': montoTotal,
        'monto_pagado': montoPagado,
        'estado': estado.name,
        'fecha_emision': fechaEmision.toIso8601String(),
        'fecha_vencimiento': fechaVencimiento?.toIso8601String(),
        'notas': notas,
      };
}
