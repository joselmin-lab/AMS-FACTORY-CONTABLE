import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ams_control_contable/core/constants/app_colors.dart';
import 'package:ams_control_contable/core/router/app_router.dart';
import 'package:ams_control_contable/services/salidas_service.dart';
import 'package:ams_control_contable/widgets/app_drawer.dart';
import 'package:ams_control_contable/widgets/empty_state.dart';
import 'package:ams_control_contable/widgets/movimiento_card.dart';
import 'package:ams_control_contable/widgets/dialogs.dart';

class SalidasScreen extends StatefulWidget {
  const SalidasScreen({super.key});

  @override
  State<SalidasScreen> createState() => _SalidasScreenState();
}

class _SalidasScreenState extends State<SalidasScreen> {
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final _currencyFormat = NumberFormat.currency(locale: 'es_BO', symbol: 'Bs.', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalidasService>().fetchSalidas();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Usaremos un color anaranjado/rojizo para las salidas
    const colorModulo = Colors.deepOrange;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salidas No Recurrentes', style: TextStyle(color: Colors.white)),
        backgroundColor: colorModulo,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<SalidasService>().fetchSalidas(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Consumer<SalidasService>(
        builder: (context, service, _) {
          if (service.isLoading) return const Center(child: CircularProgressIndicator(color: colorModulo));
          
          if (service.error != null) {
            return Center(child: Text(service.error!, style: const TextStyle(color: AppColors.error)));
          }

          if (service.salidas.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'No hay salidas registradas.\nCrea tu primera salida.',
              onAction: () => Navigator.pushNamed(context, AppRoutes.crearSalida),
              actionLabel: 'Nueva Salida',
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: colorModulo.withAlpha(26),
                child: Row(
                  children: [
                    const Icon(Icons.summarize_rounded, color: colorModulo, size: 20),
                    const SizedBox(width: 8),
                    const Text('Total salidas: ', style: TextStyle(color: colorModulo, fontWeight: FontWeight.w500)),
                    Text(
                      _currencyFormat.format(service.totalSalidas),
                      style: const TextStyle(color: colorModulo, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: colorModulo,
                  onRefresh: () => service.fetchSalidas(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: service.salidas.length,
                    itemBuilder: (context, index) {
                      final salida = service.salidas[index];
                      return MovimientoCard(
                        title: salida.detalle,
                        subtitle: '${salida.descripcion ?? 'Sin descripción'} · ${salida.metodoPago}',
                        amount: _currencyFormat.format(salida.precio),
                        date: _dateFormat.format(salida.fecha),
                        color: colorModulo,
                        badge: salida.facturado ? 'Facturado' : null,
                        badgeColor: AppColors.success,
                        onDelete: () async {
                          final confirm = await showDeleteConfirmDialog(context);
                          if (confirm && context.mounted) {
                            final ok = await service.deleteSalida(salida.id!);
                            if (context.mounted) {
                              if (ok) showSuccessSnackbar(context, 'Salida eliminada correctamente.');
                              else showErrorSnackbar(context, service.error ?? 'Error');
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.crearSalida),
        backgroundColor: colorModulo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva Salida'),
      ),
    );
  }
}