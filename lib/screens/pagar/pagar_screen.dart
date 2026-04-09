import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ams_control_contable/core/constants/app_colors.dart';
import 'package:ams_control_contable/core/constants/app_strings.dart';
import 'package:ams_control_contable/models/cuenta_cobrar.dart'; 
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
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // SOLO 2 PESTAÑAS AHORA
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CuentasPagarService>().fetchCuentas();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatearMonto(double monto, String moneda) {
    if (moneda == 'USD') {
      return NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2).format(monto);
    }
    return NumberFormat.currency(locale: 'es_BO', symbol: 'Bs.', decimalDigits: 2).format(monto);
  }

  void _mostrarDialogoPago(CuentaPagar cuenta) {
    final _montoCtrl = TextEditingController();
    final _tcCtrl = TextEditingController(text: '6.96'); // Solo se usa si es USD
    final _formKey = GlobalKey<FormState>();
    String _metodoPago = 'Transferencia';

    final esVariableNuevo = cuenta.montoTotal == 0;
    final esUsd = cuenta.moneda == 'USD';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(esVariableNuevo ? 'Definir Monto - ${cuenta.proveedor}' : 'Abonar a ${cuenta.proveedor}'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!esVariableNuevo) ...[
                    Text('Deuda total: ${_formatearMonto(cuenta.montoTotal, cuenta.moneda)}'),
                    Text('Saldo pendiente: ${_formatearMonto(cuenta.saldoPendiente, cuenta.moneda)}', style: TextStyle(fontWeight: FontWeight.bold, color: esUsd ? Colors.blue : Colors.black)),
                    const SizedBox(height: 16),
                  ],
                  if (esVariableNuevo) ...[
                    const Text('Este es un Gasto Variable. Ingresa el monto total de la factura de este mes para registrarlo.', style: TextStyle(color: Colors.orange, fontSize: 13)),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _montoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: esVariableNuevo ? 'Monto Total Factura' : 'Monto a abonar',
                      suffixText: cuenta.moneda,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      final val = double.tryParse(v.replaceAll(',', '.'));
                      if (val == null || val <= 0) return 'Monto inválido';
                      // Le damos un centavo de tolerancia por errores de coma flotante
                      if (!esVariableNuevo && val > (cuenta.saldoPendiente + 0.01)) return 'No puedes pagar más del saldo';
                      return null;
                    },
                  ),
                  
                  if (esUsd) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tcCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Tipo de Cambio (Para la caja Bs)'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido para USD';
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _metodoPago,
                    decoration: const InputDecoration(labelText: 'Método de Pago (Caja)'),
                    items: ['Transferencia', 'Efectivo', 'Cheque'].map((String m) {
                      return DropdownMenuItem(value: m, child: Text(m));
                    }).toList(),
                    onChanged: (v) => setStateDialog(() => _metodoPago = v!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final abono = double.parse(_montoCtrl.text.replaceAll(',', '.'));
                    final tc = esUsd ? double.parse(_tcCtrl.text.replaceAll(',', '.')) : 1.0;
                    
                    Navigator.pop(ctx); // Cerramos diálogo

                    if (esVariableNuevo) {
                      // Es un gasto variable (Agua, Luz), le actualizamos el monto
                      final cuentaActualizada = CuentaPagar(id: cuenta.id, proveedor: cuenta.proveedor, montoTotal: abono, estado: EstadoCuenta.pendiente, fechaEmision: cuenta.fechaEmision, fechaVencimiento: cuenta.fechaVencimiento, notas: cuenta.notas, moneda: cuenta.moneda);
                      await context.read<CuentasPagarService>().updateCuenta(cuentaActualizada);
                    } else {
                      // Abonamos a la deuda normal (Envía la info al servicio)
                      final ok = await context.read<CuentasPagarService>().registrarPago(cuenta.id!, abono, _metodoPago, tcCaja: tc);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Pago registrado correctamente.' : 'Error al procesar el pago.'), backgroundColor: ok ? Colors.green : Colors.red));
                      }
                    }
                  }
                },
                child: const Text('Guardar Pago'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _mostrarDialogoEliminar(CuentaPagar cuenta) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Deuda', style: TextStyle(color: Colors.red)),
        content: const Text('¿Estás seguro de eliminar este registro?\nLos abonos realizados a esta deuda no se eliminarán de la caja (debes anularlos manualmente).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              context.read<CuentasPagarService>().deleteCuenta(cuenta.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar Definitivamente'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.cuentasPorPagar),
        backgroundColor: AppColors.pagarColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: 'Pendientes'), Tab(text: 'Historial Pagadas')],
        ),
      ),
      drawer: const AppDrawer(),
      body: Consumer<CuentasPagarService>(
        builder: (context, service, _) {
          if (service.isLoading) return const Center(child: CircularProgressIndicator());

          final pendientes = service.cuentas.where((c) => c.estado == EstadoCuenta.pendiente || c.estado == EstadoCuenta.parcial).toList();
          final pagados = service.cuentas.where((c) => c.estado == EstadoCuenta.pagado).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildListaCuentas(pendientes),
              _buildListaCuentas(pagados),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListaCuentas(List<CuentaPagar> lista) {
    if (lista.isEmpty) {
      return const EmptyState(icon: Icons.check_circle_outline, message: 'No hay deudas en esta categoría.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final cuenta = lista[index];
        final esVariable = cuenta.montoTotal == 0 && cuenta.estado == EstadoCuenta.pendiente;
        final estaPagado = cuenta.estado == EstadoCuenta.pagado;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(cuenta.proveedor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: _getColorPorEstado(cuenta.estado).withAlpha(30), borderRadius: BorderRadius.circular(12), border: Border.all(color: _getColorPorEstado(cuenta.estado))),
                      child: Text(cuenta.estadoLabel, style: TextStyle(color: _getColorPorEstado(cuenta.estado), fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (cuenta.notas != null && cuenta.notas!.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(cuenta.notas!, style: const TextStyle(color: Colors.blueGrey, fontSize: 13, fontStyle: FontStyle.italic))),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total: ${esVariable ? 'Por definir' : _formatearMonto(cuenta.montoTotal, cuenta.moneda)}', style: const TextStyle(color: Colors.black87)),
                        if (!esVariable && !estaPagado)
                          Text('Pagado: ${_formatearMonto(cuenta.montoPagado, cuenta.moneda)}', style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!estaPagado && !esVariable)
                          Text('Saldo: ${_formatearMonto(cuenta.saldoPendiente, cuenta.moneda)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        Text('Emitida: ${_dateFormat.format(cuenta.fechaEmision)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _mostrarDialogoEliminar(cuenta)),
                    if (!estaPagado)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.pagarColor, foregroundColor: Colors.white),
                        onPressed: () => _mostrarDialogoPago(cuenta),
                        icon: const Icon(Icons.payment, size: 18),
                        label: Text(esVariable ? 'Definir Factura' : 'Abonar / Pagar'),
                      ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getColorPorEstado(EstadoCuenta estado) {
    switch (estado) {
      case EstadoCuenta.pendiente: return Colors.orange;
      case EstadoCuenta.parcial: return Colors.blue;
      case EstadoCuenta.pagado: return Colors.green;
      case EstadoCuenta.vencido: return Colors.red;
    }
  }
}