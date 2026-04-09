import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ams_control_contable/core/constants/app_colors.dart';
import 'package:ams_control_contable/core/constants/app_strings.dart';
import 'package:ams_control_contable/core/router/app_router.dart';
import 'package:ams_control_contable/services/importaciones_service.dart';
import 'package:ams_control_contable/widgets/app_drawer.dart';
import 'package:ams_control_contable/widgets/empty_state.dart';

class ImportacionesScreen extends StatefulWidget {
  const ImportacionesScreen({super.key});

  @override
  State<ImportacionesScreen> createState() => _ImportacionesScreenState();
}

class _ImportacionesScreenState extends State<ImportacionesScreen> {
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _currencyFormat = NumberFormat.currency(locale: 'es_BO', symbol: 'Bs.', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ImportacionesService>().fetchCarpetas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carpetas de Importación', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.importacionesColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<ImportacionesService>().fetchCarpetas(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Consumer<ImportacionesService>(
        builder: (context, service, _) {
          if (service.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.importacionesColor));
          }

          if (service.error != null) {
            return Center(child: Text(service.error!, style: const TextStyle(color: AppColors.error)));
          }

          if (service.carpetas.isEmpty) {
            return EmptyState(
              icon: Icons.flight_land_rounded,
              message: 'No hay importaciones en curso.\nAbre tu primera carpeta.',
              onAction: () => Navigator.pushNamed(context, AppRoutes.crearImportacion),
              actionLabel: 'Nueva Carpeta',
            );
          }

          return RefreshIndicator(
            color: AppColors.importacionesColor,
            onRefresh: () => service.fetchCarpetas(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: service.carpetas.length,
              itemBuilder: (context, index) {
                final carpeta = service.carpetas[index];
                final esLiquidada = carpeta.estado == 'Liquidada';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  elevation: esLiquidada ? 1 : 3,
                  color: esLiquidada ? Colors.grey.shade50 : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: esLiquidada ? Colors.grey.shade300 : AppColors.importacionesColor.withAlpha(100), width: 1),
                  ),
                                    child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      // Usamos la ruta crearImportacion pero pasándole el ID de la carpeta como argumento
                      Navigator.pushNamed(
                        context, 
                        AppRoutes.crearImportacion, 
                        arguments: carpeta.id,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                carpeta.numeroDespacho,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: esLiquidada ? Colors.green.withAlpha(30) : Colors.orange.withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  carpeta.estado.toUpperCase(),
                                  style: TextStyle(
                                    color: esLiquidada ? Colors.green.shade700 : Colors.orange.shade700,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.business_rounded, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(carpeta.proveedor, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('Apertura: ${_dateFormat.format(carpeta.fechaApertura)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total FOB', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                  Text('\$${carpeta.totalFobUsd.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Costo Landed Total', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                  Text(
                                    _currencyFormat.format(carpeta.costoTotalBs),
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.importacionesColor),
                                  ),
                                ],
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.crearImportacion),
        backgroundColor: AppColors.importacionesColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.create_new_folder_rounded),
        label: const Text('Abrir Carpeta'),
      ),
    );
  }
}