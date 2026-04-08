import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ams_control_contable/core/constants/app_colors.dart';
import 'package:ams_control_contable/core/constants/app_strings.dart';
import 'package:ams_control_contable/models/gasto.dart';
import 'package:ams_control_contable/services/gastos_service.dart';
import 'package:ams_control_contable/widgets/app_drawer.dart';
import 'package:ams_control_contable/widgets/dialogs.dart';
import 'package:ams_control_contable/widgets/empty_state.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _currencyFormat = NumberFormat.currency(locale: 'es_BO', symbol: 'Bs.', decimalDigits: 2);
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GastosService>().fetchGastos();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showFormularioGasto({Gasto? gasto}) {
    final formKey = GlobalKey<FormState>();
    final descripcionCtrl = TextEditingController(text: gasto?.descripcion);
    final montoCtrl = TextEditingController(text: gasto?.monto.toString());
    final notasCtrl = TextEditingController(text: gasto?.notas);
    
    // Por defecto seleccionamos el tipo de la pestaña actual o el del gasto si estamos editando
    TipoGasto tipoSeleccionado = gasto?.tipo ?? TipoGasto.values[_tabController.index];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(gasto == null ? 'Nuevo Gasto' : 'Editar Gasto', style: const TextStyle(fontSize: 18)),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: descripcionCtrl,
                      decoration: const InputDecoration(labelText: 'Descripción (Ej. Luz, Agua, Juan Perez)'),
                      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: montoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Monto Total', prefixText: 'Bs. '),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (double.tryParse(v) == null) return 'Monto inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TipoGasto>(
                      value: tipoSeleccionado,
                      decoration: const InputDecoration(labelText: 'Categoría de Gasto'),
                      items: TipoGasto.values.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(t.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (val) => setStateDialog(() => tipoSeleccionado = val!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notasCtrl,
                      decoration: const InputDecoration(labelText: 'Notas adicionales'),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.gastosColor, foregroundColor: Colors.white),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final nuevoGasto = Gasto(
                      id: gasto?.id,
                      descripcion: descripcionCtrl.text.trim(),
                      monto: double.parse(montoCtrl.text),
                      tipo: tipoSeleccionado,
                      fecha: gasto?.fecha ?? DateTime.now(),
                      notas: notasCtrl.text.trim(),
                    );

                    Navigator.pop(ctx);

                    if (gasto == null) {
                      await context.read<GastosService>().createGasto(nuevoGasto);
                    } else {
                      await context.read<GastosService>().updateGasto(nuevoGasto);
                    }
                  }
                },
                child: const Text('Guardar'),
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
        title: const Text(AppStrings.gastos, style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.gastosColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => context.read<GastosService>().fetchGastos()),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Fijos', icon: Icon(Icons.home_rounded, size: 18, color: _tabController.index == 0 ? Colors.white : Colors.white70)),
            Tab(text: 'Variables', icon: Icon(Icons.trending_up_rounded, size: 18, color: _tabController.index == 1 ? Colors.white : Colors.white70)),
            Tab(text: 'Sueldos', icon: Icon(Icons.people_rounded, size: 18, color: _tabController.index == 2 ? Colors.white : Colors.white70)),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: Consumer<GastosService>(
        builder: (context, service, _) {
          if (service.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.gastosColor));
          }
          if (service.error != null) {
            return Center(child: Text(service.error!, style: const TextStyle(color: AppColors.error)));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildGastosList(service, TipoGasto.fijo, AppColors.gastosColor),
              _buildGastosList(service, TipoGasto.variable, AppColors.warning),
              _buildGastosList(service, TipoGasto.sueldo, AppColors.comprasColor),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormularioGasto(),
        backgroundColor: AppColors.gastosColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo Gasto'),
      ),
    );
  }

  Widget _buildGastosList(GastosService service, TipoGasto tipo, Color color) {
    final gastos = service.getGastosByTipo(tipo);
    final total = service.getTotalByTipo(tipo);

    if (gastos.isEmpty) {
      return EmptyState(
        icon: Icons.money_off_outlined,
        message: 'No hay gastos de tipo ${tipo.name} registrados.',
        onAction: () => _showFormularioGasto(),
        actionLabel: 'Agregar gasto',
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: color.withAlpha(26),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Gastos ${tipo.name.toUpperCase()}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text(_currencyFormat.format(total), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
              CircleAvatar(backgroundColor: color.withAlpha(50), child: Icon(_getIconForTipo(tipo), color: color)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: gastos.length,
            itemBuilder: (context, index) {
              final gasto = gastos[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(gasto.descripcion, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Fecha: ${_dateFormat.format(gasto.fecha)}'),
                      if (gasto.notas != null && gasto.notas!.isNotEmpty) Text('Notas: ${gasto.notas}'),
                    ],
                  ),
                  trailing: Text(_currencyFormat.format(gasto.monto), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.error)),
                  onTap: () => _showFormularioGasto(gasto: gasto),
                  onLongPress: () async {
                    final confirm = await showDeleteConfirmDialog(context);
                    if (confirm && context.mounted) {
                      service.deleteGasto(gasto.id!);
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getIconForTipo(TipoGasto tipo) {
    switch (tipo) {
      case TipoGasto.fijo: return Icons.home_rounded;
      case TipoGasto.variable: return Icons.trending_up_rounded;
      case TipoGasto.sueldo: return Icons.people_rounded;
    }
  }
}