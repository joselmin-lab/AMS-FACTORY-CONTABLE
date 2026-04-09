class ImpItem {
  final String? id;
  final String producto;
  final double cantidad;
  final double pesoTotal;
  final double precioFobUsd;
  final double factorProrrateo;
  final double costoUnitarioBs;

  const ImpItem({
    this.id,
    required this.producto,
    required this.cantidad,
    this.pesoTotal = 0,
    required this.precioFobUsd,
    this.factorProrrateo = 0,
    this.costoUnitarioBs = 0,
  });

  double get totalFobUsd => cantidad * precioFobUsd;

  factory ImpItem.fromJson(Map<String, dynamic> json) => ImpItem(
        id: json['id']?.toString(),
        producto: json['producto']?.toString() ?? '',
        cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0,
        pesoTotal: (json['peso_total'] as num?)?.toDouble() ?? 0,
        precioFobUsd: (json['precio_fob_usd'] as num?)?.toDouble() ?? 0,
        factorProrrateo: (json['factor_prorrateo'] as num?)?.toDouble() ?? 0,
        costoUnitarioBs: (json['costo_unitario_bs'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'producto': producto,
        'cantidad': cantidad,
        'peso_total': pesoTotal,
        'precio_fob_usd': precioFobUsd,
        'factor_prorrateo': factorProrrateo,
        'costo_unitario_bs': costoUnitarioBs,
      };
}

class ImpGasto {
  final String? id;
  final String proveedor;
  final String descripcion;
  
  final String moneda; // 'Bs' o 'USD'
  final double montoOriginal; 
  final double tipoCambio;
  final double montoBs; // Lo que realmente vale para la contabilidad
  
  final bool esCapitalizable;
  final bool tieneIva;
  final String metodoProrrateo;
  final DateTime fechaGasto;

  const ImpGasto({
    this.id,
    required this.proveedor,
    required this.descripcion,
    this.moneda = 'Bs',
    this.montoOriginal = 0,
    this.tipoCambio = 1,
    required this.montoBs,
    this.esCapitalizable = true,
    this.tieneIva = false,
    this.metodoProrrateo = 'Valor',
    required this.fechaGasto,
  });

  factory ImpGasto.fromJson(Map<String, dynamic> json) => ImpGasto(
        id: json['id']?.toString(),
        proveedor: json['proveedor']?.toString() ?? '',
        descripcion: json['descripcion']?.toString() ?? '',
        moneda: json['moneda']?.toString() ?? 'Bs',
        montoOriginal: (json['monto_original'] as num?)?.toDouble() ?? 0,
        tipoCambio: (json['tipo_cambio'] as num?)?.toDouble() ?? 1,
        montoBs: (json['monto_bs'] as num?)?.toDouble() ?? 0,
        esCapitalizable: json['es_capitalizable'] == true,
        tieneIva: json['tiene_iva'] == true,
        metodoProrrateo: json['metodo_prorrateo']?.toString() ?? 'Valor',
        fechaGasto: json['fecha_gasto'] != null ? DateTime.parse(json['fecha_gasto'].toString()) : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'proveedor': proveedor,
        'descripcion': descripcion,
        'moneda': moneda,
        'monto_original': montoOriginal,
        'tipo_cambio': tipoCambio,
        'monto_bs': montoBs,
        'es_capitalizable': esCapitalizable,
        'tiene_iva': tieneIva,
        'metodo_prorrateo': metodoProrrateo,
        'fecha_gasto': fechaGasto.toIso8601String(),
      };
}

class ImpPago {
  final String? id;
  final String concepto;
  final String moneda; // 'USD' o 'Bs'
  final double montoOriginal;
  final double tipoCambio;
  final double montoBs;
  final DateTime fecha;

  const ImpPago({
    this.id,
    required this.concepto,
    this.moneda = 'USD',
    required this.montoOriginal,
    required this.tipoCambio,
    required this.montoBs,
    required this.fecha,
  });

  factory ImpPago.fromJson(Map<String, dynamic> json) => ImpPago(
        id: json['id']?.toString(),
        concepto: json['concepto']?.toString() ?? '',
        moneda: json['moneda']?.toString() ?? 'USD',
        montoOriginal: (json['monto_original'] as num?)?.toDouble() ?? 0,
        tipoCambio: (json['tipo_cambio'] as num?)?.toDouble() ?? 6.96,
        montoBs: (json['monto_bs'] as num?)?.toDouble() ?? 0,
        fecha: json['fecha'] != null ? DateTime.parse(json['fecha'].toString()) : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'concepto': concepto,
        'moneda': moneda,
        'monto_original': montoOriginal,
        'tipo_cambio': tipoCambio,
        'monto_bs': montoBs,
        'fecha': fecha.toIso8601String(),
      };
}

class ImpCarpeta {
  final String? id;
  final String numeroDespacho;
  final String proveedor;
  final DateTime fechaApertura;
  final DateTime? fechaCierre;
  final String estado;
  final double tipoCambio;
  
  // Estimaciones (Proyección Inicial)
  final double fleteEstimado;
  final double aduanaEstimada;
  final double otrosGastosEstimados;

  final double totalFobUsd;
  final double totalGastosBs;
  final double costoTotalBs;
  final String? notas;
  
  final List<ImpItem> items;
  final List<ImpGasto> gastos;
  final List<ImpPago> pagos;

  const ImpCarpeta({
    this.id,
    required this.numeroDespacho,
    required this.proveedor,
    required this.fechaApertura,
    this.fechaCierre,
    this.estado = 'En Tránsito',
    required this.tipoCambio,
    this.fleteEstimado = 0,
    this.aduanaEstimada = 0,
    this.otrosGastosEstimados = 0,
    this.totalFobUsd = 0,
    this.totalGastosBs = 0,
    this.costoTotalBs = 0,
    this.notas,
    this.items = const [],
    this.gastos = const [],
    this.pagos = const [],
  });

  factory ImpCarpeta.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['imp_items'] as List?)?.map((e) => ImpItem.fromJson(e)).toList() ?? [];
    final gastosList = (json['imp_gastos'] as List?)?.map((e) => ImpGasto.fromJson(e)).toList() ?? [];
    final pagosList = (json['imp_pagos'] as List?)?.map((e) => ImpPago.fromJson(e)).toList() ?? [];

    return ImpCarpeta(
      id: json['id']?.toString(),
      numeroDespacho: json['numero_despacho']?.toString() ?? '',
      proveedor: json['proveedor']?.toString() ?? '',
      fechaApertura: json['fecha_apertura'] != null ? DateTime.parse(json['fecha_apertura'].toString()) : DateTime.now(),
      fechaCierre: json['fecha_cierre'] != null ? DateTime.parse(json['fecha_cierre'].toString()) : null,
      estado: json['estado']?.toString() ?? 'En Tránsito',
      tipoCambio: (json['tipo_cambio'] as num?)?.toDouble() ?? 6.96,
      fleteEstimado: (json['flete_estimado'] as num?)?.toDouble() ?? 0,
      aduanaEstimada: (json['aduana_estimada'] as num?)?.toDouble() ?? 0,
      otrosGastosEstimados: (json['otros_gastos_estimados'] as num?)?.toDouble() ?? 0,
      totalFobUsd: (json['total_fob_usd'] as num?)?.toDouble() ?? 0,
      totalGastosBs: (json['total_gastos_bs'] as num?)?.toDouble() ?? 0,
      costoTotalBs: (json['costo_total_bs'] as num?)?.toDouble() ?? 0,
      notas: json['notas']?.toString(),
      items: itemsList,
      gastos: gastosList,
      pagos: pagosList,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'numero_despacho': numeroDespacho,
        'proveedor': proveedor,
        'fecha_apertura': fechaApertura.toIso8601String(),
        if (fechaCierre != null) 'fecha_cierre': fechaCierre!.toIso8601String(),
        'estado': estado,
        'tipo_cambio': tipoCambio,
        'flete_estimado': fleteEstimado,
        'aduana_estimada': aduanaEstimada,
        'otros_gastos_estimados': otrosGastosEstimados,
        'total_fob_usd': totalFobUsd,
        'total_gastos_bs': totalGastosBs,
        'costo_total_bs': costoTotalBs,
        'notas': notas,
      };
}