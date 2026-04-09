class ImpItem {
  final String? id;
  final String? inventarioId;
  final String producto;
  final double cantidad;
  final double pesoTotal;
  final double precioFobUsd;
  
  final double gaPct;
  final double ivaPct;

  final double factorProrrateo;
  final double costoUnitarioBs;

  const ImpItem({
    this.id,
    this.inventarioId,
    required this.producto,
    required this.cantidad,
    this.pesoTotal = 0,
    required this.precioFobUsd,
    this.gaPct = 0,
    this.ivaPct = 14.94,
    this.factorProrrateo = 0,
    this.costoUnitarioBs = 0,
  });

  double get totalFobUsd => cantidad * precioFobUsd;
  
  // LA MAGIA ESTÁ AQUÍ: Se multiplica el FOB por el porcentaje declarado antes de sacar el impuesto
  double totalGaBs(double tipoCambio, double pctDeclaracion) {
    final baseDeclaradaBs = (totalFobUsd * tipoCambio) * (pctDeclaracion / 100);
    return baseDeclaradaBs * (gaPct / 100);
  }

  double totalIvaBs(double tipoCambio, double pctDeclaracion) {
    final baseDeclaradaBs = (totalFobUsd * tipoCambio) * (pctDeclaracion / 100);
    final gaCalculado = totalGaBs(tipoCambio, pctDeclaracion);
    return (baseDeclaradaBs + gaCalculado) * (ivaPct / 100);
  }

  factory ImpItem.fromJson(Map<String, dynamic> json) => ImpItem(
        id: json['id']?.toString(),
        inventarioId: json['inventario_id']?.toString(),
        producto: json['producto']?.toString() ?? '',
        cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0,
        pesoTotal: (json['peso_total'] as num?)?.toDouble() ?? 0,
        precioFobUsd: (json['precio_fob_usd'] as num?)?.toDouble() ?? 0,
        gaPct: (json['ga_pct'] as num?)?.toDouble() ?? 0,
        ivaPct: (json['iva_pct'] as num?)?.toDouble() ?? 14.94,
        factorProrrateo: (json['factor_prorrateo'] as num?)?.toDouble() ?? 0,
        costoUnitarioBs: (json['costo_unitario_bs'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (inventarioId != null) 'inventario_id': inventarioId,
        'producto': producto,
        'cantidad': cantidad,
        'peso_total': pesoTotal,
        'precio_fob_usd': precioFobUsd,
        'ga_pct': gaPct,
        'iva_pct': ivaPct,
        'factor_prorrateo': factorProrrateo,
        'costo_unitario_bs': costoUnitarioBs,
      };
}

class ImpGasto {
  final String? id;
  final String proveedor;
  final String descripcion;
  final String moneda; 
  final double montoOriginal; 
  final double tipoCambio;
  final double montoBs; 
  final bool esCapitalizable;
  final bool tieneIva;
  final String metodoProrrateo;
  final DateTime fechaGasto;
  final String? tipoSistema;

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
    this.tipoSistema,
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
        tipoSistema: json['tipo_sistema']?.toString(),
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
        if (tipoSistema != null) 'tipo_sistema': tipoSistema,
      };
}

class ImpPago {
  final String? id;
  final String? gastoId;
  final String concepto;
  final String moneda; 
  final double montoOriginal;
  final double tipoCambio;
  final double montoBs;
  final DateTime fecha;

  const ImpPago({
    this.id,
    this.gastoId,
    required this.concepto,
    this.moneda = 'USD',
    required this.montoOriginal,
    required this.tipoCambio,
    required this.montoBs,
    required this.fecha,
  });

  factory ImpPago.fromJson(Map<String, dynamic> json) => ImpPago(
        id: json['id']?.toString(),
        gastoId: json['gasto_id']?.toString(),
        concepto: json['concepto']?.toString() ?? '',
        moneda: json['moneda']?.toString() ?? 'USD',
        montoOriginal: (json['monto_original'] as num?)?.toDouble() ?? 0,
        tipoCambio: (json['tipo_cambio'] as num?)?.toDouble() ?? 6.96,
        montoBs: (json['monto_bs'] as num?)?.toDouble() ?? 0,
        fecha: json['fecha'] != null ? DateTime.parse(json['fecha'].toString()) : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (gastoId != null) 'gasto_id': gastoId,
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
  final String incoterm;
  final DateTime fechaApertura;
  final DateTime? fechaEmbarque;
  final DateTime? fechaLlegada;
  final DateTime? fechaCierre;
  final String estado;
  final double tipoCambio;
  
  // Variables de Impuestos
  final bool usaImpuestosGlobales;
  final double gaGlobalPct;
  final double ivaGlobalPct;
  final double porcentajeDeclaracion; // NUEVO: % de valor facturado para Aduana

  // Estimaciones Proforma
  final double fleteEstimadoUsd;
  final double aduanaIvaEstimadoBs;
  final double aduanaGaEstimadoBs;
  final double despachanteEstimadoBs;
  final double documentacionEstimadaBs;
  final double almacenajeEstimadoBs;

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
    this.incoterm = 'FOB',
    required this.fechaApertura,
    this.fechaEmbarque,
    this.fechaLlegada,
    this.fechaCierre,
    this.estado = 'En Tránsito',
    required this.tipoCambio,
    this.usaImpuestosGlobales = true,
    this.gaGlobalPct = 10,
    this.ivaGlobalPct = 14.94,
    this.porcentajeDeclaracion = 100, // Por defecto al 100%
    this.fleteEstimadoUsd = 0,
    this.aduanaIvaEstimadoBs = 0,
    this.aduanaGaEstimadoBs = 0,
    this.despachanteEstimadoBs = 0,
    this.documentacionEstimadaBs = 0,
    this.almacenajeEstimadoBs = 0,
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
      incoterm: json['incoterm']?.toString() ?? 'FOB',
      fechaApertura: json['fecha_apertura'] != null ? DateTime.parse(json['fecha_apertura'].toString()) : DateTime.now(),
      fechaEmbarque: json['fecha_embarque'] != null ? DateTime.parse(json['fecha_embarque'].toString()) : null,
      fechaLlegada: json['fecha_llegada'] != null ? DateTime.parse(json['fecha_llegada'].toString()) : null,
      fechaCierre: json['fecha_cierre'] != null ? DateTime.parse(json['fecha_cierre'].toString()) : null,
      estado: json['estado']?.toString() ?? 'En Tránsito',
      tipoCambio: (json['tipo_cambio'] as num?)?.toDouble() ?? 6.96,
      usaImpuestosGlobales: json['usa_impuestos_globales'] ?? true,
      gaGlobalPct: (json['ga_global_pct'] as num?)?.toDouble() ?? 10,
      ivaGlobalPct: (json['iva_global_pct'] as num?)?.toDouble() ?? 14.94,
      porcentajeDeclaracion: (json['porcentaje_declaracion'] as num?)?.toDouble() ?? 100,
      fleteEstimadoUsd: (json['flete_estimado_usd'] as num?)?.toDouble() ?? 0,
      aduanaIvaEstimadoBs: (json['aduana_iva_estimado_bs'] as num?)?.toDouble() ?? 0,
      aduanaGaEstimadoBs: (json['aduana_ga_estimado_bs'] as num?)?.toDouble() ?? 0,
      despachanteEstimadoBs: (json['despachante_estimado_bs'] as num?)?.toDouble() ?? 0,
      documentacionEstimadaBs: (json['documentacion_estimada_bs'] as num?)?.toDouble() ?? 0,
      almacenajeEstimadoBs: (json['almacenaje_estimado_bs'] as num?)?.toDouble() ?? 0,
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
        'incoterm': incoterm,
        'fecha_apertura': fechaApertura.toIso8601String(),
        if (fechaEmbarque != null) 'fecha_embarque': fechaEmbarque!.toIso8601String(),
        if (fechaLlegada != null) 'fecha_llegada': fechaLlegada!.toIso8601String(),
        if (fechaCierre != null) 'fecha_cierre': fechaCierre!.toIso8601String(),
        'estado': estado,
        'tipo_cambio': tipoCambio,
        'usa_impuestos_globales': usaImpuestosGlobales,
        'ga_global_pct': gaGlobalPct,
        'iva_global_pct': ivaGlobalPct,
        'porcentaje_declaracion': porcentajeDeclaracion,
        'flete_estimado_usd': fleteEstimadoUsd,
        'aduana_iva_estimado_bs': aduanaIvaEstimadoBs,
        'aduana_ga_estimado_bs': aduanaGaEstimadoBs,
        'despachante_estimado_bs': despachanteEstimadoBs,
        'documentacion_estimada_bs': documentacionEstimadaBs,
        'almacenaje_estimado_bs': almacenajeEstimadoBs,
        'total_fob_usd': totalFobUsd,
        'total_gastos_bs': totalGastosBs,
        'costo_total_bs': costoTotalBs,
        'notas': notas,
      };
}