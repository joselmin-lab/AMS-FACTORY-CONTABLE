import 'package:flutter_test/flutter_test.dart';

import 'package:ams_control_contable/models/compra.dart';
import 'package:ams_control_contable/models/venta.dart';
import 'package:ams_control_contable/models/importacion.dart';
import 'package:ams_control_contable/models/tax_config.dart';
import 'package:ams_control_contable/models/gasto.dart';

void main() {
  group('Compra model', () {
    test('calculates total correctly', () {
      const compra = Compra(
        cantidad: 5,
        precio: 100,
        facturado: true,
        proveedor: 'Proveedor Test',
        metodoPago: 'Efectivo',
        fecha: _testDate,
      );
      expect(compra.total, 500.0);
    });

    test('serializes and deserializes from JSON', () {
      final json = {
        'id': '1',
        'parte_nombre': 'Amortiguador X',
        'cantidad': 3.0,
        'precio': 200.0,
        'facturado': true,
        'proveedor': 'Proveedor ABC',
        'metodo_pago': 'QR',
        'fecha': '2025-01-15T10:00:00.000',
      };
      final compra = Compra.fromJson(json);
      expect(compra.id, '1');
      expect(compra.total, 600.0);
      expect(compra.facturado, true);
    });
  });

  group('Venta model', () {
    test('calculates total correctly', () {
      const venta = Venta(
        cantidad: 2,
        precio: 300,
        facturado: false,
        cliente: 'Cliente Test',
        metodoPago: 'Tarjeta',
        fecha: _testDate,
      );
      expect(venta.total, 600.0);
    });
  });

  group('Importacion model', () {
    test('calculates costoTotal correctly', () {
      final importacion = Importacion(
        items: const [
          ItemImportacion(
            parteNombre: 'Parte A',
            cantidad: 10,
            precioUsFabrica: 50,
          ),
        ],
        porcentajeGA: 10,
        porcentajeIVA: 14.94,
        tipoCambio: 6.96,
        costoFlete: 500,
        costoDespachante: 300,
        otrosCostos: 100,
        fecha: _testDate,
      );

      // subtotalUsFabrica = 10 * 50 = 500
      expect(importacion.subtotalUsFabrica, 500.0);
      // costoGA = 500 * 0.10 = 50
      expect(importacion.costoGA, 50.0);
      // total > 0
      expect(importacion.costoTotal, greaterThan(0));
    });
  });

  group('TaxConfig model', () {
    test('defaults are correct', () {
      final config = TaxConfig.defaults();
      expect(config.ivaVentas, 13.0);
      expect(config.itVentas, 3.0);
      expect(config.ivaCompras, 13.0);
      expect(config.iueUtilidades, 25.0);
    });

    test('copyWith works correctly', () {
      final config = TaxConfig.defaults().copyWith(ivaVentas: 15.0);
      expect(config.ivaVentas, 15.0);
      expect(config.itVentas, 3.0);
    });
  });

  group('Gasto model', () {
    test('tipoLabel is correct for each type', () {
      const fijo = Gasto(
        descripcion: 'Alquiler',
        monto: 1000,
        tipo: TipoGasto.fijo,
        fecha: _testDate,
      );
      expect(fijo.tipoLabel, 'Fijo');

      const variable = Gasto(
        descripcion: 'Energía',
        monto: 500,
        tipo: TipoGasto.variable,
        fecha: _testDate,
      );
      expect(variable.tipoLabel, 'Variable');

      const sueldo = Gasto(
        descripcion: 'Empleado A',
        monto: 2000,
        tipo: TipoGasto.sueldo,
        fecha: _testDate,
      );
      expect(sueldo.tipoLabel, 'Sueldo');
    });
  });
}

const _testDate = DateTime(2025, 1, 15, 10, 0, 0);
