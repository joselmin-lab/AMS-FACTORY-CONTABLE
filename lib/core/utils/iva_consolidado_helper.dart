import 'package:ams_control_contable/models/compra.dart';
import 'package:ams_control_contable/models/gasto.dart';
import 'package:ams_control_contable/models/importacion.dart';
import 'package:ams_control_contable/models/ingreso.dart';
import 'package:ams_control_contable/models/salida.dart';
import 'package:ams_control_contable/models/venta.dart';

class IvaConsolidadoHelper {
  static double calcularIvaImportacionesMes({
    required List<ImpCarpeta> importaciones,
    required double ivaComprasPct,
    required DateTime mesReferencia,
  }) {
    double ivaImportacionesMes = 0;
    for (final carpeta in importaciones) {
      for (final gasto in carpeta.gastos) {
        if (!_esMismoMes(gasto.fechaGasto, mesReferencia)) continue;
        if (gasto.tipoSistema == 'IVA') {
          ivaImportacionesMes += gasto.montoBs;
        } else if (gasto.tieneIva) {
          ivaImportacionesMes += gasto.montoBs * (ivaComprasPct / 100);
        }
      }
    }
    return ivaImportacionesMes;
  }

  static double calcularSaldoIvaArrastrado({
    required List<Venta> ventas,
    required List<Ingreso> ingresos,
    required List<Compra> compras,
    required List<Salida> salidas,
    required List<Gasto> gastos,
    required List<ImpCarpeta> importaciones,
    required double ivaVentasPct,
    required double ivaComprasPct,
    required DateTime mesReferencia,
  }) {
    final fechas = <DateTime>[
      ...ventas.map((v) => v.fecha),
      ...ingresos.map((i) => i.fecha),
      ...compras.map((c) => c.fecha),
      ...salidas.map((s) => s.fecha),
      ...gastos.map((g) => g.fecha),
      for (final carpeta in importaciones) ...carpeta.gastos.map((g) => g.fechaGasto),
    ];

    if (fechas.isEmpty) return 0;

    final fechaInicial = _inicioMes(fechas.reduce((a, b) => a.isBefore(b) ? a : b));
    final limite = _inicioMes(DateTime(mesReferencia.year, mesReferencia.month - 1, 1));
    if (limite.isBefore(fechaInicial)) return 0;

    double saldo = 0;
    DateTime cursor = fechaInicial;
    while (!cursor.isAfter(limite)) {
      final ventasFacMes = ventas
          .where((v) => v.facturado && _esMismoMes(v.fecha, cursor))
          .fold(0.0, (sum, v) => sum + (v.precio * v.cantidad));
      final ingresosFacMes = ingresos
          .where((i) => i.facturado && _esMismoMes(i.fecha, cursor))
          .fold(0.0, (sum, i) => sum + i.precio);
      final debitoMes = (ventasFacMes + ingresosFacMes) * (ivaVentasPct / 100);

      final comprasFacMes = compras
          .where((c) => c.facturado && _esMismoMes(c.fecha, cursor))
          .fold(0.0, (sum, c) => sum + (c.precio * c.cantidad));
      final salidasFacMes = salidas
          .where((s) => s.facturado && _esMismoMes(s.fecha, cursor))
          .fold(0.0, (sum, s) => sum + s.precio);
      final gastosFacMes = gastos
          .where((g) => g.facturado && _esMismoMes(g.fecha, cursor))
          .fold(0.0, (sum, g) => sum + g.monto);
      final creditoLocalMes = (comprasFacMes + salidasFacMes + gastosFacMes) * (ivaComprasPct / 100);
      final ivaImportacionesMes = calcularIvaImportacionesMes(
        importaciones: importaciones,
        ivaComprasPct: ivaComprasPct,
        mesReferencia: cursor,
      );

      final resultadoMes = creditoLocalMes + ivaImportacionesMes + saldo - debitoMes;
      saldo = resultadoMes > 0 ? resultadoMes : 0;
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    return saldo;
  }

  static bool _esMismoMes(DateTime fecha, DateTime referencia) =>
      fecha.year == referencia.year && fecha.month == referencia.month;

  static DateTime _inicioMes(DateTime fecha) => DateTime(fecha.year, fecha.month, 1);
}
