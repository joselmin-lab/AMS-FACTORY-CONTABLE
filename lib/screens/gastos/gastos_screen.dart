import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ams_control_contable/core/constants/app_colors.dart';
import 'package:ams_control_contable/core/constants/app_strings.dart';
import 'package:ams_control_contable/models/gasto.dart';
import 'package:ams_control_contable/widgets/app_drawer.dart';
import 'package:ams_control_contable/widgets/dialogs.dart';
import 'package:ams_control_contable/widgets/empty_state.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _currencyFormat =
      NumberFormat.currency(locale: 'es_BO', symbol: 'Bs.', decimalDigits: 2);
  final _dateFormat = DateFormat('dd/MM/yyyy');

  // Placeholder local state (TODO: replace with service)
  final List<Gasto> _gastos = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Gasto> _gastosByTipo(TipoGasto tipo) =>
      _gastos.where((g) => g.tipo == tipo).toList();

  double _totalByTipo(TipoGasto tipo) =>
      _gastosByTipo(tipo).fold(0, (s, g) => s + g.monto);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.gastos),
        backgroundColor: AppColors.gastosColor,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              text: 'Fijos',
              icon: Icon(
                Icons.home_rounded,
                size: 18,
                color: _tabController.index == 0
                    ? Colors.white
                    : Colors.white70,
              ),
            ),
            Tab(
              text: 'Variables',
              icon: Icon(
                Icons.trending_up_rounded,
                size: 18,
                color: _tabController.index == 1
                    ? Colors.white
                    : Colors.white70,
              ),
            ),
            Tab(
              text: 'Sueldos',
              icon: Icon(
                Icons.people_rounded,
                size: 18,
                color: _tabController.index == 2
                    ? Colors.white
                    : Colors.white70,
              ),
            ),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGastosList(TipoGasto.fijo, AppColors.gastosColor),
          _buildGastosList(TipoGasto.variable, AppColors.warning),
          _buildGastosList(TipoGasto.sueldo, AppColors.comprasColor),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCrearGastoDialog,
        backgroundColor: AppColors.gastosColor,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo Gasto'),
      ),
    );
  }

  Widget _buildGastosList(TipoGasto tipo, Color color) {
    final gastos = _gastosByTipo(tipo);
    final total = _totalByTipo(tipo);

    if (gastos.isEmpty) {
      return EmptyState(
        icon: Icons.money_off_outlined,
        message:
            'No hay gastos ${tipo.name} registrados.',
        onAction: _showCrearGastoDialog,
        actionLabel: 'Agregar gasto',
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          color: color.withAlpha(26),
          child: Row(
            children: [
              Icon(Icons.summarize_rounded, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                'Total ${tipo.name}: ',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w500),
              ),
              Text(
                _currencyFormat.format(total),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
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
                margin: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withAlpha(26),
                    child: Icon(Icons.receipt_rounded,
                        color: color, size: 20),
                  ),
                  title: Text(gasto.descripcion,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600)),
                  subtitle: Text(_dateFormat.format(gasto.fecha)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _currencyFormat.format(gasto.monto),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {},
                            child: const Icon(Icons.edit_rounded,
                                size: 16, color: AppColors.primary),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () async {
                              final confirm =
                                  await showDeleteConfirmDialog(
                                      context);
                              if (confirm) {
                                setState(() => _gastos.remove(gasto));
                              }
                            },
                            child: const Icon(Icons.delete_rounded,
                                size: 16, color: AppColors.error),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCrearGastoDialog() {
    final descController = TextEditingController();
    final montoController = TextEditingController();
    TipoGasto tipo = TipoGasto.values[_tabController.index];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo Gasto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: AppStrings.descripcion,
                  prefixIcon: Icon(Icons.description_rounded),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: montoController,
                decoration: const InputDecoration(
                  labelText: AppStrings.monto,
                  prefixIcon: Icon(Icons.attach_money_rounded),
                  prefixText: 'Bs. ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TipoGasto>(
                value: tipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: TipoGasto.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.name[0].toUpperCase() +
                              t.name.substring(1)),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => tipo = v!),
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
                if (descController.text.isNotEmpty &&
                    montoController.text.isNotEmpty) {
                  setState(() {
                    _gastos.add(Gasto(
                      descripcion: descController.text,
                      monto: double.tryParse(montoController.text) ?? 0,
                      tipo: tipo,
                      fecha: DateTime.now(),
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
      ),
    );
  }
}
