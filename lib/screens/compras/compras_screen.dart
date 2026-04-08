import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ams_control_contable/core/constants/app_colors.dart';
import 'package:ams_control_contable/core/constants/app_strings.dart';
import 'package:ams_control_contable/core/router/app_router.dart';
import 'package:ams_control_contable/services/compras_service.dart';
import 'package:ams_control_contable/widgets/app_drawer.dart';
import 'package:ams_control_contable/widgets/empty_state.dart';
import 'package:ams_control_contable/widgets/movimiento_card.dart';
import 'package:ams_control_contable/widgets/dialogs.dart';

class ComprasScreen extends StatefulWidget {
  const ComprasScreen({super.key});

  @override
  State<ComprasScreen> createState() => _ComprasScreenState();
}

class _ComprasScreenState extends State<ComprasScreen> {
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _currencyFormat =
      NumberFormat.currency(locale: 'es_BO', symbol: 'Bs.', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ComprasService>().fetchCompras();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.compras),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                context.read<ComprasService>().fetchCompras(),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Consumer<ComprasService>(
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
                    onPressed: () => service.fetchCompras(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (service.compras.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_cart_outlined,
              message: 'No hay compras registradas.\nCrea tu primera compra.',
              onAction: () =>
                  Navigator.pushNamed(context, AppRoutes.crearCompra),
              actionLabel: 'Nueva Compra',
            );
          }

          return Column(
            children: [
              _buildTotalBanner(service.totalCompras),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => service.fetchCompras(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: service.compras.length,
                    itemBuilder: (context, index) {
                      final compra = service.compras[index];
                      return MovimientoCard(
                        title: compra.parteNombre ?? 'Compra',
                        subtitle:
                            '${compra.proveedor} · ${compra.metodoPago}',
                        amount:
                            _currencyFormat.format(compra.total),
                        date: _dateFormat.format(compra.fecha),
                        color: AppColors.comprasColor,
                        badge: compra.facturado ? 'Facturado' : null,
                        badgeColor: AppColors.success,
                        onEdit: () => Navigator.pushNamed(
                          context,
                          AppRoutes.crearCompra,
                          arguments: {'id': compra.id},
                        ),
                        onDelete: () async {
                          final confirm =
                              await showDeleteConfirmDialog(context);
                          if (confirm && context.mounted) {
                            final ok = await service
                                .deleteCompra(compra.id!);
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
            Navigator.pushNamed(context, AppRoutes.crearCompra),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Crear Compra'),
      ),
    );
  }

  Widget _buildTotalBanner(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.comprasColor.withAlpha(26),
      child: Row(
        children: [
          const Icon(Icons.summarize_rounded,
              color: AppColors.comprasColor, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Total compras: ',
            style: TextStyle(
                color: AppColors.comprasColor, fontWeight: FontWeight.w500),
          ),
          Text(
            NumberFormat.currency(
                    locale: 'es_BO', symbol: 'Bs.', decimalDigits: 2)
                .format(total),
            style: const TextStyle(
              color: AppColors.comprasColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
