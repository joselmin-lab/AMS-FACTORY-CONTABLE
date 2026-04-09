import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ams_control_contable/core/constants/app_colors.dart';
import 'package:ams_control_contable/core/router/app_router.dart';
import 'package:ams_control_contable/services/ingresos_service.dart';
import 'package:ams_control_contable/widgets/app_drawer.dart';
import 'package:ams_control_contable/widgets/empty_state.dart';

class IngresosScreen extends StatefulWidget {
  const IngresosScreen({super.key});

  @override
  State<IngresosScreen> createState() => _IngresosScreenState();
}

class _IngresosScreenState extends State<IngresosScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'es_BO', symbol: 'Bs.', decimalDigits: 2);
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IngresosService>().fetchIngresos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingresos Extra', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<IngresosService>().fetchIngresos(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Consumer<IngresosService>(
        builder: (context, service, _) {
          if (service.isLoading) return const Center(child: CircularProgressIndicator(color: Colors.teal));
          if (service.error != null) return Center(child: Text(service.error!, style: const TextStyle(color: AppColors.error)));
          if (service.ingresos.isEmpty) {
            return EmptyState(
              icon: Icons.savings_outlined,
              message: 'No hay ingresos extraordinarios registrados.',
              actionLabel: 'Registrar Ingreso',
              onAction: () => Navigator.pushNamed(context, AppRoutes.crearIngreso),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: service.ingresos.length,
            itemBuilder: (context, index) {
              final ingreso = service.ingresos[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.arrow_downward_rounded), // Flecha hacia abajo (entra a caja)
                  ),
                  title: Text(ingreso.detalle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Fecha: ${_dateFormat.format(ingreso.fecha)}'),
                      if (ingreso.descripcion != null && ingreso.descripcion!.isNotEmpty)
                        Text('Desc: ${ingreso.descripcion}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.teal.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                            child: Text(ingreso.metodoPago, style: const TextStyle(fontSize: 10, color: Colors.teal, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          if (ingreso.facturado)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.blue.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                              child: const Text('Facturado', style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Text(_currencyFormat.format(ingreso.precio), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.crearIngreso),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo Ingreso'),
      ),
    );
  }
}