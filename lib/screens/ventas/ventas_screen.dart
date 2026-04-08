import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ams_control_contable/core/constants/app_colors.dart';
import 'package:ams_control_contable/core/constants/app_strings.dart';
import 'package:ams_control_contable/core/router/app_router.dart';
import 'package:ams_control_contable/services/ventas_service.dart';
import 'package:ams_control_contable/widgets/app_drawer.dart';
import 'package:ams_control_contable/widgets/empty_state.dart';
import 'package:ams_control_contable/widgets/movimiento_card.dart';
import 'package:ams_control_contable/widgets/dialogs.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _currencyFormat =
      NumberFormat.currency(locale: 'es_BO', symbol: 'Bs.', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VentasService>().fetchVentas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.ventas),
        backgroundColor: AppColors.ventasColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                context.read<VentasService>().fetchVentas(),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Consumer<VentasService>(
        builder: (context, service, _) {
          if (service.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (service.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 48),
                  const SizedBox(height: 12),
                  Text(service.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => service.fetchVentas(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (service.ventas.isEmpty) {
            return EmptyState(
              icon: Icons.point_of_sale_outlined,
              message: 'No hay ventas registradas.\nCrea tu primera venta.',
              onAction: () =>
                  Navigator.pushNamed(context, AppRoutes.crearVenta),
              actionLabel: 'Nueva Venta',
            );
          }

          return Column(
            children: [
              _buildTotalBanner(service.totalVentas),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => service.fetchVentas(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: service.ventas.length,
                    itemBuilder: (context, index) {
                      final venta = service.ventas[index];
                      return MovimientoCard(
                        title: venta.parteNombre ?? 'Venta',
                        subtitle:
                            '${venta.cliente} · ${venta.metodoPago}',
                        amount: _currencyFormat.format(venta.total),
                        date: _dateFormat.format(venta.fecha),
                        color: AppColors.ventasColor,
                        badge: venta.facturado ? 'Facturado' : null,
                        badgeColor: AppColors.success,
                        onEdit: () => Navigator.pushNamed(
                          context,
                          AppRoutes.crearVenta,
                          arguments: {'id': venta.id},
                        ),
                        onDelete: () async {
                          final confirm =
                              await showDeleteConfirmDialog(context);
                          if (confirm && context.mounted) {
                            final ok = await service.deleteVenta(venta.id!);
                            if (context.mounted) {
                              if (ok) {
                                showSuccessSnackbar(context,
                                    AppStrings.registroEliminado);
                              } else {
                                showErrorSnackbar(
                                    context, service.error ?? 'Error');
                              }
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
        onPressed: () =>
            Navigator.pushNamed(context, AppRoutes.crearVenta),
        backgroundColor: AppColors.ventasColor,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Crear Venta'),
      ),
    );
  }

  Widget _buildTotalBanner(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.ventasColor.withAlpha(26),
      child: Row(
        children: [
          const Icon(Icons.summarize_rounded,
              color: AppColors.ventasColor, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Total ventas: ',
            style: TextStyle(
                color: AppColors.ventasColor, fontWeight: FontWeight.w500),
          ),
          Text(
            NumberFormat.currency(
                    locale: 'es_BO', symbol: 'Bs.', decimalDigits: 2)
                .format(total),
            style: const TextStyle(
              color: AppColors.ventasColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
