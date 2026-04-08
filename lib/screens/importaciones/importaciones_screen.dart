import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ams_control_contable/core/constants/app_colors.dart';
import 'package:ams_control_contable/core/constants/app_strings.dart';
import 'package:ams_control_contable/core/router/app_router.dart';
import 'package:ams_control_contable/services/importaciones_service.dart';
import 'package:ams_control_contable/widgets/app_drawer.dart';
import 'package:ams_control_contable/widgets/empty_state.dart';
import 'package:ams_control_contable/widgets/movimiento_card.dart';
import 'package:ams_control_contable/widgets/dialogs.dart';

class ImportacionesScreen extends StatefulWidget {
  const ImportacionesScreen({super.key});

  @override
  State<ImportacionesScreen> createState() => _ImportacionesScreenState();
}

class _ImportacionesScreenState extends State<ImportacionesScreen> {
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _currencyFormat =
      NumberFormat.currency(locale: 'es_BO', symbol: 'Bs.', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ImportacionesService>().fetchImportaciones();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.importaciones),
        backgroundColor: AppColors.importacionesColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                context.read<ImportacionesService>().fetchImportaciones(),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Consumer<ImportacionesService>(
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
                    onPressed: () => service.fetchImportaciones(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (service.importaciones.isEmpty) {
            return EmptyState(
              icon: Icons.local_shipping_outlined,
              message:
                  'No hay importaciones registradas.\nCrea tu primera importación.',
              onAction: () =>
                  Navigator.pushNamed(context, AppRoutes.crearImportacion),
              actionLabel: 'Nueva Importación',
            );
          }

          return RefreshIndicator(
            onRefresh: () => service.fetchImportaciones(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: service.importaciones.length,
              itemBuilder: (context, index) {
                final imp = service.importaciones[index];
                final itemCount = imp.items.length;
                return MovimientoCard(
                  title:
                      '$itemCount ${itemCount == 1 ? 'ítem' : 'ítems'}',
                  subtitle:
                      'GA: ${imp.porcentajeGA}% · IVA: ${imp.porcentajeIVA}% · TC: ${imp.tipoCambio}',
                  amount: _currencyFormat.format(imp.costoTotal),
                  date: _dateFormat.format(imp.fecha),
                  color: AppColors.importacionesColor,
                  onEdit: () => Navigator.pushNamed(
                    context,
                    AppRoutes.crearImportacion,
                    arguments: {'id': imp.id},
                  ),
                  onDelete: () async {
                    final confirm = await showDeleteConfirmDialog(context);
                    if (confirm && context.mounted) {
                      final ok =
                          await service.deleteImportacion(imp.id!);
                      if (context.mounted) {
                        if (ok) {
                          showSuccessSnackbar(
                              context, AppStrings.registroEliminado);
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, AppRoutes.crearImportacion),
        backgroundColor: AppColors.importacionesColor,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva Importación'),
      ),
    );
  }
}
