class TaxConfig {
  final String? id;
  final double ivaVentas;
  final double itVentas;
  final double ivaCompras;
  final double iueUtilidades;
  final DateTime? updatedAt;

  const TaxConfig({
    this.id,
    required this.ivaVentas,
    required this.itVentas,
    required this.ivaCompras,
    required this.iueUtilidades,
    this.updatedAt,
  });

  factory TaxConfig.defaults() {
    return const TaxConfig(
      ivaVentas: 13.0,
      itVentas: 3.0,
      ivaCompras: 13.0,
      iueUtilidades: 25.0,
    );
  }

  factory TaxConfig.fromJson(Map<String, dynamic> json) {
    return TaxConfig(
      id: json['id']?.toString(),
      ivaVentas: (json['iva_ventas'] as num?)?.toDouble() ?? 13.0,
      itVentas: (json['it_ventas'] as num?)?.toDouble() ?? 3.0,
      ivaCompras: (json['iva_compras'] as num?)?.toDouble() ?? 13.0,
      iueUtilidades: (json['iue_utilidades'] as num?)?.toDouble() ?? 25.0,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'iva_ventas': ivaVentas,
        'it_ventas': itVentas,
        'iva_compras': ivaCompras,
        'iue_utilidades': iueUtilidades,
      };

  TaxConfig copyWith({
    String? id,
    double? ivaVentas,
    double? itVentas,
    double? ivaCompras,
    double? iueUtilidades,
    DateTime? updatedAt,
  }) {
    return TaxConfig(
      id: id ?? this.id,
      ivaVentas: ivaVentas ?? this.ivaVentas,
      itVentas: itVentas ?? this.itVentas,
      ivaCompras: ivaCompras ?? this.ivaCompras,
      iueUtilidades: iueUtilidades ?? this.iueUtilidades,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
