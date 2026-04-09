import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ams_control_contable/widgets/app_drawer.dart';
import 'package:ams_control_contable/services/pdf_service.dart';

import 'package:ams_control_contable/services/ventas_service.dart';
import 'package:ams_control_contable/services/compras_service.dart';
import 'package:ams_control_contable/services/ingresos_service.dart';
import 'package:ams_control_contable/services/salidas_service.dart';
import 'package:ams_control_contable/services/cuentas_cobrar_service.dart';
import 'package:ams_control_contable/services/cuentas_pagar_service.dart';
import 'package:ams_control_contable/services/impositivo_service.dart';
import 'package:ams_control_contable/services/gastos_service.dart';
import 'package:ams_control_contable/services/importaciones_service.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VentasService>().fetchVentas();
      context.read<ComprasService>().fetchCompras();
      context.read<IngresosService>().fetchIngresos();
      context.read<SalidasService>().fetchSalidas();
      context.read<CuentasCobrarService>().fetchCuentas();
      context.read<CuentasPagarService>().fetchCuentas();
      context.read<ImpositivoService>().fetchConfig();
      context.read<GastosService>().fetchGastos();
      context.read<ImportacionesService>().fetchCarpetas();
    });
  }

  bool _esMesSeleccionado(DateTime fecha) {
    return fecha.year == _selectedYear && fecha.month == _selectedMonth;
  }

  void _generarReporteImpositivo() async {
    try {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generando Reporte Impositivo...'), duration: Duration(seconds: 1)));

      final ventas = context.read<VentasService>().ventas;
      final compras = context.read<ComprasService>().compras;
      final ingresos = context.read<IngresosService>().ingresos;
      final salidas = context.read<SalidasService>().salidas;
      final gastos = context.read<GastosService>().gastos;
      final importaciones = context.read<ImportacionesService>().carpetas;
      final configImp = context.read<ImpositivoService>().config;

      final ventasFacMes = ventas.where((v) => v.facturado && _esMesSeleccionado(v.fecha)).fold(0.0, (sum, v) => sum + (v.precio * v.cantidad));
      final ingresosFacMes = ingresos.where((i) => i.facturado && _esMesSeleccionado(i.fecha)).fold(0.0, (sum, i) => sum + i.precio);
      final baseVentas = ventasFacMes + ingresosFacMes;
      final ivaVentasTotal = baseVentas * (configImp.ivaVentas / 100);

      final comprasFacMes = compras.where((c) => c.facturado && _esMesSeleccionado(c.fecha)).fold(0.0, (sum, c) => sum + (c.precio * c.cantidad));
      final salidasFacMes = salidas.where((s) => s.facturado && _esMesSeleccionado(s.fecha)).fold(0.0, (sum, s) => sum + s.precio);
      final gastosFacMes = gastos.where((g) => (g.facturado ?? false) && _esMesSeleccionado(g.fecha)).fold(0.0, (sum, g) => sum + (g.monto ?? 0));
      final baseComprasLocal = comprasFacMes + salidasFacMes + gastosFacMes;
      final ivaComprasLocal = baseComprasLocal * (configImp.ivaCompras / 100);

      double ivaImportacionesMes = 0;
      for (var carpeta in importaciones) {
        for (var gasto in carpeta.gastos) {
          if (gasto.fechaGasto.year == _selectedYear && gasto.fechaGasto.month == _selectedMonth) {
            if (gasto.tipoSistema == 'IVA') {
              ivaImportacionesMes += gasto.montoBs;
            } else if (gasto.tieneIva) {
              ivaImportacionesMes += gasto.montoBs * (configImp.ivaCompras / 100);
            }
          }
        }
      }

      final ivaComprasTotal = ivaComprasLocal + ivaImportacionesMes + configImp.saldoIvaAnterior;
      final saldoIva = ivaComprasTotal - ivaVentasTotal;

      final itCalculadoOriginal = baseVentas * (configImp.itVentas / 100);
      double itPorPagarReal = 0;
      double iueSobranteParaElFuturo = configImp.saldoIuePorCompensar;

      if (iueSobranteParaElFuturo >= itCalculadoOriginal) {
        itPorPagarReal = 0;
        iueSobranteParaElFuturo -= itCalculadoOriginal;
      } else {
        itPorPagarReal = itCalculadoOriginal - iueSobranteParaElFuturo;
        iueSobranteParaElFuturo = 0;
      }

      final cuentasCobrar = context.read<CuentasCobrarService>().cuentas;
      final cuentasPagar = context.read<CuentasPagarService>().cuentas;
      
      final totalEntradas = ventas.where((v) => v.metodoPago != 'Crédito' && _esMesSeleccionado(v.fecha)).fold(0.0, (sum, v) => sum + (v.precio * v.cantidad)) + 
                            ingresos.where((i) => _esMesSeleccionado(i.fecha)).fold(0.0, (sum, i) => sum + i.precio) + 
                            cuentasCobrar.where((c) => _esMesSeleccionado(c.fechaEmision)).fold(0.0, (sum, c) => sum + c.montoPagado);
                            
      final totalSalidas = compras.where((c) => c.metodoPago != 'Crédito' && _esMesSeleccionado(c.fecha)).fold(0.0, (sum, c) => sum + (c.precio * c.cantidad)) + 
                           salidas.where((s) => _esMesSeleccionado(s.fecha)).fold(0.0, (sum, s) => sum + s.precio) + 
                           cuentasPagar.where((c) => _esMesSeleccionado(c.fechaEmision)).fold(0.0, (sum, c) => sum + c.montoPagado);

      final saldoEnCaja = totalEntradas - totalSalidas;
      final dineroEnLaCalle = cuentasCobrar.fold(0.0, (sum, c) => sum + c.saldoPendiente);
      final deudaAProveedores = cuentasPagar.fold(0.0, (sum, c) => sum + c.saldoPendiente);

      await PdfService.generarYMostrarReporteMensual(
        fecha: DateTime(_selectedYear, _selectedMonth),
        saldoEnCaja: saldoEnCaja,
        dineroEnLaCalle: dineroEnLaCalle,
        deudaAProveedores: deudaAProveedores,
        baseVentas: baseVentas,
        baseComprasLocal: baseComprasLocal,
        ivaVentasTotal: ivaVentasTotal,
        ivaComprasLocal: ivaComprasLocal,
        ivaImportacionesMes: ivaImportacionesMes,
        ivaComprasTotal: ivaComprasTotal,
        saldoIvaAnterior: configImp.saldoIvaAnterior,
        saldoIvaFinal: saldoIva,
        itCalculado: itCalculadoOriginal,
        iueCompensar: configImp.saldoIuePorCompensar,
        itPorPagarFinal: itPorPagarReal,
        nuevoIueRestante: iueSobranteParaElFuturo,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al generar Reporte: $e'), backgroundColor: Colors.red));
    }
  }

  void _generarLibroMovimientos() async {
    try {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generando Libro de Movimientos...'), duration: Duration(seconds: 1)));

      final ventas = context.read<VentasService>().ventas.where((v) => _esMesSeleccionado(v.fecha)).toList();
      final compras = context.read<ComprasService>().compras.where((c) => _esMesSeleccionado(c.fecha)).toList();
      final ingresos = context.read<IngresosService>().ingresos.where((i) => _esMesSeleccionado(i.fecha)).toList();
      final salidas = context.read<SalidasService>().salidas.where((s) => _esMesSeleccionado(s.fecha)).toList();
      final gastos = context.read<GastosService>().gastos.where((g) => _esMesSeleccionado(g.fecha)).toList();

      await PdfService.generarLibroMovimientos(
        fecha: DateTime(_selectedYear, _selectedMonth),
        ventas: ventas,
        compras: compras,
        ingresos: ingresos,
        salidas: salidas,
        gastos: gastos,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al generar Libro de Movimientos: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Centro de Reportes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Seleccionar Periodo', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white),
                        value: _selectedMonth,
                        items: List.generate(12, (index) => DropdownMenuItem(value: index + 1, child: Text(_meses[index]))),
                        onChanged: (val) => setState(() => _selectedMonth = val!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white),
                        value: _selectedYear,
                        items: List.generate(10, (index) => DropdownMenuItem(value: 2024 + index, child: Text('${2024 + index}'))),
                        onChanged: (val) => setState(() => _selectedYear = val!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            const Text('Reportes Disponibles', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 16),

            _buildReportCard(
              title: 'Reporte Financiero e Impositivo',
              description: 'Liquidez de caja, compensación de IVA (Débito/Crédito) y compensación de IT vs IUE.',
              icon: Icons.request_quote_rounded,
              color: Colors.tealAccent,
              onTap: _generarReporteImpositivo,
            ),
            const SizedBox(height: 16),

            _buildReportCard(
              title: 'Libro de Movimientos General',
              description: 'Detalle línea por línea de todas las ventas, compras, ingresos y gastos del mes seleccionado.',
              icon: Icons.list_alt_rounded,
              color: Colors.blueAccent,
              onTap: _generarLibroMovimientos,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({required String title, required String description, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withAlpha(50))),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle), child: Icon(icon, color: color, size: 32)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
}