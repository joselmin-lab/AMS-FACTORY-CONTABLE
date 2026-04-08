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

class _PagarScreenState extends State<PagarScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'es_BO', symbol: 'Bs.', decimalDigits: 2);
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CuentasPagarService>().fetchCuentas();
    });
  }

  void _mostrarDialogoPago(CuentaPagar cuenta) {
    final _montoCtrl = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    String _metodoPago = 'Transferencia'; // Valor por defecto

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Abonar a ${cuenta.proveedor}'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Deuda total: ${_currencyFormat.format(cuenta.montoTotal)}'),
                  Text('Saldo pendiente: ${_currencyFormat.format(cuenta.saldoPendiente)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _montoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Monto a pagar (Bs.)'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      final val = double.tryParse(v);
                      if (val == null || val <= 0) return 'Monto inválido';
                      if (val > cuenta.saldoPendiente) return 'No puedes pagar más del saldo';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _metodoPago,
                    decoration: const InputDecoration(labelText: 'Método de Pago (Egreso)'),
                    items: ['Efectivo', 'QR', 'Transferencia', 'Tarjeta']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
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
                    final monto = double.parse(_montoCtrl.text);
                    Navigator.pop(ctx);
                    
                    final ok = await context.read<CuentasPagarService>().registrarPago(cuenta.id!, monto, _metodoPago);
                    
                    if (ok && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abono registrado. Dinero restado de la caja.'), backgroundColor: AppColors.success));
                    }
                  }
                },
                child: const Text('Registrar Abono'),
              ),
            ],
          );
        }
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
      ),
      drawer: const AppDrawer(),
      body: Consumer<CuentasPagarService>(
        builder: (context, service, _) {
          if (service.isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.pagarColor));
          
          if (service.error != null) return Center(child: Text(service.error!, style: const TextStyle(color: AppColors.error)));

          if (service.cuentas.isEmpty) {
            return const EmptyState(
              icon: Icons.arrow_circle_up_outlined,
              message: 'No hay cuentas por pagar.\nLas compras "a Crédito" aparecerán aquí de forma automática.',
              actionLabel: '', // Quitamos el botón de la vista vacía
            );
          }

          final pendientes = service.cuentas.where((c) => c.estado != EstadoCuenta.pagado).toList();

          return Column(
            children: [
              _buildSummaryBanner(service, pendientes.length),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.pagarColor,
                  onRefresh: () => service.fetchCuentas(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: service.cuentas.length,
                    itemBuilder: (context, index) {
                      final cuenta = service.cuentas[index];
                      final estadoColor = _estadoColor(cuenta.estado);

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
                                    child: Text(cuenta.estadoLabel, style: TextStyle(color: estadoColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
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
                                  if (cuenta.estado != EstadoCuenta.pagado)
                                    TextButton.icon(
                                      onPressed: () => _mostrarDialogoPago(cuenta),
                                      icon: const Icon(Icons.payments_outlined, size: 18),
                                      label: const Text('Abonar Deuda'),
                                      style: TextButton.styleFrom(foregroundColor: AppColors.pagarColor, padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                                    ),
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
        },
      ),
      // ELIMINADO EL FLOATING ACTION BUTTON
    );
  }

  Widget _buildSummaryBanner(CuentasPagarService service, int pendientesCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.pagarColor.withAlpha(26),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dinero a pagar', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(_currencyFormat.format(service.totalPendiente), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.pagarColor)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Proveedores', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text('$pendientesCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}