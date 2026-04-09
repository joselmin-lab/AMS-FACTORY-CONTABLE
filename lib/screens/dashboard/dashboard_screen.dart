import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ams_control_contable/core/constants/app_colors.dart';
import 'package:ams_control_contable/core/router/app_router.dart';
import 'package:ams_control_contable/widgets/app_drawer.dart';
import 'package:ams_control_contable/models/cuenta_pagar.dart';

import 'package:ams_control_contable/services/ventas_service.dart';
import 'package:ams_control_contable/services/compras_service.dart';
import 'package:ams_control_contable/services/ingresos_service.dart';
import 'package:ams_control_contable/services/salidas_service.dart';
import 'package:ams_control_contable/services/cuentas_cobrar_service.dart';
import 'package:ams_control_contable/services/cuentas_pagar_service.dart';
import 'package:ams_control_contable/services/impositivo_service.dart';
import 'package:ams_control_contable/services/gastos_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'es_BO', symbol: 'Bs.', decimalDigits: 2);
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarTodosLosDatos());
  }

  Future<void> _cargarTodosLosDatos() async {
    setState(() => _isRefreshing = true);
    await Future.wait([
      context.read<VentasService>().fetchVentas(),
      context.read<ComprasService>().fetchCompras(),
      context.read<IngresosService>().fetchIngresos(),
      context.read<SalidasService>().fetchSalidas(),
      context.read<CuentasCobrarService>().fetchCuentas(),
      context.read<CuentasPagarService>().fetchCuentas(),
      context.read<ImpositivoService>().fetchConfig(),
      context.read<GastosService>().fetchGastos(), // <-- Carga de Gastos
    ]);
    if (mounted) setState(() => _isRefreshing = false);
  }

  Future<void> _generarDeudasImpositivas(double ivaPagar, double itPagar) async {
    final mesStr = DateFormat('MMMM yyyy', 'es_ES').format(DateTime.now()).toUpperCase();
    bool exito = true;

    // Generar deuda IT
    if (itPagar > 0) {
      final cuentaIT = CuentaPagar(
        proveedor: 'Impuestos Nacionales (IT)',
        montoTotal: itPagar,
        fechaEmision: DateTime.now(),
        notas: 'Generado automáticamente - $mesStr',
      );
      final res = await context.read<CuentasPagarService>().createCuenta(cuentaIT);
      if (!res) exito = false;
    }

    // Generar deuda IVA (solo si hay saldo en contra)
    if (ivaPagar > 0) {
      final cuentaIVA = CuentaPagar(
        proveedor: 'Impuestos Nacionales (IVA)',
        montoTotal: ivaPagar,
        fechaEmision: DateTime.now(),
        notas: 'Generado automáticamente - $mesStr',
      );
      final res = await context.read<CuentasPagarService>().createCuenta(cuentaIVA);
      if (!res) exito = false;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(exito ? 'Deudas fiscales enviadas a Cuentas por Pagar.' : 'Hubo un error al generar deudas.'),
          backgroundColor: exito ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- FILTROS DE MES ACTUAL Y BLOQUEO DE BOTÓN ---
    final now = DateTime.now();
    bool esEsteMes(DateTime d) => d.year == now.year && d.month == now.month;
    
    // Lógica para saber si hoy es el último día del mes
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    final esUltimoDia = now.day == lastDayOfMonth;

    // --- DATOS GLOBALES PARA CAJA ---
    final ventas = context.watch<VentasService>().ventas;
    final ingresos = context.watch<IngresosService>().ingresos;
    final cuentasCobrar = context.watch<CuentasCobrarService>().cuentas;
    
    final totalVentasContado = ventas.where((v) => v.metodoPago != 'Crédito').fold(0.0, (sum, v) => sum + (v.precio * v.cantidad));
    final totalIngresosExtra = ingresos.fold(0.0, (sum, i) => sum + i.precio);
    final totalCobrosRealizados = cuentasCobrar.fold(0.0, (sum, c) => sum + c.montoPagado);
    final totalEntradas = totalVentasContado + totalIngresosExtra + totalCobrosRealizados;

    final compras = context.watch<ComprasService>().compras;
    final salidas = context.watch<SalidasService>().salidas;
    final cuentasPagar = context.watch<CuentasPagarService>().cuentas;

    final totalComprasContado = compras.where((c) => c.metodoPago != 'Crédito').fold(0.0, (sum, c) => sum + (c.precio * c.cantidad));
    final totalSalidasExtra = salidas.fold(0.0, (sum, s) => sum + s.precio);
    final totalPagosRealizados = cuentasPagar.fold(0.0, (sum, c) => sum + c.montoPagado);
    final totalSalidasCaja = totalComprasContado + totalSalidasExtra + totalPagosRealizados;

    final saldoEnCaja = totalEntradas - totalSalidasCaja;
    final dineroEnLaCalle = cuentasCobrar.fold(0.0, (sum, c) => sum + c.saldoPendiente);
    final deudaAProveedores = cuentasPagar.fold(0.0, (sum, c) => sum + c.saldoPendiente);

    // --- MOTOR IMPOSITIVO (SOLO ESTE MES) ---
    final configImp = context.watch<ImpositivoService>().config;
    final gastos = context.watch<GastosService>().gastos;
    
    // Sumatorias Facturadas del Mes (Débito)
    final ventasFacMes = ventas.where((v) => v.facturado && esEsteMes(v.fecha)).fold(0.0, (sum, v) => sum + (v.precio * v.cantidad));
    final ingresosFacMes = ingresos.where((i) => i.facturado && esEsteMes(i.fecha)).fold(0.0, (sum, i) => sum + i.precio);
    final baseVentas = ventasFacMes + ingresosFacMes;

    // Sumatorias Facturadas del Mes (Crédito)
    final comprasFacMes = compras.where((c) => c.facturado && esEsteMes(c.fecha)).fold(0.0, (sum, c) => sum + (c.precio * c.cantidad));
    final salidasFacMes = salidas.where((s) => s.facturado && esEsteMes(s.fecha)).fold(0.0, (sum, s) => sum + s.precio);
    final gastosFacMes = gastos.where((g) => g.facturado && esEsteMes(g.fecha)).fold(0.0, (sum, g) => sum + g.monto);
    final baseCompras = comprasFacMes + salidasFacMes + gastosFacMes;

    // Cálculos
    final ivaCompras = baseCompras * (configImp.ivaCompras / 100); // Crédito
    final ivaVentas = baseVentas * (configImp.ivaVentas / 100);    // Débito
    final saldoIva = ivaCompras - ivaVentas; // Positivo = A favor, Negativo = En contra
    
    final itVentas = baseVentas * (configImp.itVentas / 100);

    // --- DISEÑO DARK MODE ---
    const bgColor = Color(0xFF0F172A);
    const cardColor = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Dashboard Financiero', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isRefreshing) 
            const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.tealAccent, strokeWidth: 2))))
          else
            IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _cargarTodosLosDatos),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        color: Colors.tealAccent,
        backgroundColor: cardColor,
        onRefresh: _cargarTodosLosDatos,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- SALDO EN CAJA ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.cyanAccent.withAlpha(20), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Saldo en Caja Físico', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Icon(Icons.account_balance_wallet_rounded, color: Colors.cyanAccent.withAlpha(200)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_currencyFormat.format(saldoEnCaja), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: -1)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Entradas', style: const TextStyle(color: Colors.white54, fontSize: 12)), Text(_currencyFormat.format(totalEntradas), style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold))])),
                      Container(width: 1, height: 30, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 16)),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Salidas', style: const TextStyle(color: Colors.white54, fontSize: 12)), Text(_currencyFormat.format(totalSalidasCaja), style: const TextStyle(color: Colors.pinkAccent, fontSize: 16, fontWeight: FontWeight.bold))])),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(child: _DashboardCard(title: 'Por Cobrar', amount: dineroEnLaCalle, icon: Icons.arrow_circle_down_rounded, color: Colors.orangeAccent)),
                const SizedBox(width: 12),
                Expanded(child: _DashboardCard(title: 'Por Pagar', amount: deudaAProveedores, icon: Icons.arrow_circle_up_rounded, color: Colors.redAccent)),
              ],
            ),
            const SizedBox(height: 32),

            // --- NUEVA TARJETA: ESTADO IMPOSITIVO DEL MES ---
            const Text('Estado Impositivo (Mes Actual)', style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.deepPurpleAccent.withAlpha(50))),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Base Imponible Facturada', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Icon(Icons.request_quote_rounded, color: Colors.deepPurpleAccent.withAlpha(200)),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  _TaxRow('Ventas e Ingresos:', _currencyFormat.format(baseVentas), Colors.white70),
                  _TaxRow('Compras y Gastos:', _currencyFormat.format(baseCompras), Colors.white70),
                  const SizedBox(height: 16),
                  
                  const Align(alignment: Alignment.centerLeft, child: Text('Cálculo de Impuestos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                  const Divider(color: Colors.white10, height: 24),
                  _TaxRow('Crédito Fiscal (IVA Compras +)', _currencyFormat.format(ivaCompras), Colors.greenAccent),
                  _TaxRow('Débito Fiscal (IVA Ventas -)', _currencyFormat.format(ivaVentas), Colors.redAccent),
                  
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: saldoIva >= 0 ? Colors.green.withAlpha(20) : Colors.red.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(saldoIva >= 0 ? 'SALDO IVA A FAVOR' : 'IVA POR PAGAR', style: TextStyle(fontWeight: FontWeight.bold, color: saldoIva >= 0 ? Colors.greenAccent : Colors.redAccent)),
                        Text(_currencyFormat.format(saldoIva.abs()), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: saldoIva >= 0 ? Colors.greenAccent : Colors.redAccent)),
                      ],
                    ),
                  ),

                  _TaxRow('IT Ventas (Por Pagar -)', _currencyFormat.format(itVentas), Colors.orangeAccent),
                  
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: esUltimoDia ? Colors.deepPurpleAccent : Colors.grey.shade800, 
                        foregroundColor: Colors.white, 
                        padding: const EdgeInsets.symmetric(vertical: 12), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      onPressed: esUltimoDia ? () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: cardColor,
                            title: const Text('Cerrar Mes Fiscal', style: TextStyle(color: Colors.white)),
                            content: const Text('¿Generar Cuentas por Pagar para el IT y el IVA de este mes?', style: TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _generarDeudasImpositivas(saldoIva < 0 ? saldoIva.abs() : 0.0, itVentas);
                                },
                                child: const Text('Generar Deudas', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      } : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Solo puedes liquidar impuestos el último día del mes.'), backgroundColor: Colors.orange),
                        );
                      },
                      icon: Icon(esUltimoDia ? Icons.account_balance_rounded : Icons.lock_outline_rounded),
                      label: Text(esUltimoDia ? 'Liquidar Impuestos' : 'Liquidación Bloqueada (Habilitado el día $lastDayOfMonth)', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text('Navegación', style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            _buildModuleGrid(context, cardColor),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleGrid(BuildContext context, Color cardColor) {
    final modules = [
      _ModuleItem('Compras', Icons.shopping_bag_outlined, Colors.blueAccent, AppRoutes.compras),
      _ModuleItem('Ventas', Icons.sell_outlined, Colors.greenAccent, AppRoutes.ventas),
      _ModuleItem('Cobrar', Icons.account_balance_wallet_outlined, Colors.orangeAccent, AppRoutes.cobrar),
      _ModuleItem('Pagar', Icons.credit_card_off_outlined, Colors.redAccent, AppRoutes.pagar),
      _ModuleItem('Impuestos', Icons.request_quote_outlined, Colors.deepPurpleAccent, AppRoutes.impositivo),
      _ModuleItem('Gastos', Icons.money_off_outlined, Colors.pinkAccent, AppRoutes.gastos),
      _ModuleItem('Importar', Icons.flight_land_rounded, Colors.cyanAccent, AppRoutes.importaciones),
      _ModuleItem('Personal', Icons.people_outline_rounded, Colors.grey, AppRoutes.usuarios),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.8, mainAxisSpacing: 12, crossAxisSpacing: 12),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final mod = modules[index];
        return InkWell(
          onTap: () => Navigator.pushNamed(context, mod.route),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(mod.icon, color: mod.color, size: 28),
                const SizedBox(height: 8),
                Text(mod.label, style: const TextStyle(color: Colors.white70, fontSize: 11), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- WIDGETS AUXILIARES ---

class _TaxRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TaxRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _DashboardCard({required this.title, required this.amount, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_BO', symbol: 'Bs.', decimalDigits: 2).format(amount);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withAlpha(30))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 2)),
            ],
          ),
          const SizedBox(height: 12),
          Text(currency, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, shadows: [BoxShadow(color: color.withAlpha(100), blurRadius: 8)])),
        ],
      ),
    );
  }
}

class _ModuleItem {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  _ModuleItem(this.label, this.icon, this.color, this.route);
}