import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ams_control_contable/core/constants/app_colors.dart';
import 'package:ams_control_contable/core/constants/app_strings.dart';
import 'package:ams_control_contable/models/cuenta_cobrar.dart';
import 'package:ams_control_contable/services/cuentas_cobrar_service.dart';
import 'package:ams_control_contable/widgets/app_drawer.dart';
import 'package:ams_control_contable/widgets/empty_state.dart';

class CobrarScreen extends StatefulWidget {
  const CobrarScreen({super.key});

  @override
  State<CobrarScreen> createState() => _CobrarScreenState();
}

class _CobrarScreenState extends State<CobrarScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'es_BO', symbol: 'Bs.', decimalDigits: 2);
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CuentasCobrarService>().fetchCuentas();
    });
  }

    void _mostrarDialogoPago(CuentaCobrar cuenta) {
    final _montoCtrl = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    String _metodoPago = 'Efectivo'; // Valor por defecto

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder( // StatefulBuilder para actualizar el desplegable dentro del diálogo
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Registrar Pago - ${cuenta.cliente}'),
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
                    decoration: const InputDecoration(labelText: 'Monto a abonar (Bs.)'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      final val = double.tryParse(v);
                      if (val == null || val <= 0) return 'Monto inválido';
                      if (val > cuenta.saldoPendiente) return 'No puede pagar más del saldo';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _metodoPago,
                    decoration: const InputDecoration(labelText: 'Método de Pago'),
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
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.cobrarColor, foregroundColor: Colors.white),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final monto = double.parse(_montoCtrl.text);
                    Navigator.pop(ctx);
                    
                    // Ahora mandamos el método de pago también
                    final ok = await context.read<CuentasCobrarService>().registrarPago(cuenta.id!, monto, _metodoPago);
                    
                    if (ok && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pago registrado correctamente. Dinero ingresado a caja.'), backgroundColor: AppColors.success));
                    }
                  }
                },
                child: const Text('Registrar Pago'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.cuentasPorCobrar, style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.cobrarColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => context.read<CuentasCobrarService>().fetchCuentas()),
        ],
      ),
      drawer: const AppDrawer(),
      body: Consumer<CuentasCobrarService>(
        builder: (context, service, _) {
          if (service.isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.cobrarColor));
          
          if (service.cuentas.isEmpty) {
            return const EmptyState(
              icon: Icons.arrow_circle_down_outlined,
              message: 'No hay cuentas por cobrar.\nLas ventas "a Crédito" aparecerán aquí.',
              actionLabel: '',
            );
          }

          return Column(
            children: [
              _buildSummaryBanner(service),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: service.cuentas.length,
                  itemBuilder: (context, index) {
                    final cuenta = service.cuentas[index];
                    return _buildCuentaCard(cuenta);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryBanner(CuentasCobrarService service) {
    final pendientes = service.cuentas.where((c) => c.estado != EstadoCuenta.pagado).length;
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.cobrarColor.withAlpha(26),
      child: Row(
        children: [
          Expanded(child: _buildSummaryItem('Pendiente Total', _currencyFormat.format(service.totalPendiente), AppColors.cobrarColor)),
          const SizedBox(width: 16),
          Expanded(child: _buildSummaryItem('Cuentas Activas', '$pendientes', AppColors.warning)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildCuentaCard(CuentaCobrar cuenta) {
    final Color estadoColor = _estadoColor(cuenta.estado);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(cuenta.cliente, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: estadoColor.withAlpha(26), borderRadius: BorderRadius.circular(12), border: Border.all(color: estadoColor)),
                  child: Text(cuenta.estadoLabel, style: TextStyle(fontSize: 12, color: estadoColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                    const Text('Saldo Pendiente', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text(_currencyFormat.format(cuenta.saldoPendiente), style: TextStyle(fontWeight: FontWeight.bold, color: cuenta.saldoPendiente > 0 ? AppColors.error : AppColors.success)),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Emitido: ${_dateFormat.format(cuenta.fechaEmision)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                if (cuenta.estado != EstadoCuenta.pagado)
                  TextButton.icon(
                    onPressed: () => _mostrarDialogoPago(cuenta),
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text('Registrar Pago'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.cobrarColor, padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _estadoColor(EstadoCuenta estado) {
    switch (estado) {
      case EstadoCuenta.pendiente: return AppColors.error;
      case EstadoCuenta.parcial: return AppColors.warning;
      case EstadoCuenta.pagado: return AppColors.success;
      case EstadoCuenta.vencido: return AppColors.error;
    }
  }
}