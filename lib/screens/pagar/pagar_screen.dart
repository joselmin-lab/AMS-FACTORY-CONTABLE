import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ams_control_contable/core/constants/app_colors.dart';
import 'package:ams_control_contable/core/constants/app_strings.dart';
import 'package:ams_control_contable/models/cuenta_cobrar.dart'; // Usamos EstadoCuenta
import 'package:ams_control_contable/models/cuenta_pagar.dart';
import 'package:ams_control_contable/services/cuentas_pagar_service.dart';
import 'package:ams_control_contable/widgets/app_drawer.dart';
import 'package:ams_control_contable/widgets/empty_state.dart';

class PagarScreen extends StatefulWidget {
  const PagarScreen({super.key});

  @override
  State<PagarScreen> createState() => _PagarScreenState();
}

class _PagarScreenState extends State<PagarScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _currencyFormat = NumberFormat.currency(locale: 'es_BO', symbol: 'Bs.', decimalDigits: 2);
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CuentasPagarService>().fetchCuentas();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _mostrarDialogoPago(CuentaPagar cuenta) {
    final _montoCtrl = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    String _metodoPago = 'Transferencia';

    final esVariableNuevo = cuenta.montoTotal == 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(esVariableNuevo ? 'Definir Monto - ${cuenta.proveedor}' : 'Abonar a ${cuenta.proveedor}'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!esVariableNuevo) ...[
                    Text('Deuda total: ${_currencyFormat.format(cuenta.montoTotal)}'),
                    Text('Saldo pendiente: ${_currencyFormat.format(cuenta.saldoPendiente)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                  ],
                  if (esVariableNuevo) ...[
                    const Text('Este es un Gasto Variable. Ingresa el monto total de la factura de este mes para registrarlo.', style: TextStyle(color: Colors.orange, fontSize: 13)),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _montoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: esVariableNuevo ? 'Monto Total de la Factura (Bs.)' : 'Monto a pagar (Bs.)'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      final val = double.tryParse(v);
                      if (val == null || val <= 0) return 'Monto inválido';
                      if (!esVariableNuevo && val > cuenta.saldoPendiente) return 'No puedes pagar más del saldo';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _metodoPago,
                    decoration: const InputDecoration(labelText: 'Método de Pago (Egreso)'),
                    items: ['Efectivo', 'QR', 'Transferencia', 'Tarjeta'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) => setStateDialog(() => _metodoPago = val!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.pagarColor, foregroundColor: Colors.white),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final montoIngresado = double.parse(_montoCtrl.text);
                    Navigator.pop(ctx);
                    
                    if (esVariableNuevo) {
                      final cuentaActualizada = CuentaPagar(
                        id: cuenta.id,
                        proveedor: cuenta.proveedor,
                        compraId: cuenta.compraId,
                        gastoId: cuenta.gastoId,
                        montoTotal: montoIngresado,
                        montoPagado: cuenta.montoPagado,
                        estado: cuenta.estado,
                        fechaEmision: cuenta.fechaEmision,
                        notas: cuenta.notas,
                      );
                      await context.read<CuentasPagarService>().updateCuenta(cuentaActualizada);
                      await context.read<CuentasPagarService>().registrarPago(cuenta.id!, montoIngresado, _metodoPago);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gasto variable definido y pagado.'), backgroundColor: AppColors.success));
                    } else {
                      final ok = await context.read<CuentasPagarService>().registrarPago(cuenta.id!, montoIngresado, _metodoPago);
                      if (ok && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abono registrado. Dinero restado de la caja.'), backgroundColor: AppColors.success));
                    }
                  }
                },
                child: Text(esVariableNuevo ? 'Guardar y Pagar' : 'Registrar Abono'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _mostrarDialogoEditarMonto(CuentaPagar cuenta) {
    final formKey = GlobalKey<FormState>();
    final totalCtrl = TextEditingController(text: cuenta.montoTotal.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Actualizar Deuda', style: TextStyle(fontSize: 18)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(cuenta.proveedor, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Ingrese el monto real del gasto para este mes:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              TextFormField(
                controller: totalCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Monto Total de la Deuda', prefixText: 'Bs. '),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Monto inválido';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final nuevoTotal = double.parse(totalCtrl.text);
                final cuentaActualizada = CuentaPagar(
                  id: cuenta.id,
                  proveedor: cuenta.proveedor,
                  compraId: cuenta.compraId,
                  gastoId: cuenta.gastoId,
                  montoTotal: nuevoTotal,
                  montoPagado: cuenta.montoPagado,
                  estado: cuenta.estado,
                  fechaEmision: cuenta.fechaEmision,
                  notas: cuenta.notas,
                );
                Navigator.pop(context);
                await context.read<CuentasPagarService>().updateCuenta(cuentaActualizada);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.pagarColor, foregroundColor: Colors.white),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Color _estadoColor(EstadoCuenta estado) {
    switch (estado) {
      case EstadoCuenta.pagado: return AppColors.success;
      case EstadoCuenta.parcial: return Colors.orange;
      case EstadoCuenta.vencido: return AppColors.error;
      case EstadoCuenta.pendiente: return AppColors.pagarColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.cuentasPorPagar, style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.pagarColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => context.read<CuentasPagarService>().fetchCuentas()),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Compras', icon: Icon(Icons.shopping_cart_rounded, size: 18)),
            Tab(text: 'Gastos', icon: Icon(Icons.money_off_rounded, size: 18)),
            Tab(text: 'Otros Extras', icon: Icon(Icons.receipt_long_rounded, size: 18)),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: Consumer<CuentasPagarService>(
        builder: (context, service, _) {
          if (service.isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.pagarColor));
          if (service.error != null) return Center(child: Text(service.error!, style: const TextStyle(color: AppColors.error)));

          // FILTROS
          final comprasList = service.cuentas.where((c) => c.compraId != null).toList();
          final gastosList = service.cuentas.where((c) => c.gastoId != null).toList();
          final otrosList = service.cuentas.where((c) => c.compraId == null && c.gastoId == null).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildListaDeudas(comprasList, 'Compras a Crédito', Icons.shopping_cart_outlined),
              _buildListaDeudas(gastosList, 'Gastos y Sueldos', Icons.money_off_outlined),
              _buildListaDeudas(otrosList, 'Otras Deudas', Icons.receipt_long_outlined),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListaDeudas(List<CuentaPagar> lista, String nombreLista, IconData iconEmpty) {
    if (lista.isEmpty) {
      return EmptyState(icon: iconEmpty, message: 'No hay deudas pendientes en $nombreLista.', actionLabel: '');
    }

    final totalPendiente = lista.where((c) => c.estado != EstadoCuenta.pagado).fold(0.0, (sum, c) => sum + c.saldoPendiente);
    final activas = lista.where((c) => c.estado != EstadoCuenta.pagado).length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.pagarColor.withAlpha(26),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Pendiente', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text(_currencyFormat.format(totalPendiente), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.pagarColor)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cuentas Activas', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text('$activas', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.pagarColor,
            onRefresh: () => context.read<CuentasPagarService>().fetchCuentas(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: lista.length,
              itemBuilder: (context, index) {
                final cuenta = lista[index];
                final estadoColor = _estadoColor(cuenta.estado);
                final bool esVariableEnCero = cuenta.montoTotal <= 0;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(cuenta.proveedor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: estadoColor.withAlpha(26), borderRadius: BorderRadius.circular(12)),
                              child: Text(esVariableEnCero ? 'Falta Monto' : cuenta.estadoLabel, style: TextStyle(color: estadoColor, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        if (cuenta.notas != null) ...[
                          const SizedBox(height: 4),
                          Text(cuenta.notas!, style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Deuda', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                Text(_currencyFormat.format(cuenta.montoTotal), style: const TextStyle(fontWeight: FontWeight.w500)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Saldo Restante', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                Text(_currencyFormat.format(cuenta.saldoPendiente), style: TextStyle(fontWeight: FontWeight.bold, color: cuenta.saldoPendiente > 0 ? AppColors.error : AppColors.success)),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Creado: ${_dateFormat.format(cuenta.fechaEmision)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            if (cuenta.estado != EstadoCuenta.pagado) ...[
                              if (esVariableEnCero || cuenta.montoPagado == 0) 
                                IconButton(
                                  icon: const Icon(Icons.edit_note_rounded, color: AppColors.pagarColor),
                                  tooltip: 'Editar Monto Total',
                                  onPressed: () => _mostrarDialogoEditarMonto(cuenta),
                                ),
                              if (!esVariableEnCero)
                                TextButton.icon(
                                  onPressed: () => _mostrarDialogoPago(cuenta),
                                  icon: const Icon(Icons.payments_outlined, size: 18),
                                  label: const Text('Abonar Deuda'),
                                  style: TextButton.styleFrom(foregroundColor: AppColors.pagarColor, padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                                ),
                            ]
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}