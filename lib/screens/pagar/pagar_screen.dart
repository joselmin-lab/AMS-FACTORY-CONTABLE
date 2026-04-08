import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ams_control_contable/core/constants/app_colors.dart';
import 'package:ams_control_contable/core/constants/app_strings.dart';
import 'package:ams_control_contable/models/cuenta_cobrar.dart';
import 'package:ams_control_contable/models/cuenta_pagar.dart';
import 'package:ams_control_contable/widgets/app_drawer.dart';
import 'package:ams_control_contable/widgets/dialogs.dart';
import 'package:ams_control_contable/widgets/empty_state.dart';

class PagarScreen extends StatefulWidget {
  const PagarScreen({super.key});

  @override
  State<PagarScreen> createState() => _PagarScreenState();
}

class _PagarScreenState extends State<PagarScreen> {
  final _currencyFormat =
      NumberFormat.currency(locale: 'es_BO', symbol: 'Bs.', decimalDigits: 2);
  final _dateFormat = DateFormat('dd/MM/yyyy');

  // Placeholder local state (TODO: replace with CuentasPagarService)
  final List<CuentaPagar> _cuentas = [];

  double get _totalPendiente => _cuentas
      .where((c) => c.estado != EstadoCuenta.pagado)
      .fold(0, (s, c) => s + c.saldoPendiente);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.cuentasPorPagar),
        backgroundColor: AppColors.pagarColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() {}),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _cuentas.isEmpty
          ? EmptyState(
              icon: Icons.arrow_circle_up_outlined,
              message:
                  'No hay cuentas por pagar registradas.',
              onAction: _showCrearCuentaDialog,
              actionLabel: 'Agregar cuenta',
            )
          : Column(
              children: [
                _buildSummaryBanner(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _cuentas.length,
                    itemBuilder: (context, index) {
                      final cuenta = _cuentas[index];
                      return _buildCuentaCard(cuenta);
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCrearCuentaDialog,
        backgroundColor: AppColors.pagarColor,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva Cuenta'),
      ),
    );
  }

  Widget _buildSummaryBanner() {
    final pendientes =
        _cuentas.where((c) => c.estado != EstadoCuenta.pagado).length;
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.pagarColor.withAlpha(26),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'Deuda Total',
              _currencyFormat.format(_totalPendiente),
              AppColors.pagarColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryItem(
              'Cuentas Activas',
              '$pendientes',
              AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildCuentaCard(CuentaPagar cuenta) {
    final Color estadoColor = _estadoColor(cuenta.estado);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    cuenta.proveedor,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: estadoColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    cuenta.estadoLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: estadoColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                    const Text('Monto total:',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                    Text(
                      _currencyFormat.format(cuenta.montoTotal),
                      style:
                          const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Saldo pendiente:',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                    Text(
                      _currencyFormat.format(cuenta.saldoPendiente),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.pagarColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Emitido: ${_dateFormat.format(cuenta.fechaEmision)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                if (cuenta.fechaVencimiento != null)
                  Text(
                    'Vence: ${_dateFormat.format(cuenta.fechaVencimiento!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: cuenta.estado == EstadoCuenta.vencido
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                  ),
                Row(
                  children: [
                    InkWell(
                      onTap: () {},
                      child: const Icon(Icons.edit_rounded,
                          size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () async {
                        final confirm =
                            await showDeleteConfirmDialog(context);
                        if (confirm) {
                          setState(() => _cuentas.remove(cuenta));
                        }
                      },
                      child: const Icon(Icons.delete_rounded,
                          size: 18, color: AppColors.error),
                    ),
                  ],
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
      case EstadoCuenta.pendiente:
        return AppColors.warning;
      case EstadoCuenta.parcial:
        return AppColors.accent;
      case EstadoCuenta.pagado:
        return AppColors.success;
      case EstadoCuenta.vencido:
        return AppColors.error;
    }
  }

  void _showCrearCuentaDialog() {
    final proveedorController = TextEditingController();
    final montoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Cuenta por Pagar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: proveedorController,
              decoration: const InputDecoration(
                labelText: AppStrings.proveedor,
                prefixIcon: Icon(Icons.business_rounded),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: montoController,
              decoration: const InputDecoration(
                labelText: AppStrings.total,
                prefixIcon: Icon(Icons.attach_money_rounded),
                prefixText: 'Bs. ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancelar),
          ),
          ElevatedButton(
            onPressed: () {
              if (proveedorController.text.isNotEmpty &&
                  montoController.text.isNotEmpty) {
                setState(() {
                  _cuentas.add(CuentaPagar(
                    proveedor: proveedorController.text,
                    montoTotal:
                        double.tryParse(montoController.text) ?? 0,
                    fechaEmision: DateTime.now(),
                  ));
                });
                Navigator.pop(context);
                showSuccessSnackbar(
                    context, AppStrings.registroGuardado);
              }
            },
            child: const Text(AppStrings.guardar),
          ),
        ],
      ),
    );
  }
}
