import 'package:ams_control_contable/core/utils/iva_consolidado_helper.dart';
import 'package:ams_control_contable/models/compra.dart';
import 'package:ams_control_contable/models/gasto.dart';
import 'package:ams_control_contable/models/importacion.dart';
import 'package:ams_control_contable/models/ingreso.dart';
import 'package:ams_control_contable/models/salida.dart';
import 'package:ams_control_contable/models/venta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('arrastra crédito facturado de meses anteriores sin cierre', () {
    final saldo = IvaConsolidadoHelper.calcularSaldoIvaArrastrado(
      ventas: const [],
      ingresos: const [],
      compras: [
        Compra(
          cantidad: 1,
          precio: 100,
          facturado: true,
          proveedor: 'Proveedor',
          metodoPago: 'Efectivo',
          fecha: DateTime(2026, 5, 10),
        ),
      ],
      salidas: const [],
      gastos: const [],
      importaciones: const [],
      ivaVentasPct: 13,
      ivaComprasPct: 13,
      mesReferencia: DateTime(2026, 6, 1),
    );

    expect(saldo, 13);
  });

  test('solo arrastra saldo a favor y reinicia en cero cuando el mes da por pagar', () {
    final saldo = IvaConsolidadoHelper.calcularSaldoIvaArrastrado(
      ventas: const [
        Venta(
          cantidad: 1,
          precio: 100,
          facturado: true,
          cliente: 'Cliente A',
          metodoPago: 'Efectivo',
          fecha: DateTime(2026, 4, 10),
        ),
        Venta(
          cantidad: 1,
          precio: 200,
          facturado: true,
          cliente: 'Cliente B',
          metodoPago: 'Efectivo',
          fecha: DateTime(2026, 6, 5),
        ),
      ],
      ingresos: const [],
      compras: const [
        Compra(
          cantidad: 1,
          precio: 100,
          facturado: true,
          proveedor: 'Proveedor',
          metodoPago: 'Efectivo',
          fecha: DateTime(2026, 5, 15),
        ),
      ],
      salidas: const [],
      gastos: const [],
      importaciones: const [],
      ivaVentasPct: 13,
      ivaComprasPct: 13,
      mesReferencia: DateTime(2026, 7, 1),
    );

    expect(saldo, 0);
  });

  test('incluye crédito fiscal de importaciones por tipo IVA', () {
    final saldo = IvaConsolidadoHelper.calcularSaldoIvaArrastrado(
      ventas: const [],
      ingresos: const [],
      compras: const [],
      salidas: const [],
      gastos: const [],
      importaciones: [
        ImpCarpeta(
          numeroDespacho: 'D-1',
          proveedor: 'Aduana',
          fechaApertura: DateTime(2026, 5, 1),
          tipoCambio: 6.96,
          gastos: const [
            ImpGasto(
              proveedor: 'Aduana',
              descripcion: 'IVA póliza',
              montoBs: 20,
              fechaGasto: DateTime(2026, 5, 20),
              tipoSistema: 'IVA',
            ),
          ],
        ),
      ],
      ivaVentasPct: 13,
      ivaComprasPct: 13,
      mesReferencia: DateTime(2026, 6, 1),
    );

    expect(saldo, 20);
  });

  test('incluye crédito fiscal de importaciones con tieneIva', () {
    final saldo = IvaConsolidadoHelper.calcularSaldoIvaArrastrado(
      ventas: const [],
      ingresos: const [],
      compras: const [],
      salidas: const [],
      gastos: const [],
      importaciones: [
        ImpCarpeta(
          numeroDespacho: 'D-2',
          proveedor: 'Proveedor',
          fechaApertura: DateTime(2026, 5, 1),
          tipoCambio: 6.96,
          gastos: const [
            ImpGasto(
              proveedor: 'Despachante',
              descripcion: 'Servicio con IVA',
              montoBs: 100,
              fechaGasto: DateTime(2026, 5, 5),
              tieneIva: true,
            ),
          ],
        ),
      ],
      ivaVentasPct: 13,
      ivaComprasPct: 13,
      mesReferencia: DateTime(2026, 6, 1),
    );

    expect(saldo, 13);
  });

  test('retorna cero cuando no existen movimientos previos', () {
    final saldo = IvaConsolidadoHelper.calcularSaldoIvaArrastrado(
      ventas: const [],
      ingresos: const [],
      compras: const [],
      salidas: const [],
      gastos: const [],
      importaciones: const [],
      ivaVentasPct: 13,
      ivaComprasPct: 13,
      mesReferencia: DateTime(2026, 6, 1),
    );

    expect(saldo, 0);
  });

  test('calcula IVA importaciones del mes de referencia', () {
    final ivaMes = IvaConsolidadoHelper.calcularIvaImportacionesMes(
      importaciones: [
        ImpCarpeta(
          numeroDespacho: 'D-3',
          proveedor: 'Proveedor',
          fechaApertura: DateTime(2026, 5, 1),
          tipoCambio: 6.96,
          gastos: const [
            ImpGasto(
              proveedor: 'Aduana',
              descripcion: 'IVA póliza',
              montoBs: 15,
              fechaGasto: DateTime(2026, 6, 1),
              tipoSistema: 'IVA',
            ),
            ImpGasto(
              proveedor: 'Otro',
              descripcion: 'Gasto con IVA',
              montoBs: 100,
              fechaGasto: DateTime(2026, 6, 2),
              tieneIva: true,
            ),
            ImpGasto(
              proveedor: 'Otro',
              descripcion: 'Otro mes',
              montoBs: 100,
              fechaGasto: DateTime(2026, 5, 2),
              tieneIva: true,
            ),
          ],
        ),
      ],
      ivaComprasPct: 13,
      mesReferencia: DateTime(2026, 6, 1),
    );

    expect(ivaMes, 28);
  });

  test('usa gastos facturados para crédito fiscal arrastrado', () {
    final saldo = IvaConsolidadoHelper.calcularSaldoIvaArrastrado(
      ventas: const [],
      ingresos: const [],
      compras: const [],
      salidas: const [],
      gastos: const [
        Gasto(
          descripcion: 'Gasto facturado',
          monto: 100,
          tipo: TipoGasto.variable,
          facturado: true,
          fecha: DateTime(2026, 5, 10),
        ),
      ],
      importaciones: const [],
      ivaVentasPct: 13,
      ivaComprasPct: 13,
      mesReferencia: DateTime(2026, 6, 1),
    );

    expect(saldo, 13);
  });

  test('usa salidas facturadas para crédito fiscal arrastrado', () {
    final saldo = IvaConsolidadoHelper.calcularSaldoIvaArrastrado(
      ventas: const [],
      ingresos: const [],
      compras: const [],
      salidas: const [
        Salida(
          detalle: 'Salida facturada',
          descripcion: 'Servicio',
          precio: 100,
          metodoPago: 'Efectivo',
          facturado: true,
          fecha: DateTime(2026, 5, 10),
        ),
      ],
      gastos: const [],
      importaciones: const [],
      ivaVentasPct: 13,
      ivaComprasPct: 13,
      mesReferencia: DateTime(2026, 6, 1),
    );

    expect(saldo, 13);
  });

  test('usa ingresos facturados para débito fiscal arrastrado', () {
    final saldo = IvaConsolidadoHelper.calcularSaldoIvaArrastrado(
      ventas: const [],
      ingresos: const [
        Ingreso(
          detalle: 'Ingreso facturado',
          precio: 100,
          metodoPago: 'Efectivo',
          facturado: true,
          fecha: DateTime(2026, 5, 10),
        ),
      ],
      compras: const [],
      salidas: const [],
      gastos: const [],
      importaciones: const [],
      ivaVentasPct: 13,
      ivaComprasPct: 13,
      mesReferencia: DateTime(2026, 6, 1),
    );

    expect(saldo, 0);
  });
}
